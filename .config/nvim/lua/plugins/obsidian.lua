local M = {}

local function read_json(path)
    local file = io.open(path, "r")
    if file == nil then
        return {}
    end

    local content = file:read("*a")
    file:close()

    local ok, decoded = pcall(vim.json.decode, content)
    if not ok or type(decoded) ~= "table" then
        return {}
    end

    return decoded
end

local function string_or(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end

    return fallback
end

local function one_of(value, allowed, fallback)
    for _, item in ipairs(allowed) do
        if value == item then
            return item
        end
    end

    return fallback
end

function M.vault_path()
    return vim.env.OBSIDIAN_VAULT or vim.fn.expand("~/Projects/MyLib")
end

function M.is_vault_note(path)
    local dir = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(path, ":p")))
    while dir and dir ~= "" do
        if vim.uv.fs_stat(vim.fs.joinpath(dir, ".obsidian")) ~= nil then
            return true
        end

        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return false
        end

        dir = parent
    end

    return false
end

function M.register_trigger()
    if vim.uv.fs_stat(M.vault_path()) == nil then
        return
    end

    local group = vim.api.nvim_create_augroup("VellumObsidianTrigger", { clear = true })
    local trigger = vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
        group = group,
        pattern = { "*.md", "*.markdown" },
        callback = function(args)
            if package.loaded["obsidian"] ~= nil then
                return
            end

            if M.is_vault_note(args.file) then
                vim.api.nvim_exec_autocmds("User", { pattern = "VellumObsidian" })
            end
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "VellumAfter obsidian",
        once = true,
        callback = function()
            vim.api.nvim_del_autocmd(trigger)
        end,
    })
end

function M.opts()
    local vault = M.vault_path()
    local config_dir = vim.fs.joinpath(vault, ".obsidian")
    local app = read_json(vim.fs.joinpath(config_dir, "app.json"))
    local templates = read_json(vim.fs.joinpath(config_dir, "templates.json"))
    local daily_notes = read_json(vim.fs.joinpath(config_dir, "daily-notes.json"))

    local link_style = "wiki"
    if app.useMarkdownLinks == true then
        link_style = "markdown"
    end

    local daily_template = "daily-note"
    if type(daily_notes.template) == "string" and daily_notes.template ~= "" then
        daily_template = vim.fs.joinpath(vault, daily_notes.template)
    end

    return {
        legacy_commands = false,
        workspaces = {
            {
                name = "MyLib",
                path = vault,
            },
        },
        link = {
            style = link_style,
            format = one_of(app.newLinkFormat, { "shortest", "relative", "absolute" }, "absolute"),
            auto_update = app.alwaysUpdateLinks ~= false,
        },
        note_id_func = function(title)
            if title == nil then
                return tostring(os.time())
            end

            local note_id = vim.trim(title):gsub('[/\\:*?"<>|]', "")
            if note_id == "" then
                return tostring(os.time())
            end

            return note_id
        end,
        frontmatter = {
            enabled = false,
        },
        templates = {
            folder = string_or(templates.folder, "templates"),
        },
        daily_notes = {
            folder = string_or(daily_notes.folder, "00-inbox/journal"),
            template = daily_template,
            date_format = string_or(daily_notes.format, "YYYY-MM-DD"),
            workdays_only = false,
            default_tags = {},
        },
        attachments = {
            folder = "assets",
        },
    }
end

return M
