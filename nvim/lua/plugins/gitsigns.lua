return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add          = { text = "▎" },
            change       = { text = "▎" },
            delete       = { text = "" },
            topdelete    = { text = "" },
            changedelete = { text = "▎" },
        },
        current_line_blame = false,
        on_attach = function(bufnr)
            local gs = require("gitsigns")
            local map = function(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end

            map("n", "]h", gs.next_hunk, "Next hunk")
            map("n", "[h", gs.prev_hunk, "Previous hunk")

            map("n", "<leader>uhp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>uhs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>uhr", gs.reset_hunk, "Reset hunk")
            map("n", "<leader>uhb", function() gs.blame_line({ full = true }) end, "Blame line")
            map("n", "<leader>uhd", gs.diffthis, "Diff this file")
        end,
    },
}
