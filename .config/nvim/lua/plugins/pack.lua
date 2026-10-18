local specs = {}
local priorities = {}
local is_vscode = require("core.utils").is_vscode
Vellum.__COLORSCHEME_PLUGINS = {}
Vellum.__PROFILE = {
    plugins = {},
    plugins_trigger = {},
}

---@type table<string, any>
local pack_changed_autocmd = {}

local function get_spec_name(path)
    local parts = vim.fn.split(path, "/")
    return parts[#parts]
end

local function resolve_version(version)
    if type(version) ~= "string" then
        return version
    end
    local ok, range = pcall(vim.version.range, version)
    if ok and range ~= nil then
        return range
    end
    return version
end

---@param plugin table
---@return boolean
local function is_enabled(plugin)
    local enabled = plugin.enabled
    if type(enabled) == "function" then
        enabled = enabled()
    end
    if enabled == false then
        return false
    end
    return not is_vscode or plugin.vscode == true
end

---@param plugin table
---@param is_dependency boolean?
---@param name string?
local function packadd(plugin, is_dependency, name)
    if not is_enabled(plugin) then
        Vellum.__PROFILE.plugins[get_spec_name(plugin[1])] = "disabled"
        return
    else
        Vellum.__PROFILE.plugins[get_spec_name(plugin[1])] = "not loaded"
    end

    local src = plugin[1]
    if not vim.startswith(src, "http") then
        src = "https://github.com/" .. src
    end
    local spec = { src = src, version = resolve_version(plugin.version), data = {} }
    if is_dependency == true then
        spec.data.is_dependency = true
    end
    if name == nil or #name == 0 then
        name = "__" .. plugin[1]
        Vellum.plugins[name] = plugin
    end
    spec.data.pretty_name = name
    specs[#specs + 1] = spec
    priorities[name] = plugin.priority or 100

    if plugin.build ~= nil then
        if type(plugin.build) == "function" or type(plugin.build) == "string" then
            pack_changed_autocmd[get_spec_name(plugin[1])] = true
        end
    end

    if type(plugin.dependencies) == "table" then
        for _, dependency in ipairs(plugin.dependencies) do
            if type(dependency) == "string" then
                dependency = { dependency }
            end

            if type(dependency) == "table" then
                packadd(dependency, true)
            end
        end
    end
end

local function packadd_all_dependencies(source)
    if type(source.dependencies) == "table" then
        for _, dependency in ipairs(source.dependencies) do
            if type(dependency) == "table" then
                dependency = dependency[1]
            end
            local name = get_spec_name(dependency)
            Vellum.__PROFILE.plugins[name] = "loaded"
            if Vellum.__PROFILE.plugins_trigger[name] == nil then
                Vellum.__PROFILE.plugins_trigger[name] = { type = "dependency", value = get_spec_name(source[1]) }
            end
            vim.cmd.packadd(name)
        end
    end
end

for _, name in ipairs(vim.tbl_keys(Vellum.plugins)) do
    packadd(Vellum.plugins[name], false, name)
end

table.sort(specs, function(a, b)
    return (priorities[a.data.pretty_name] or 100) < (priorities[b.data.pretty_name] or 100)
end)

local augroup = vim.api.nvim_create_augroup("VellumPack", { clear = true })

vim.api.nvim_create_autocmd("PackChanged", {
    group = augroup,
    callback = function(ev)
        local name = ev.data.spec.name
        if not (ev.data.kind == "update" or ev.data.kind == "install") or pack_changed_autocmd[name] == nil then
            return
        end

        local plugin = Vellum.plugins[ev.data.spec.data.pretty_name]
        local callback
        if type(plugin.build) == "string" then
            if vim.startswith(plugin.build, ":") then
                callback = function()
                    vim.cmd(plugin.build)
                end
            else
                callback = function()
                    local shell
                    if require("core.utils").is_windows then
                        shell = { "cmd", "/c", plugin.build }
                    else
                        shell = { "bash", "-c", plugin.build }
                    end
                    vim.system(shell, { cwd = ev.data.path, text = true }, function(out)
                        if out.code ~= 0 then
                            vim.schedule(function()
                                vim.notify(
                                    "Build failed for " .. name .. ": " .. (out.stderr or ""),
                                    vim.log.levels.WARN
                                )
                            end)
                        end
                    end)
                end
            end
        else
            callback = plugin.build
        end

        packadd_all_dependencies(plugin)
        if not ev.data.active then
            vim.cmd.packadd(name)
        end

        vim.schedule(function()
            vim.notify("Running build script for " .. name)
            if type(callback) == "function" then
                callback()
            end
        end)
    end,
})

---@type table<vim.api.keyset.events, string[]>
local event_load = {}
---@type table<string, string[]>
local ft_load = {}

---@type table<string, function>
local load_functions = {}

local function source_after_plugin(path)
    if vim.v.vim_did_enter == 0 then
        return
    end

    for _, file in ipairs(vim.fn.glob(path .. "/after/plugin/**/*.{vim,lua}", false, true)) do
        vim.cmd.source({ file, magic = { file = false } })
    end
end

vim.pack.add(specs, {
    confirm = false,
    load = function(plug_data)
        local path = plug_data.path
        local spec = plug_data.spec
        local name = spec.name or ""

        local data = spec.data
        local source = Vellum.plugins[data.pretty_name]

        if type(source.init) == "function" then
            source.init()
        end

        local possible_colors_dir = vim.fs.joinpath(path, "colors")
        if vim.uv.fs_stat(possible_colors_dir) then
            local dir = vim.uv.fs_scandir(possible_colors_dir)
            if dir ~= nil then
                while true do
                    local item, item_type = vim.uv.fs_scandir_next(dir)
                    if
                        item_type == "file"
                        and item ~= nil
                        and (string.match(item, "%.vim$") or string.match(item, "%.lua$"))
                    then
                        local colorscheme = vim.split(item, "%.")[1]
                        Vellum.__COLORSCHEME_PLUGINS[colorscheme] = name
                    else
                        if item == nil then
                            break
                        end
                    end
                end
            end
        end

        if data.is_dependency == true then
            return
        end

        local load_function = function()
            packadd_all_dependencies(source)

            vim.cmd.packadd(name)
            source_after_plugin(path)

            local opts = {}
            if type(source.opts) == "table" then
                opts = source.opts
            elseif type(source.opts) == "function" then
                opts = source.opts()
            end

            if type(source.config) == "function" then
                source.config(opts)
            else
                local main = source.main
                if main == nil then
                    local options = vim.list.unique({
                        (string.gsub(name, "%.lua$", "")),
                        name,
                        (string.gsub(name, "%.nvim$", "")),
                        (string.gsub(name, "%-nvim$", "")),
                        (string.gsub(name, "^nvim%-", "")),
                    })

                    for _, option in ipairs(options) do
                        if vim.uv.fs_stat(vim.fs.joinpath(path, "lua", option)) then
                            main = option
                            break
                        end
                    end
                end

                if main ~= nil then
                    require(main).setup(opts)
                end
            end

            vim.api.nvim_exec_autocmds("User", { pattern = "VellumAfter " .. data.pretty_name })
            Vellum.__PROFILE.plugins[name] = "loaded"
        end

        if
            (type(source.lazy) == "boolean" and source.lazy == false)
            or (type(source.lazy) == "function" and source.lazy() == false)
            or (
                source.lazy ~= true
                and source.cmd == nil
                and source.event == nil
                and source.ft == nil
                and source.keys == nil
            )
        then
            load_function()
            if Vellum.__PROFILE.plugins_trigger[name] == nil then
                Vellum.__PROFILE.plugins_trigger[name] = { type = "init" }
            end
            return
        end

        if source.event ~= nil then
            ---@diagnostic disable: assign-type-mismatch, param-type-mismatch
            local events = source.event
            if type(source.event) == "string" then
                events = { source.event }
            end
            for _, event in ipairs(events) do
                if event_load[event] == nil then
                    event_load[event] = {}
                end
                event_load[event][#event_load[event] + 1] = name
            end
        end

        if source.ft ~= nil then
            ---@diagnostic disable: assign-type-mismatch, param-type-mismatch
            local fts = source.ft
            if type(source.ft) == "string" then
                fts = { source.ft }
            end
            for _, ft in ipairs(fts) do
                if ft_load[ft] == nil then
                    ft_load[ft] = {}
                end
                ft_load[ft][#ft_load[ft] + 1] = name
            end
        end

        if type(source.keys) == "table" then
            local keymap_group = {}
            for _, keymap in ipairs(source.keys) do
                local lhs = keymap[1]
                local rhs = keymap[2]
                local mode = keymap.mode or "n"
                local opts = {}
                for k, v in pairs(keymap) do
                    if type(k) ~= "number" and k ~= "mode" and k ~= "ft" then
                        opts[k] = v
                    end
                end
                if keymap.ft ~= nil then
                    keymap_group[#keymap_group + 1] = function()
                        vim.api.nvim_create_autocmd("FileType", {
                            pattern = keymap.ft,
                            callback = function()
                                vim.keymap.set(
                                    mode,
                                    lhs,
                                    rhs,
                                    vim.tbl_extend("force", { buffer = vim.fn.bufnr() }, opts)
                                )
                            end,
                        })
                    end
                else
                    keymap_group[#keymap_group + 1] = function()
                        vim.keymap.set(mode, lhs, rhs, opts)
                    end
                end
                vim.keymap.set(mode, lhs, function()
                    local ft = vim.bo.filetype
                    if
                        keymap.ft == nil
                        or ft == keymap.ft
                        or (type(keymap.ft) == "table" and vim.list_contains(keymap.ft, ft))
                    then
                        load_function()
                        if Vellum.__PROFILE.plugins_trigger[name] == nil then
                            Vellum.__PROFILE.plugins_trigger[name] = { type = "keys", value = lhs }
                        end
                        vim.api.nvim_exec_autocmds("FileType", { pattern = ft })
                        local keys = vim.api.nvim_replace_termcodes(lhs, true, true, true)
                        vim.api.nvim_feedkeys(keys, "m", false)
                    end
                end, opts)
            end

            local _old_load_function = load_function
            load_function = function()
                _old_load_function()
                for _, cb in ipairs(keymap_group) do
                    cb()
                end
            end
        end

        if source.cmd ~= nil then
            ---@diagnostic disable: assign-type-mismatch, param-type-mismatch
            local cmds = source.cmd
            if type(source.cmd) == "string" then
                cmds = { source.cmd }
            end

            for _, cmd in ipairs(cmds) do
                vim.api.nvim_create_user_command(cmd, function(event)
                    local command = {
                        cmd = cmd,
                        bang = event.bang or nil,
                        mods = event.smods,
                        args = event.fargs,
                        count = event.count >= 0 and event.range == 0 and event.count or nil,
                    }

                    if event.range == 1 then
                        command.range = { event.line1 }
                    elseif event.range == 2 then
                        command.range = { event.line1, event.line2 }
                    end

                    load_function()
                    if Vellum.__PROFILE.plugins_trigger[name] == nil then
                        Vellum.__PROFILE.plugins_trigger[name] = { type = "cmd", value = cmd }
                    end

                    local info = vim.api.nvim_get_commands({})[cmd] or vim.api.nvim_buf_get_commands(0, {})[cmd]
                    if not info then
                        return
                    end

                    command.nargs = info.nargs
                    if event.args and event.args ~= "" and info.nargs and info.nargs:find("[1?]") then
                        command.args = { event.args }
                    end
                    vim.cmd(command)
                end, {
                    bang = true,
                    range = true,
                    nargs = "*",
                    complete = function(_, line)
                        load_function()
                        if Vellum.__PROFILE.plugins_trigger[name] == nil then
                            Vellum.__PROFILE.plugins_trigger[name] = { type = "cmd", value = cmd }
                        end
                        return vim.fn.getcompletion(line, "cmdline")
                    end,
                })

                local _old_load_function = load_function
                load_function = function()
                    vim.api.nvim_del_user_command(cmd)
                    _old_load_function()
                end
            end
        end

        load_functions[name] = load_function
    end,
})

for event, plugins in pairs(event_load) do
    local _original_event_name = event
    if vim.startswith(event, "User ") then
        local suffix = string.sub(event, 6)
        if suffix == "VeryLazy" or vim.startswith(suffix, "Vellum") then
            _original_event_name = suffix
        end
    end
    local opts = {
        once = true,
        group = augroup,
        callback = function()
            for _, name in ipairs(plugins) do
                if type(load_functions[name]) == "function" then
                    load_functions[name]()
                    if Vellum.__PROFILE.plugins_trigger[name] == nil then
                        Vellum.__PROFILE.plugins_trigger[name] = { type = "event", value = _original_event_name }
                    end
                    load_functions[name] = nil
                end
            end
        end,
    }

    ---@diagnostic disable: assign-type-mismatch, param-type-mismatch
    if event == "VeryLazy" or vim.startswith(event, "Vellum") then
        opts.pattern = event
        event = "User"
    else
        local pos = string.find(event, " ")
        if pos ~= nil then
            opts.pattern = string.sub(event, pos + 1)
            event = string.sub(event, 1, pos - 1)
        end
    end
    vim.api.nvim_create_autocmd(event, opts)
end

for ft, plugins in pairs(ft_load) do
    local opts = {
        once = true,
        group = augroup,
        pattern = ft,
        callback = function()
            for _, name in ipairs(plugins) do
                if type(load_functions[name]) == "function" then
                    load_functions[name]()
                    if Vellum.__PROFILE.plugins_trigger[name] == nil then
                        Vellum.__PROFILE.plugins_trigger[name] = { type = "ft", value = vim.bo.filetype }
                    end
                    load_functions[name] = nil
                end
            end
        end,
    }
    vim.api.nvim_create_autocmd("FileType", opts)
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = augroup,
    once = true,
    callback = function()
        local second, microsecond = vim.uv.gettimeofday()
        if second ~= nil then
            Vellum.__PROFILE.startup_time = second * 1e9 + microsecond * 1000 - vim.v.starttime
        end
        vim.schedule(function()
            vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
        end)
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "VellumAfter colorscheme",
    callback = function()
        local function should_trigger()
            return vim.bo.filetype ~= "dashboard" and vim.api.nvim_buf_get_name(0) ~= ""
        end

        local function trigger()
            vim.api.nvim_exec_autocmds("User", { pattern = "VellumLoad" })
        end

        if should_trigger() then
            trigger()
            return
        end

        local vellum_load = 0
        vellum_load = vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                if should_trigger() then
                    trigger()
                    vim.api.nvim_del_autocmd(vellum_load)
                end
            end,
        })
    end,
})

require("plugins.profile")
