local script_path = PANDOC_SCRIPT_FILE:match("(.*[/\\])") or ""

local resource_root = script_path .. "../resources/"
local env_resource_root = os.getenv("PANDOC_RESOURCES_DIR")
if env_resource_root and env_resource_root ~= "" then
    resource_root = env_resource_root:gsub("[/\\]+$", "") .. "/"
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
    { Str = FilterTags },
    { Str = ImageSyntax }
}
