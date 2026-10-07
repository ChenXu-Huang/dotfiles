return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
    config = function ()
        local npairs = require("nvim-autopairs")
        npairs.setup({})
        local Rule = require("nvim-autopairs.rule")
        npairs.add_rule(Rule("<", ">", {
            "html", "xml", "lua", "c", "cpp", "typescript", "rust"
        }):with_pair(function (opts)
            local prev = opts.line:sub(opts.col - 1, opts.col - 1)
            return prev:match('[%w_:)\'"]') ~= nil
        end))
    end
}
