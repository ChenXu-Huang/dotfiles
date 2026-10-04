local dsh_term

return {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
        direction = "vertical",
        size = function (term)
            if term.direction == "horizontal" then
                return 15
            elseif term.direction == "vertical" then
                return math.floor(vim.o.columns * 0.35)
            end
        end,
        float_opts = { border = "rounded" },
        start_in_insert = true,
        persist_size = true,
        persist_mode = true,
        on_open = function (term)
            local o = { buffer = term.bufnr, silent = true }
            vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], vim.tbl_extend("force", o, { desc = "Exit terminal mode" }))
            vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], vim.tbl_extend("force", o, { desc = "Focus left window" }))
            vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], vim.tbl_extend("force", o, { desc = "Focus window below" }))
            vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], vim.tbl_extend("force", o, { desc = "Focus window above" }))
            vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], vim.tbl_extend("force", o, { desc = "Focus right window" }))
        end
    },
    keys = {
        { "<leader>tt", "<Cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
        { "<A-t>", "<Cmd>ToggleTerm<CR>", mode = "t", desc = "Close terminal" },
        { "<leader>tf", "<Cmd>ToggleTerm direction=float<CR>", desc = "Float terminal" },
        { "<leader>tv", "<Cmd>ToggleTerm direction=vertical<CR>", desc = "Vertical terminal" },
        { "<leader>th", "<Cmd>ToggleTerm direction=horizontal<CR>", desc = "Horizontal terminal" },
        { "<leader>t1", "<Cmd>1ToggleTerm<CR>", desc = "Terminal 1" },
        { "<leader>t2", "<Cmd>2ToggleTerm<CR>", desc = "Terminal 2" },
        { "<leader>td", function ()
            if not dsh_term then
                local Terminal = require("toggleterm.terminal").Terminal
                dsh_term = Terminal:new({
                    cmd = "dsh-tui --resume",
                    hidden = true,
                    direction = "vertical",
                    count = 99,
                    close_on_edit = true,
                    on_open = function (term)
                        for _, lhs in ipairs({"<Esc><Esc", "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
                            pcall(vim.keymap.del, "t", lhs, { buffer = term.border })
                        end
                    end,
                })
            end
            dsh_term:toggle()
        end, desc = "dsh-tui" },
    },
}
