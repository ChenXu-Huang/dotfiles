return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        vim.env.CC = "gcc"

        local ts = require("nvim-treesitter")
        ts.setup()
        ts.install({
            "lua",
            "vim",
            "vimdoc",
            "query",
            "python",
            "requirements",
            "powershell",
            "bash",
            "markdown",
            "markdown_inline",
            "json",
            "yaml",
            "toml",
            "gitcommit",
            "gitignore",
            "diff",
            "regex",
            "comment",
        })

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                if pcall(vim.treesitter.start, args.buf) then
                    vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    vim.wo[0][0].foldmethod = "expr"
                end
            end,
        })
        vim.opt.foldlevel = 99
    end,
}
