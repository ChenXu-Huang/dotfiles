vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Ctrl+z -> Undo
vim.keymap.set({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", { silent = true })

if vim.g.neovide then
    -- F11 -> Full screen
    vim.keymap.set("n", "<F11>", function ()
        vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
    end, { silent = true})
    -- Ctrl+-/+ Screen scale
    vim.keymap.set({ "n", "v", "i"}, "<C-=>", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1
    end, { silent = true})
    vim.keymap.set({ "n", "v", "i"}, "<C-->", function ()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1
    end, { silent = true})
end
