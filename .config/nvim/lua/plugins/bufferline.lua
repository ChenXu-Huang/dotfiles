return {
    "akinsho/bufferline.nvim",
    version = "*",
    opts = {
        options = {
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function (_, _, diagnostics_dict, _)
                local indicator = " "
                for level, number in pairs(diagnostics_dict) do
                    local symbol
                    if level == "error" then
                        symbol = " "
                    elseif level == "warning" then
                        symbol = " "
                    else
                        symbol = " "
                    end
                    indicator = indicator .. number .. symbol
                end
                return indicator
            end
        }
    },
    dependencies = {
        "nvim-tree/nvim-web-devicons"
    },
    keys = {
        { "<leader>bh", "<Cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
        { "<leader>bl", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
        { "<leader>bp", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
        { "<leader>bc", "<Cmd>BufferLinePickClose<CR>", desc = "Pick buffer to close" },
        { "<leader>bd", "<Cmd>bdelete<CR>", desc = "Delete buffer" },
        { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Close other buffers" }
    },
    lazy = false
}
