vim.g.mapleader = " "
vim.g.maplocalleader = ","

local opt = { silent = true }

vim.keymap.set({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", opt, { desc = "Undo"} )

if vim.g.neovide then
    vim.keymap.set("n", "<F11>", function ()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end, opt, { desc = "Full Screen" } )
    vim.keymap.set({ "n", "v", "i"}, "<C-=>", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
    end, opt, { desc = "Zoom in" } )
    vim.keymap.set({ "n", "v", "i"}, "<C-->", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
    end, opt, { desc = "Zoom out" } )
end
