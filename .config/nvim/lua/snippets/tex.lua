local ls = require("luasnip")
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local h = require("snippets.utils")

local auto = h.auto
local autop = h.autop

local function not_math()
    return not h.math()
end

local tex_only = {
    auto([[^( *)dm]], {
        f(function(_, snip)
            return snip.captures[1] or ""
        end),
        t("\\[ "),
        i(1),
        t(" \\]"),
        i(0),
    }, { name = "display math" }),

    autop("lm", {
        t("\\( "),
        i(1),
        t(" \\) "),
        i(0),
    }, { name = "inline math" }),

    auto([[^( *)et]], {
        f(function(_, snip)
            return snip.captures[1] or ""
        end),
        t("\\begin{equation}"),
        f(function(_, snip)
            return "\n" .. (snip.captures[1] or "") .. "    "
        end),
        f(function()
            return h.visual()
        end),
        i(1),
        f(function(_, snip)
            return "\n" .. (snip.captures[1] or "")
        end),
        t("\\end{equation}"),
        f(function(_, snip)
            return "\n" .. (snip.captures[1] or "")
        end),
        i(0),
    }, { name = "equation" }),

    autop("QQ", {
        f(function()
            h.add_package("amssymb")
            return "\\hfill $\\square$ "
        end),
        i(1),
        t("\\par"),
    }, { condition = not_math, name = "qed" }),
}

return {}, vim.list_extend(tex_only, require("snippets.math"))
