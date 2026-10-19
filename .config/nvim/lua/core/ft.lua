Vellum.ft = {
    c = function()
        vim.bo.tabstop = 2
    end,
    cs = function()
        vim.wo.colorcolumn = "100"
    end,
    css = function()
        vim.bo.comments = "s1:/*,ex:*/"
    end,
    dart = function()
        vim.bo.tabstop = 2
    end,
    html = function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
        vim.wo.breakindent = true

        if vim.bo.filetype == "html" then
            vim.wo.colorcolumn = "120"
        end
    end,
    javascript = function()
        vim.wo.colorcolumn = "120"
        vim.bo.commentstring = "// %s"
    end,
    lua = function()
        vim.wo.colorcolumn = "120"
    end,
    markdown = function()
        vim.wo.conceallevel = 2
        vim.wo.wrap = true
        vim.wo.colorcolumn = "120"
        vim.bo.shiftwidth = 2
        vim.bo.softtabstop = 2
        vim.bo.tabstop = 2
        vim.bo.matchpairs = vim.bo.matchpairs .. ",“:”"
        vim.wo.linebreak = false
    end,
    python = function()
        vim.bo.formatoptions = "tcqjor"
        vim.wo.colorcolumn = "88"
    end,
    tex = function()
        vim.wo.wrap = true
    end,
    text = function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
    end,
    typescript = function()
        vim.wo.colorcolumn = "120"
        vim.bo.commentstring = "// %s"
    end,
    typst = function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
        vim.wo.colorcolumn = "120"
        vim.wo.breakindent = true
        vim.bo.tabstop = 2
        vim.bo.commentstring = "// %s"
    end,
    sh = function()
        vim.bo.syntax = "sh"
        vim.cmd("runtime! syntax/sh.vim")
    end,
    ps1 = function()
        vim.bo.syntax = "ps1"
        vim.cmd("runtime! syntax/ps1.vim")
    end,
    zsh = function()
        vim.bo.syntax = "zsh"
        vim.cmd("runtime! syntax/zsh.vim")
    end,
}

---@param ft string
---@param callback function
function Vellum.ft:set(ft, callback)
    local default_callback = self[ft]
    if default_callback ~= nil then
        self[ft] = function()
            default_callback()
            callback()
        end
    else
        self[ft] = callback
    end
end
