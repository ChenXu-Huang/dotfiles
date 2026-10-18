local M = {}

---@class VellumTerminal
---@field id string
---@field buf integer?
---@field win integer?
---@field direction string
---@field width integer?
---@field height integer?
---@field mode string?
---@field job integer?
---@field sizes table<string, integer>
---@field opts table

---@type table<string, VellumTerminal>
local terminals = {}

local directions = { "float", "vertical", "horizontal" }

local function is_open(t)
    return t.win ~= nil and vim.api.nvim_win_is_valid(t.win) and vim.api.nvim_win_get_buf(t.win) == t.buf
end

local function float_size(t)
    local width = t.width or math.min(vim.o.columns, math.max(80, vim.o.columns - 20))
    local height = t.height or math.min(vim.o.lines, math.max(20, vim.o.lines - 10))

    return math.min(width, vim.o.columns), math.min(height, vim.o.lines)
end

local function split_size(t)
    return t.sizes[t.direction] or (t.direction == "vertical" and math.floor(vim.o.columns * 0.35) or 15)
end

local function ensure_buf(t)
    if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
        return false
    end

    t.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[t.buf].bufhidden = "hide"

    return true
end

local function dispose(t)
    if t.win and vim.api.nvim_win_is_valid(t.win) then
        vim.api.nvim_win_close(t.win, true)
    end

    if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
        vim.api.nvim_buf_delete(t.buf, { force = true })
    end

    t.win = nil
    t.buf = nil
    t.job = nil
    t.mode = nil
end

M.dispose = dispose

local function handle_exit(t)
    return function(_, code)
        vim.schedule(function()
            t.job = nil

            if t.opts.on_exit then
                t.opts.on_exit(code, t)
            else
                dispose(t)
            end
        end)
    end
end

local function open_window(t)
    if t.direction == "float" then
        local width, height = float_size(t)

        t.win = vim.api.nvim_open_win(t.buf, true, {
            relative = "editor",
            style = "minimal",
            border = "rounded",
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
        })

        return
    end

    vim.cmd(t.direction == "vertical" and "botright vsplit" or "botright split")
    t.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(t.win, t.buf)

    if t.direction == "vertical" then
        vim.wo[t.win].winfixwidth = true
        vim.api.nvim_win_set_width(t.win, split_size(t))
    else
        vim.wo[t.win].winfixheight = true
        vim.api.nvim_win_set_height(t.win, split_size(t))
    end
end

local function open(t)
    local new_buf = ensure_buf(t)

    open_window(t)
    vim.api.nvim_set_current_win(t.win)

    if new_buf then
        local cmd = t.opts.cmd or vim.o.shell

        t.job = vim.fn.jobstart(cmd, { term = true, on_exit = handle_exit(t) })

        if t.job <= 0 then
            vim.notify("Failed to start terminal: " .. tostring(cmd), vim.log.levels.ERROR)
            dispose(t)
            return
        end

        vim.bo[t.buf].filetype = "terminal"

        if t.opts.escape then
            vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = t.buf, silent = true, desc = "Send Esc to dsh-tui" })
        end
    end

    if t.mode ~= "nt" then
        vim.cmd("startinsert")
    end
end

local function close(t)
    t.mode = vim.api.nvim_get_mode().mode:match("nt") and "nt" or "i"
    vim.cmd("stopinsert")

    if t.direction == "float" then
        local config = vim.api.nvim_win_get_config(t.win)
        t.width, t.height = config.width, config.height
    elseif t.direction == "vertical" then
        t.sizes[t.direction] = vim.api.nvim_win_get_width(t.win)
    else
        t.sizes[t.direction] = vim.api.nvim_win_get_height(t.win)
    end

    vim.api.nvim_win_close(t.win, true)
    t.win = nil
end

local function toggle(t)
    if is_open(t) then
        close(t)
    else
        open(t)
    end
end

M.toggle = function(id, direction, opts)
    id = tostring(id or "1")

    local t = terminals[id]

    if not t then
        t = { id = id, direction = "float", sizes = {}, opts = {} }
        terminals[id] = t
    end

    if direction then
        if not vim.tbl_contains(directions, direction) then
            vim.notify("Invalid terminal direction: " .. tostring(direction), vim.log.levels.ERROR)
            return
        end

        t.direction = direction
    end

    if opts then
        if opts.size then
            t.sizes[t.direction] = opts.size
        end

        t.opts = vim.tbl_extend("force", t.opts, opts)
    end

    toggle(t)
end

M.toggle_current = function()
    local buf = vim.api.nvim_get_current_buf()

    for _, t in pairs(terminals) do
        if t.buf == buf then
            toggle(t)
            return
        end
    end

    M.toggle("1", "float")
end

M.get = function(id)
    return terminals[tostring(id)]
end

M.get_all = function()
    return terminals
end

M.command = function(args, count)
    local id, direction, raw_size

    for _, token in ipairs(vim.split(args or "", "%s+")) do
        if token:match("^direction=") then
            direction = token:sub(11)
        elseif token:match("^size=") then
            raw_size = token:sub(6)
        elseif token ~= "" and id == nil then
            id = token
        end
    end

    if direction and not vim.tbl_contains(directions, direction) then
        vim.notify("Invalid terminal direction: " .. direction, vim.log.levels.ERROR)
        return
    end

    local size

    if raw_size then
        size = tonumber(raw_size)

        if not size or size % 1 ~= 0 or size < 1 then
            vim.notify("Invalid terminal size: " .. raw_size, vim.log.levels.ERROR)
            return
        end
    end

    M.toggle(id or (count and count >= 1 and count or 1), direction, size and { size = size } or nil)
end

M.complete = function(arglead)
    local items = { "direction=float", "direction=vertical", "direction=horizontal", "size=" }

    for id in pairs(terminals) do
        items[#items + 1] = id
    end

    return vim.tbl_filter(function(item)
        return vim.startswith(item, arglead)
    end, items)
end

Vellum.terminal = M

return M
