local version = vim.fn.matchstr(vim.fn.execute("version"), "NVIM v\\zs[^\\n]*")

local argv = vim.api.nvim_get_vvar("argv")

local utils = {
    is_linux = vim.uv.os_uname().sysname == "Linux",
    is_mac = vim.uv.os_uname().sysname == "Darwin",
    is_windows = vim.uv.os_uname().sysname == "Windows_NT",
    is_wsl = string.find(vim.uv.os_uname().release, "WSL") ~= nil,
    is_vscode = vim.g.vscode ~= nil,
    is_neovide = vim.g.neovide ~= nil,
    noplugin = vim.list_contains(argv, "--noplugin") or vim.list_contains(argv, "--noplugins"),
    version = version,
}

local augroup = vim.api.nvim_create_augroup("NvimConfig", { clear = true })

---@param bufnr integer
---@return boolean
utils.bdelete = function(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    local modified = vim.api.nvim_get_option_value("modified", { buf = bufnr })

    if modified and vim.fn.confirm("File is not saved. Close anyway?", "&Yes\n&No", 2) ~= 1 then
        return false
    end

    pcall(vim.cmd, "bwipeout! " .. bufnr)
    return true
end

---@param filetype string | string[]
---@param callback function
utils.ft = function(filetype, callback)
    vim.api.nvim_create_autocmd("FileType", {
        pattern = filetype,
        group = augroup,
        callback = callback,
    })
end

utils.get_root = function()
    local default_pattern = {
        ".git",
        ".gitignore",
        "package.json",
        "pyproject.toml",
        ".prettierrc",
        "tsconfig.json",
        "pubspec.yaml",
        "stylua.toml",
        ".stylua.toml",
        "README.md",
    }

    local pattern = Vellum.chdir_root_pattern
    if pattern == nil or type(pattern) ~= "table" then
        pattern = default_pattern
    end

    local filename = vim.fn.resolve(vim.fn.expand("%:p", true))
    if filename == "" then
        return vim.uv.cwd()
    end

    return vim.fs.root(filename, pattern) or vim.fs.dirname(filename)
end

---@param group table
---@param opt table | nil
utils.group_map = function(group, opt)
    if not opt then
        opt = {}
    end

    for desc, keymap in pairs(group) do
        desc = string.gsub(desc, "_", " ")
        local default_option = vim.tbl_extend("force", { desc = desc, nowait = true, silent = true }, opt)
        local map = vim.tbl_deep_extend("force", { nil, nil, nil, default_option }, keymap)
        vim.keymap.set(map[1], map[2], map[3], map[4])
    end
end

---@param win integer
---@param buf integer
utils.config_window = function(win, buf)
    vim.keymap.set("n", "q", "<C-w>c", { buffer = buf })
    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
    vim.api.nvim_set_option_value("cursorline", false, { win = win })
    vim.api.nvim_set_option_value("colorcolumn", "", { win = win })
    vim.api.nvim_set_option_value("fillchars", "eob: ", { win = win })
end

---@param opts { buf: integer, width: integer, height: integer, title: string, row: integer? }
---@return integer
utils.centered_float = function(opts)
    local left = math.floor((vim.fn.winwidth(0) - opts.width) / 2)
    local row = opts.row or math.floor((vim.fn.winheight(0) - opts.height) / 2)

    return vim.api.nvim_open_win(opts.buf, true, {
        relative = "win",
        width = opts.width,
        height = opts.height,
        row = row,
        col = left,
        border = "rounded",
        title = opts.title,
        title_pos = "center",
        footer = "Press q to close window",
        footer_pos = "center",
    })
end

---@param t table
---@return function
utils.ordered_pair = function(t)
    local keys = {}
    for key in pairs(t) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local index = 0
    return function()
        index = index + 1
        return keys[index], t[keys[index]]
    end
end

local pending_system = {}

---@param cmd string[]
---@param opts vim.SystemOpts?
---@param on_exit (fun(out: vim.SystemCompleted))?
---@return vim.SystemObj
utils.system = function(cmd, opts, on_exit)
    if on_exit == nil then
        return vim.system(cmd, opts)
    end

    local index = #pending_system + 1
    local function callback()
        if pending_system[index] ~= nil then
            on_exit(pending_system[index])
            pending_system[index] = nil
        else
            vim.schedule(callback)
        end
    end

    vim.schedule(callback)
    return vim.system(cmd, opts, function(out)
        pending_system[index] = out
    end)
end

---@param t table
---@param target any
---@return any
table.find = function(t, target)
    for key, value in pairs(t) do
        if value == target then
            return key
        end
    end
    return nil
end

return utils
