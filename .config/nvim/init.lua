Vellum = {}

require("core.init")
require("plugins.init")

local utils = require("core.utils")

if utils.is_vscode then
    require("core.vscode")
end

utils.group_map(Vellum.keymap)

for filetype, config in pairs(Vellum.ft) do
    if filetype ~= "set" then
        require("core.utils").ft(filetype, config)
    end
end

if not utils.noplugin then
    require("plugins.pack")

    local pattern = "VellumAfter transparent"
    if utils.is_vscode or Vellum.plugins["transparent"].enabled == false then
        pattern = "VeryLazy"
    end
    vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = pattern,
        callback = function()
            if utils.is_vscode then
                vim.api.nvim_exec_autocmds("User", { pattern = "VellumAfter colorscheme" })
                return
            end

            if not Vellum.colorscheme then
                Vellum.colorscheme = "tokyonight"
                local colorscheme_cache = vim.fs.joinpath(vim.fn.stdpath("data"), "colorscheme")
                if vim.uv.fs_stat(colorscheme_cache) then
                    local colorscheme_cache_file = io.open(colorscheme_cache, "r")
                    ---@diagnostic disable: need-check-nil
                    Vellum.colorscheme = colorscheme_cache_file:read("*a")
                    colorscheme_cache_file:close()
                end
            end

            require("plugins.utils").colorscheme(Vellum.colorscheme, false)
        end,
    })
end
