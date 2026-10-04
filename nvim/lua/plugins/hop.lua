return {
    "smoka7/hop.nvim",
    version = "*",
    opts = function()
        return {
            hint_position = require("hop.hint").HintPosition.END,
        }
    end,
    keys = {
        { "<leader>hp", "<Cmd>HopWord<CR>", desc = "Hop to word", silent = true },
    },
}
