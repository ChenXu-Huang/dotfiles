return {
    "mason-org/mason-lspconfig.nvim",
    event = "VeryLazy",
    init = function()
        vim.diagnostic.config({
            update_in_insert = true,
            virtual_text = { spacing = 2, prefix = "●" },
            signs = true,
            underline = true,
            severity_sort = true,
            float = { border = "rounded", source = true },
        })
    end,
    opts = {},
    config = function(_, opts)
        vim.lsp.config("*", {
            capabilities = require("blink.cmp").get_lsp_capabilities(),
            on_attach = function(client, _)
                if client.name ~= "null-ls" then
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false
                end
            end,
        })
        require("mason-lspconfig").setup(opts)
    end,
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
        "saghen/blink.cmp",
    },
}
