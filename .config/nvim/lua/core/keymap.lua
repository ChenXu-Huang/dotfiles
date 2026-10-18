local utils = require("core.utils")

vim.g.mapleader = " "
vim.g.maplocalleader = ","

---@param pos "above" | "below" | "end"
local function comment(pos)
    return function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local total_lines = vim.api.nvim_buf_line_count(0)
        local commentstring = vim.bo.commentstring
        local cmt = string.gsub(commentstring, "%%s", "")
        local index = string.find(commentstring, "%%s")

        local target_line
        if pos == "below" then
            if row == total_lines then
                target_line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
            else
                target_line = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]
            end
        else
            target_line = vim.api.nvim_get_current_line()
        end

        if pos == "end" then
            if string.find(target_line, "%S") then
                cmt = " " .. cmt
                index = index + 1
            end
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { target_line .. cmt })
            vim.api.nvim_win_set_cursor(0, { row, #target_line + index - 2 })
        else
            local line_start = string.find(target_line, "%S") or (#target_line + 1)
            local blank = string.sub(target_line, 1, line_start - 1)

            if pos == "above" then
                vim.api.nvim_buf_set_lines(0, row - 1, row - 1, true, { blank .. cmt })
                vim.api.nvim_win_set_cursor(0, { row, #blank + index - 2 })
            end

            if pos == "below" then
                vim.api.nvim_buf_set_lines(0, row, row, true, { blank .. cmt })
                vim.api.nvim_win_set_cursor(0, { row + 1, #blank + index - 2 })
            end
        end

        vim.api.nvim_feedkeys("a", "n", false)
    end
end

local function comment_line()
    local line = vim.api.nvim_get_current_line()

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local commentstring = vim.bo.commentstring
    local cmt = string.gsub(commentstring, "%%s", "")
    local index = string.find(commentstring, "%%s")

    if not string.find(line, "%S") then
        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line .. cmt })
        vim.api.nvim_win_set_cursor(0, { row, #line + index - 1 })
    else
        require("vim._comment").toggle_lines(row, row, { row, 0 })
    end
end

local function join_lines()
    local v_count = vim.v.count1 + 1
    local mode = vim.api.nvim_get_mode().mode
    local keys
    if mode == "n" then
        keys = v_count .. "J"
    else
        keys = "J"
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

local function open_html_file()
    if vim.bo.filetype == "html" then
        local command
        if utils.is_linux or utils.is_wsl then
            command = "xdg-open"
        elseif utils.is_windows then
            command = "explorer"
        else
            command = "open"
        end
        if utils.is_windows then
            local old_shellslash = vim.opt.shellslash
            vim.opt.shellslash = false
            vim.cmd(string.format('silent exec "!%s %%:p"', command))
            vim.opt.shellslash = old_shellslash
        else
            vim.cmd(string.format('silent exec "!%s %%:p"', command))
        end
    end
end

local function save_file()
    local buffer_is_modified = vim.api.nvim_get_option_value("modified", { buf = 0 })
    if buffer_is_modified then
        vim.cmd("write")
    else
        print("Buffer not modified. No writing is done.")
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end

local function undo()
    local mode = vim.api.nvim_get_mode().mode

    if mode == "n" or mode == "i" or mode == "v" then
        vim.cmd("undo")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    end
end

local function undotree_toggle()
    local ok, undotree = pcall(require, "undotree")
    if not ok then
        vim.cmd("packadd nvim.undotree")
        undotree = require("undotree")
    end
    if Vellum.__UNDOTREE_BUFFER == nil then
        undotree.open()
        Vellum.__UNDOTREE_BUFFER = vim.api.nvim_get_current_buf()
    else
        vim.api.nvim_buf_delete(Vellum.__UNDOTREE_BUFFER, {})
        Vellum.__UNDOTREE_BUFFER = nil
    end
end

local terminal_command
if not utils.is_windows then
    terminal_command = "<Cmd>split | terminal<CR>"
else
    local executables = { "pwsh", "powershell", "bash", "cmd" }
    for _, executable in utils.ordered_pair(executables) do
        if vim.fn.executable(executable) == 1 then
            terminal_command = "<Cmd>split term://" .. executable .. "<CR>"
            break
        end
    end
end

Vellum.keymap = {
    black_hole_register = { { "n", "v" }, "\\", '"_' },

    buffer_delete = {
        "n",
        "<leader>bd",
        function()
            utils.bdelete(0)
        end,
    },
    buffer_delete_others = {
        "n",
        "<leader>bo",
        function()
            local all_buffers = vim.fn.getbufinfo()
            local current_buffer = vim.fn.bufnr()
            for _, buffer in ipairs(all_buffers) do
                if buffer.listed == 1 and buffer.bufnr ~= current_buffer then
                    utils.bdelete(buffer.bufnr)
                end
            end
        end,
    },
    buffer_next = { "n", "<leader>bl", "<Cmd>bnext<CR>" },
    buffer_prev = { "n", "<leader>bh", "<Cmd>bprevious<CR>" },

    clear_cmd_line = { { "n", "i", "v", "t" }, "<C-g>", "<Cmd>mode<CR>" },
    cmd_forward = { "c", "<C-f>", "<Right>", { silent = false } },
    cmd_backward = { "c", "<C-b>", "<Left>", { silent = false } },
    cmd_home = { "c", "<C-a>", "<Home>", { silent = false } },
    cmd_end = { "c", "<C-e>", "<End>", { silent = false } },
    cmd_word_forward = { "c", "<A-f>", "<S-Right>", { silent = false } },
    cmd_word_backward = { "c", "<A-b>", "<S-Left>", { silent = false } },

    comment_line = { "n", "gcc", comment_line },
    comment_above = { "n", "gcO", comment("above") },
    comment_below = { "n", "gco", comment("below") },
    comment_end = { "n", "gcA", comment("end") },

    disable_ctrl_left_mouse = { "n", "<C-LeftMouse>", "" },
    disable_right_mouse = { { "n", "i", "v", "t" }, "<RightMouse>", "<LeftMouse>" },

    join_lines = { { "n", "v" }, "J", join_lines },

    plugin_profile = { "n", "<leader>ul", "<Cmd>VellumProfile<CR>" },

    new_line_below_normal = { "n", "<A-o>", "o<Esc>" },
    new_line_above_normal = { "n", "<A-O>", "O<Esc>" },

    open_html_file = { "n", "<A-b>", open_html_file },
    open_terminal = { "n", "<C-t>", terminal_command },

    quickfix_next = { "n", "<leader>qn", ":cnext<CR>" },
    quickfix_prev = { "n", "<leader>qp", ":cprevious<CR>" },
    quickfix_open = { "n", "<leader>qo", ":copen<CR>" },
    quickfix_close = { "n", "<leader>qc", ":cclose<CR>" },

    normal_mode_in_terminal = { "t", "<Esc>", "<C-\\><C-n>" },
    save_file = { { "n", "i", "v" }, "<C-s>", save_file },
    undo = { { "n", "i", "v" }, "<C-z>", undo },
    undotree = { "n", "<leader>uu", undotree_toggle },
    visual_line = { "n", "V", "0v$" },

    toggle_wrap = {
        "n",
        "<leader>uw",
        function()
            vim.opt_local.wrap = not vim.opt_local.wrap:get()
        end,
    },
}

if utils.noplugin then
    Vellum.keymap.plugin_profile[3] = ""
end

if not utils.is_vscode then
    local function terminal_id()
        return tostring(vim.v.count1)
    end

    Vellum.keymap.toggle_terminal = {
        "n",
        "<leader>st",
        function()
            Vellum.terminal.toggle(terminal_id(), "float")
        end,
    }
    Vellum.keymap.vertical_terminal = {
        "n",
        "<leader>sv",
        function()
            Vellum.terminal.toggle(terminal_id(), "vertical")
        end,
    }
    Vellum.keymap.horizontal_terminal = {
        "n",
        "<leader>sh",
        function()
            Vellum.terminal.toggle(terminal_id(), "horizontal")
        end,
    }
    Vellum.keymap.close_terminal = {
        "t",
        "<M-s>",
        function()
            Vellum.terminal.toggle_current()
        end,
    }
    Vellum.keymap.dsh_tui = {
        "n",
        "<leader>sd",
        function()
            Vellum.terminal.toggle("dsh", "vertical", {
                cmd = "dsh-tui --resume",
                escape = true,
                on_exit = function(code, term)
                    if code == 0 then
                        Vellum.terminal.dispose(term)
                    elseif code then
                        vim.notify("dsh-tui exited with code " .. tostring(code), vim.log.levels.WARN)
                    end
                end,
            })
        end,
    }
end

if vim.g.neovide then
    Vellum.keymap.fullscreen = {
        "n",
        "<F11>",
        function()
            vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
        end,
    }
    Vellum.keymap.zoom_in = {
        { "n", "v", "i" },
        "<C-=>",
        function()
            vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
        end,
    }
    Vellum.keymap.zoom_out = {
        { "n", "v", "i" },
        "<C-->",
        function()
            vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
        end,
    }
end
