vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.colorcolumn = "100"
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0
vim.opt.smartindent = true
vim.opt.autoread = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.showmode = false
vim.opt.wrap = false
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.scrolloff = 5
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.winborder = "rounded"
vim.opt.title = true
vim.opt.titlestring = "%{fnamemodify(getcwd(), ':~')} - nvim"

if vim.fn.executable("pwsh") == 1 then
    vim.opt.shell = "pwsh"
    if vim.fn.has("win32") == 1 then
        vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"
        vim.opt.shellquote = ""
        vim.opt.shellxquote = ""
    end
end

if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font Mono"
    vim.g.neovide_scale_factor = 0.9
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_cursur_animation_length = 0.13
    vim.g.neovide_cursur_vfx_mode = "railgun"
    vim.g.neovide_refresh_rate = 144
    vim.g.neovide_refresh_rate_idle = 5
    vim.g.neovide_remenber_window_size = true
end
