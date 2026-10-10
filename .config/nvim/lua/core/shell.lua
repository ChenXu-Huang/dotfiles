local M = {}

local synced = false

local default_path = "/usr/bin:/bin:/usr/sbin:/sbin"

local system_dirs = {
    ["/usr/local/bin"] = true,
    ["/usr/local/sbin"] = true,
    ["/opt/homebrew/bin"] = true,
    ["/opt/homebrew/sbin"] = true,
}

for dir in default_path:gmatch("[^:]+") do
    system_dirs[dir] = true
end

local session_vars = {
    PWD = true,
    OLDPWD = true,
    SHLVL = true,
    _ = true,
    PS1 = true,
    PS2 = true,
    PS4 = true,
    RANDOM = true,
    SECONDS = true,
    LINENO = true,
    TERM = true,
    COLUMNS = true,
    LINES = true,
}

local function login_shell()
    local candidates = { "/bin/zsh", "/bin/bash", "/bin/sh" }
    if vim.env.SHELL then table.insert(candidates, 1, vim.env.SHELL) end
    for _, shell in ipairs(candidates) do
        if vim.fn.executable(shell) == 1 then return shell end
    end
end

local function login_flags(shell)
    return (shell:match("zsh$") or shell:match("bash$")) and "-lic" or "-ic"
end

local function split_path(path)
    local entries = {}
    for entry in (path or ""):gmatch("[^:]+") do
        entries[#entries + 1] = entry
    end
    return entries
end

local function path_includes(path, other)
    local have = {}
    for _, entry in ipairs(split_path(path)) do
        have[entry] = true
    end
    for _, entry in ipairs(split_path(other)) do
        if not have[entry] then return false end
    end
    return true
end

local function path_is_system_default()
    local entries = split_path(vim.env.PATH)
    if #entries == 0 then return false end
    for _, entry in ipairs(entries) do
        if not system_dirs[entry] then return false end
    end
    return true
end

local function parse_env(text)
    local env = {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        local key, value = line:match("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
        if key then env[key] = value end
    end
    return env
end

local home = vim.env.HOME or ""

local rc_files = {
    home .. "/.zshenv",
    home .. "/.zprofile",
    home .. "/.zshrc",
}

local function cache_file()
    return vim.fn.stdpath("cache") .. "/shell-path"
end

local function read_cached_path()
    local file = cache_file()
    if vim.fn.filereadable(file) == 0 then return end
    local mtime = vim.fn.getftime(file)
    for _, rc in ipairs(rc_files) do
        if vim.fn.getftime(rc) > mtime then return end
    end
    local path = vim.fn.readfile(file)[1]
    if path and path ~= "" then return path end
end

local function write_cached_path(path)
    pcall(vim.fn.mkdir, vim.fn.stdpath("cache"), "p")
    pcall(vim.fn.writefile, { path }, cache_file())
end

local function shell_cmd(shell)
    return { shell, login_flags(shell), "command env" }
end

local function shell_opts()
    return { text = true, timeout = 5000, env = { PATH = default_path } }
end

local function fetch_env(shell)
    local ok, result = pcall(function()
        return vim.system(shell_cmd(shell), shell_opts()):wait()
    end)
    if not ok or not result or result.code ~= 0 then return end
    return parse_env(result.stdout)
end

local function fetch_env_async(shell, on_done)
    pcall(vim.system, shell_cmd(shell), shell_opts(), function(result)
        if result.code ~= 0 then return end
        local env = parse_env(result.stdout)
        vim.schedule(function() on_done(env) end)
    end)
end

local function merge_path(login_path, current_path, stale_path)
    local merged, seen = {}, {}
    local function add(entry)
        if entry ~= "" and not seen[entry] then
            seen[entry] = true
            merged[#merged + 1] = entry
        end
    end
    for _, entry in ipairs(split_path(login_path)) do add(entry) end
    local stale = {}
    for _, entry in ipairs(split_path(stale_path)) do stale[entry] = true end
    for _, entry in ipairs(split_path(current_path)) do
        if not stale[entry] then add(entry) end
    end
    return table.concat(merged, ":")
end

local function apply_env_if_needed(env, stale_path)
    if env.PATH and env.PATH ~= "" and not path_includes(vim.env.PATH, env.PATH) then
        vim.env.PATH = merge_path(env.PATH, vim.env.PATH, stale_path)
    end
    for key, value in pairs(env) do
        local skip = session_vars[key] or key:match("^NVIM") or key:match("^VIM")
        if not skip and vim.env[key] == nil then
            vim.env[key] = value
        end
    end
end

local function sync(shell, opts)
    local cached = read_cached_path()
    if cached then
        if not opts.force and path_includes(vim.env.PATH, cached) then return "skipped" end
        apply_env_if_needed({ PATH = cached })
    end

    if not (opts.force or (not cached and path_is_system_default())) then
        fetch_env_async(shell, function(env)
            apply_env_if_needed(env, cached)
            if env.PATH then write_cached_path(env.PATH) end
        end)
        return cached and "cached" or "async"
    end

    local env = fetch_env(shell)
    if not env then return "failed" end
    apply_env_if_needed(env, cached)
    if env.PATH then write_cached_path(env.PATH) end
    return "synced"
end

function M.sync_env(opts)
    opts = opts or {}
    if (synced and not opts.force) or vim.fn.has("win32") == 1 then
        return "skipped"
    end
    synced = true
    local shell = login_shell()
    if not shell then return "failed" end
    return sync(shell, opts)
end

return M
