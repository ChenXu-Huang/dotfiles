local utils = require("core.utils")

local g = vim.g
local opt = vim.opt

vim.cmd("language en_US.UTF-8")
vim.cmd("syntax off")

g.encoding = "UTF-8"
opt.fileencoding = "utf-8"

local win_height = vim.fn.winheight(0)
opt.scrolloff = math.floor((win_height - 1) / 2)
opt.sidescrolloff = math.floor((win_height - 1) / 2)

opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 0
opt.shiftround = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false

opt.autoread = true
opt.updatetime = 250
opt.undofile = true
opt.title = true
opt.titlestring = "%{fnamemodify(getcwd(), ':~')} - nvim"

opt.whichwrap = "<,>,[,]"
opt.hidden = true
opt.mouse = "a"
opt.mousemodel = "extend"
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.timeoutlen = 500
opt.splitbelow = true
opt.splitright = true
opt.cmdheight = 1
opt.cmdwinheight = 1
opt.shortmess = vim.o.shortmess .. "s"
opt.pumheight = 16
opt.showtabline = 0
opt.nrformats = "bin,hex,alpha"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = false
opt.laststatus = 3

if not utils.is_vscode then
    opt.number = true
    opt.relativenumber = true
    opt.cursorline = true
    opt.colorcolumn = "80"
    opt.signcolumn = "yes"
    opt.termguicolors = true
    opt.winborder = "rounded"
    opt.showmode = false
    opt.wrap = false

    vim.api.nvim_create_autocmd("WinNew", {
        callback = function()
            vim.wo.wrap = false
        end,
    })
end

if utils.is_windows then
    opt.shellslash = true
    opt.shell = "pwsh"
    opt.shellcmdflag =
        "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
    opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
    opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    opt.shellquote = ""
    opt.shellxquote = ""
end

opt.shadafile = "NONE"
vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdwinEnter" }, {
    once = true,
    callback = function()
        local shada = vim.fs.joinpath(vim.fn.stdpath("state"), "shada/main.shada")
        vim.o.shadafile = shada
        vim.cmd("rshada! " .. shada)
    end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
    callback = function()
        vim.cmd("startinsert")
        vim.wo.number = false
        vim.wo.relativenumber = false
    end,
})

if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font Mono"
    vim.g.neovide_scale_factor = 0.85
    vim.g.neovide_opacity = 0.95
    vim.g.neovide_cursur_animation_length = 0.13
    vim.g.neovide_cursur_vfx_mode = "railgun"
    vim.g.neovide_refresh_rate = 144
    vim.g.neovide_refresh_rate_idle = 5
    vim.g.neovide_remenber_window_size = true
end
