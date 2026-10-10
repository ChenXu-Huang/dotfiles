vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.keymap.set({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", { silent = true, desc = "Undo" })
vim.keymap.set("n", "<leader>uw", function ()
    vim.opt_local.wrap = not vim.opt_local.wrap:get()
end, { silent = true, desc = "Toggle line wrap" })

if vim.g.neovide then
    vim.keymap.set("n", "<F11>", function ()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end, { silent = true, desc = "Fullscreen" })
    vim.keymap.set({ "n", "v", "i" }, "<C-=>", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
    end, { silent = true, desc = "Zoom in" })
    vim.keymap.set({ "n", "v", "i" }, "<C-->", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
    end, { silent = true, desc = "Zoom out" })
end
