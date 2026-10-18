local utils = require("core.utils")

local config_path = vim.fn.stdpath("config")

local clip_path = vim.fs.joinpath(config_path, "bin/uclip.exe")
if not vim.uv.fs_stat(clip_path) then
    local root
    if utils.is_windows then
        root = "C:"
    else
        root = "/mnt/c"
    end
    clip_path = vim.fs.joinpath(root, "Windows/System32/clip.exe")
end

if (utils.is_windows or utils.is_wsl) and not utils.is_vscode then
    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
            if vim.v.event.operator == "y" then
                vim.fn.system(clip_path, vim.fn.getreg("0"))
            end
        end,
    })
else
    vim.cmd("set clipboard+=unnamedplus")
end

local ime_autogroup = vim.api.nvim_create_augroup("ImeAutoGroup", { clear = true })
if utils.is_windows or utils.is_wsl then
    local im_select_path = vim.fs.joinpath(config_path, "bin/im-select.exe")

    if vim.uv.fs_stat(im_select_path) then
        local function autocmd(event, code)
            vim.api.nvim_create_autocmd(event, {
                group = ime_autogroup,
                callback = function()
                    vim.cmd(":silent :!" .. im_select_path .. " " .. code)
                end,
            })
        end

        autocmd("InsertLeave", 1033)
        autocmd("InsertEnter", 2052)
        autocmd("VimLeavePre", 2052)
    end
elseif utils.is_mac then
    if vim.fn.executable("macism") == 1 then
        vim.api.nvim_create_autocmd("InsertLeave", {
            group = ime_autogroup,
            callback = function()
                vim.system({ "macism" }, { text = true }, function(out)
                    Vellum.__PREVIOUS_IM_CODE_MAC = string.gsub(out.stdout, "\n", "")
                end)
                vim.cmd(":silent :!macism com.apple.keylayout.ABC")
            end,
        })

        vim.api.nvim_create_autocmd("InsertEnter", {
            group = ime_autogroup,
            callback = function()
                if Vellum.__PREVIOUS_IM_CODE_MAC then
                    vim.cmd(":silent :!macism " .. Vellum.__PREVIOUS_IM_CODE_MAC)
                end
                Vellum.__PREVIOUS_IM_CODE_MAC = nil
            end,
        })
    end
elseif utils.is_linux then
    vim.cmd([[
        let fcitx5state=system("fcitx5-remote")
        autocmd InsertLeave * :silent let fcitx5state=system("fcitx5-remote")[0] | silent !fcitx5-remote -c
        autocmd InsertEnter * :silent if fcitx5state == 2 | call system("fcitx5-remote -o") | endif
    ]])
end

if not utils.is_vscode then
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("AutoChdir", { clear = true }),
        callback = function()
            if not (Vellum.auto_chdir or Vellum.auto_chdir == nil) then
                return
            end

            local exclude_filetype = Vellum.chdir_exclude_filetype
            if exclude_filetype == nil or type(exclude_filetype) ~= "table" then
                exclude_filetype = { "NvimTree", "help" }
            end

            local exclude_buftype = Vellum.chdir_exclude_buftype
            if exclude_buftype == nil or type(exclude_buftype) ~= "table" then
                exclude_buftype = { "terminal", "nofile" }
            end

            if table.find(exclude_filetype, vim.bo.filetype) or table.find(exclude_buftype, vim.bo.buftype) then
                return
            end

            vim.api.nvim_set_current_dir(require("core.utils").get_root())
        end,
    })
end

if utils.is_windows then
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("RemoveShadaTmp", { clear = true }),
        callback = function()
            local dir = vim.fs.joinpath(vim.fn.stdpath("data"), "shada")
            local shada_dir = vim.uv.fs_scandir(dir)
            if shada_dir == nil then
                return
            end

            local shada_temp = ""
            while shada_temp ~= nil do
                if string.find(shada_temp, ".tmp.") then
                    local full_path = vim.fs.joinpath(dir, shada_temp)
                    os.remove(full_path)
                end
                shada_temp = vim.uv.fs_scandir_next(shada_dir)
            end
        end,
    })
end
