local M = {}

---@param cmd string
---@param behavior function | nil
local function check(cmd, behavior)
    if vim.fn.executable(cmd) == 1 then
        vim.health.ok(cmd .. " is installed.")
    else
        if not behavior then
            vim.health.error(cmd .. " is missing.")
        else
            behavior()
        end
    end
end

M.check = function()
    vim.health.start("Vellum Prerequisites")
    vim.health.info("At least one [nerd font] should be installed; this is not checked.")

    for _, cmd in ipairs({
        "curl",
        "wget",
        "fd",
        "rg",
        "gcc",
        "cmake",
        "node",
        "npm",
        "yarn",
        "python3",
        "pip3",
        "tree-sitter",
    }) do
        check(cmd)
    end

    check("cargo", function()
        vim.health.warn("cargo is needed to build blink.cmp's fuzzy matcher from source.")
    end)

    if vim.fn.executable("gzip") == 1 or vim.fn.executable("7z") == 1 then
        vim.health.ok("One of gzip / 7zip is installed.")
    else
        vim.health.error("You must install one of gzip or 7zip.")
    end

    check("tokei", function()
        vim.health.warn("To enable code counting (:VellumTokei), you might want to install tokei.")
    end)

    local utils = require("core.utils")

    if utils.is_linux then
        vim.health.start("Vellum Prerequisites for Linux")
        vim.health.info("A [python virtualenv] is expected; this is not checked.")

        for _, cmd in ipairs({ "unzip", "xclip", "zip" }) do
            check(cmd)
        end
    end

    if utils.is_windows or utils.is_wsl then
        vim.health.start("Vellum Optional Dependencies for Windows and WSL")

        if utils.is_windows then
            check("cl", function()
                vim.health.error(
                    "You need msvc for treesitter to work properly. Specifically, you need cl.exe in your PATH."
                )
            end)
        end

        check(vim.fs.joinpath(vim.fn.stdpath("config"), "bin/im-select.exe"), function()
            vim.health.warn(
                "im-select.exe enables automatic IME switching for Chinese. See https://github.com/daipeihust/im-select"
            )
        end)

        check(vim.fs.joinpath(vim.fn.stdpath("config"), "bin/uclip.exe"), function()
            vim.health.warn(
                "uclip.exe enables correct unicode copy / paste; without it, clip.exe is used as a fallback."
            )
        end)
    end

    if utils.is_mac then
        vim.health.start("Vellum Optional Dependencies for MacOS")

        check("macism", function()
            vim.health.warn("macism enables automatic IME switching for Chinese.")
        end)
    end

    vim.health.start("Vellum Lsp Support")

    if Vellum.lsp.rust and Vellum.lsp.rust.enabled == true then
        vim.health.info("Rust")
        check("rust-analyzer", function()
            vim.health.error("You have rust support enabled, which requires rust-analyzer.")
        end)
    end

    if Vellum.lsp.emmylua_ls and Vellum.lsp.emmylua_ls.enabled == true then
        vim.health.info("Emmylua")
        check("emmylua_ls", function()
            vim.health.error("You have emmylua_ls support enabled, which requires emmylua_ls.")
        end)

        local has_luv = pcall(require, "luv")
        if not has_luv then
            vim.health.warn("For best experience with emmylua, you should add luv to your runtimepath.")
        end

        if Vellum.lsp["lua-language-server"] and Vellum.lsp["lua-language-server"].enabled == true then
            vim.health.warn("You have lua-language-server and emmylua_ls both enabled.")
        end
    end

    vim.health.start("Vellum Icons")

    vim.health.info("Take a look at whether the icons below render properly.")
    vim.health.info("If they do not display properly, you probably need to have a NERD FONT installed.")

    local item_width = 20
    local item_name_width = 15
    local win_width = vim.fn.winwidth(0)
    local columns = math.floor(win_width / item_width) - 1

    local items_in_row = 0
    local line = ""
    for name, icon in require("core.utils").ordered_pair(Vellum.symbols) do
        line = string.format(
            "%s%s%s%s%s",
            line,
            name,
            string.rep(" ", item_name_width - #name),
            icon,
            string.rep(" ", item_width - item_name_width - vim.fn.strdisplaywidth(icon))
        )

        items_in_row = items_in_row + 1

        if items_in_row == columns then
            vim.health.info(line)
            items_in_row = 0
            line = ""
        end
    end
end

return M
