return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvimtools/none-ls-extras.nvim",
    },
    event = "VeryLazy",
    opts = function()
        return {
            sources = {
                require("none-ls.formatting.ruff_format"),
                require("none-ls.formatting.ruff"),
                require("null-ls.builtins.formatting.stylua"),
            },
        }
    end,
    keys = {
        {
            "<leader>lf",
            function()
                vim.lsp.buf.format({ timeout_ms = 2000 })
            end,
            mode = { "n", "v" },
            desc = "Format buffer or selection",
        },
    },
}
