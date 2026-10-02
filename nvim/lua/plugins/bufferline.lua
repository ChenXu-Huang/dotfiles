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
        { "<leader>bh", "<Cmd>BufferLineCyclePrev<CR>" },
        { "<leader>bl", "<Cmd>BufferLineCycleNext<CR>" },
        { "<leader>bp", "<Cmd>BufferLinePick<CR>" },
        { "<leader>bc", "<Cmd>BufferLinePickClose<CR>" },
        { "<leader>bd", "<Cmd>bdelete<CR>" },
        { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>" }
    },
    lazy = false
}
