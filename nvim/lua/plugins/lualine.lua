return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    opts = {
        options = {
            theme = "auto",
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
        },
        extensions = { "nvim-tree" },
        sections = {
            lualine_b = { function ()
                return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end, "branch", "diff" },
            lualine_x = {
                "filesize",
                "encoding",
                "filetype",
            },
        },
    },
}
