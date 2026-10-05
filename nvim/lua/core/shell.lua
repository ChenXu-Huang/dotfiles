local M = {}

local function resolvable(name)
    return vim.fn.exepath(name) ~= ""
end

local function login_shell()
    local candidates = { "/bin/zsh", "/bin/bash", "/bin/sh" }
    if vim.env.SHELL then table.insert(candidates, 1, vim.env.SHELL) end
    for _, shell in ipairs(candidates) do
        if vim.fn.executable(shell) == 1 then return shell end
    end
end

function M.cmd(program, opts)
    opts = opts or {}
    local argv = program .. (opts.args and (" " .. opts.args) or "")

    local requires = opts.requires
    if type(requires) == "string" then requires = { requires } end

    local ok = resolvable(program)
    for _, name in ipairs(requires or {}) do
        ok = ok and resolvable(name)
    end
    if ok or vim.fn.has("win32") == 1 then return argv end

    local shell = login_shell()
    if not shell then return argv end
    local flags = (shell:match("zsh$") or shell:match("bash$")) and "-lic" or "-ic"
    return vim.fn.shellescape(shell) .. " " .. flags .. " 'exec " .. argv .. "'"
end

return M
