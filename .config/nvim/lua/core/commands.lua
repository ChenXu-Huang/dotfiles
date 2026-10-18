local utils = require("core.utils")

vim.api.nvim_create_user_command("VellumAbout", function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "",
        "A Neovim configuration on vim.pack, ported from IceNvim",
        "into a personal dotfiles repository.",
        "",
        "Url: https://github.com/ChenXu-Huang/dotfiles",
        "Based on: https://github.com/Shaobin-Jiang/IceNvim",
    })

    local win = utils.centered_float({
        buf = buf,
        width = 80,
        height = math.floor(vim.fn.winheight(0) * 0.3),
        title = "About Vellum",
    })

    utils.config_window(win, buf)
end, { nargs = 0 })

vim.api.nvim_create_user_command("VellumHealth", "checkhealth core", { nargs = 0 })

vim.api.nvim_create_user_command("VellumRepeat", function(args)
    for _ = 1, vim.v.count1 do
        vim.cmd(args.args)
    end
end, { nargs = "+", complete = "command" })

vim.api.nvim_create_user_command("VellumTerm", function(args)
    Vellum.terminal.command(args.args, args.count)
end, {
    nargs = "*",
    count = true,
    complete = function(arglead)
        return Vellum.terminal.complete(arglead)
    end,
})

vim.api.nvim_create_user_command("VellumTokei", function()
    if vim.fn.executable("tokei") == 0 then
        vim.notify("Tokei is not installed!", vim.log.levels.WARN)
        return
    end

    local pwd = utils.get_root()

    utils.system({ "tokei" }, { cwd = pwd, text = true }, function(out)
        if out.code ~= 0 then
            vim.notify("Tokei encountered an unexpected error: " .. out.stderr, vim.log.levels.WARN)
            return
        end

        local content = vim.split(out.stdout, "\n")
        local buf = vim.api.nvim_create_buf(false, true)

        local win_height = vim.fn.winheight(0)
        local min_height = math.floor(win_height * 0.3)
        local max_height = math.floor(win_height * 0.8)
        local height = math.min(math.max(#content, min_height), max_height)

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

        local win = utils.centered_float({
            buf = buf,
            width = 80,
            height = height,
            title = "Tokei " .. pwd,
        })

        utils.config_window(win, buf)
    end)
end, { nargs = 0 })

vim.api.nvim_create_user_command("VellumView", function(args)
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), "vellum-view.txt")
    if args.args == "" then
        vim.cmd("edit " .. path)
    else
        vim.cmd(string.format(
            [[
                redir! > %s
                silent %s
                redir END
                edit %s
            ]],
            path,
            args.args,
            path
        ))
    end
end, { nargs = "*", complete = "command" })

vim.api.nvim_create_user_command("VellumYank", function(args)
    vim.cmd(string.format(
        [[
            redir @+>
            silent %s
            redir END
            lua vim.notify("Content yanked to system clipboard")
        ]],
        args.args
    ))
end, { nargs = "+", complete = "command" })

vim.api.nvim_create_user_command("LspInfo", function()
    vim.cmd("checkhealth vim.lsp")
end, { nargs = 0 })
