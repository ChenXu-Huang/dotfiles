local script_path = PANDOC_SCRIPT_FILE:match("(.*[/\\])") or ""
local default_resource_root = script_path .. "../assets/"

local function path_exists(path)
    local handle = io.open(path, "r")
    if handle then
        handle:close()
        return true
    end
    return pcall(pandoc.system.with_working_directory, path, function() end)
end

local function find_project_root(start)
    local dir = start
    while dir do
        if path_exists(pandoc.path.join({ dir, ".git" })) then
            return dir
        end
        local parent = pandoc.path.directory(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
    return nil
end

local function document_dir()
    local cwd = pandoc.system.get_working_directory()
    local input = PANDOC_STATE.input_files[1]
    if not input or input == "-" then
        return cwd
    end
    if not pandoc.path.is_absolute(input) then
        input = pandoc.path.join({ cwd, input })
    end
    return pandoc.path.directory(input)
end

local function metadata_path(meta, name)
    local value = meta[name]
    if value == nil then
        return nil
    end
    local path = pandoc.utils.stringify(value)
    if path == "" then
        return nil
    end
    return path
end

local function with_trailing_separator(path)
    return pandoc.path.normalize(path):gsub("[/\\]+$", "") .. "/"
end

local function resolve_resource_root(meta)
    local start = document_dir()
    local root = find_project_root(start)
    local option = metadata_path(meta, "resource_root")

    if option then
        if pandoc.path.is_absolute(option) then
            return with_trailing_separator(option)
        end
        return with_trailing_separator(pandoc.path.join({ root or start, option }))
    end

    if root then
        return with_trailing_separator(pandoc.path.join({ root, "assets" }))
    end

    return default_resource_root
end

local resource_root = default_resource_root

local function Configure(meta)
    resource_root = resolve_resource_root(meta)
end

local function ImageSyntax(elem)
    local pattern = "!%[%[([^%]]+)%]%]"
    local startIdx, endIdx, innerContent = elem.text:find(pattern)

    if innerContent then
        local filename = innerContent
        local width = nil

        local pipeIdx = innerContent:find("|", 1, true)
        if pipeIdx then
            filename = innerContent:sub(1, pipeIdx - 1)
            width = innerContent:sub(pipeIdx + 1)
        end

        local src = resource_root .. filename
        local attr = pandoc.Attr()
        if width then
            attr.attributes["width"] = width
        end

        local img = pandoc.Image({}, src, "", attr)
        local prefix = elem.text:sub(1, startIdx - 1)
        local suffix = elem.text:sub(endIdx + 1)

        local result = pandoc.List()
        if prefix ~= "" then result:insert(pandoc.Str(prefix)) end
        result:insert(img)
        if suffix ~= "" then result:insert(pandoc.Str(suffix)) end

        return result
    end
    return nil
end

local function FilterTags(elem)
    if elem.text:match("^#%a+") then
        return {}
    end
    return nil
end

return {
    { Meta = Configure, Str = FilterTags },
    { Str = ImageSyntax }
}
