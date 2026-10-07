return {
    "nvimdev/lspsaga.nvim",
    cmd = "Lspsaga",
    opts = {
        finder = {
            keys = {
                toggle_or_open = "<CR>",
            },
        },
    },
    keys = {
        { "<leader>lr", "<Cmd>Lspsaga rename<CR>", desc = "Rename symbol" },
        { "<leader>lc", "<Cmd>Lspsaga code_action<CR>", desc = "Code action" },
        { "<leader>ld", "<Cmd>Lspsaga definition<CR>", desc = "Go to definition" },
        { "<leader>lh", "<Cmd>Lspsaga hover_doc<CR>", desc = "Hover documentation" },
        { "<leader>lR", "<Cmd>Lspsaga finder<CR>", desc = "Find references" },
        { "<leader>ln", "<Cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next diagnostic" },
        { "<leader>lp", "<Cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Previous diagnostic" },
    }
}
