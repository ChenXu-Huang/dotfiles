local ls = require("luasnip")
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

local h = require("snippets.utils")

local auto = h.auto
local autop = h.autop

local function not_math()
    return not h.math()
end

local md_only = {
    auto([[v(tm|tt|ex|pf|pb|sn|df|dd|st|md|ds|cc)]], {
        d(1, function(_, snip)
            local res = h.block[snip.captures[1]]
            local nodes = {
                t("$\\{\\color{" .. res[2] .. "}\\mathbf{" .. res[3] .. "\\ " .. res[1] .. " ."),
                i(1),
                t("}}$ "),
            }
            if res[4] == 1 then
                nodes[#nodes + 1] = t("(**")
                nodes[#nodes + 1] = i(2)
                nodes[#nodes + 1] = t("**) ")
            end
            return ls.snippet_node(nil, nodes)
        end),
    }, { condition = not_math, name = "theorem block" }),

    autop("vdt", {
        t({ "<details>", "<summary>", "", "" }),
        i(1),
        t({ "", "", "</summary>", "", "" }),
        i(2),
        t({ "", "", "</details>" }),
        i(0),
    }, { condition = not_math, wordTrig = true, name = "details" }),

    autop("QQ", { t('<span class="qed"></span>') }, { condition = not_math, name = "qed" }),

    auto([[\?\?\?|？？？]], { t("==???==") }, { condition = not_math, name = "highlight question" }),

    autop("ksi", { t("\\xi") }, { condition = h.math, name = "xi" }),
    autop("gma", { t("\\gamma") }, { condition = h.math, name = "gamma" }),
    autop("Gma", { t("\\Gamma") }, { condition = h.math, name = "Gamma" }),
    autop("dlt", { t("\\delta") }, { condition = h.math, name = "delta" }),
    autop("tha", { t("\\theta") }, { condition = h.math, name = "theta" }),
    autop("Tha", { t("\\Theta") }, { condition = h.math, name = "Theta" }),

    auto([[DA|Dlt]], { t("\\Delta") }, { condition = h.math, name = "Delta" }),

    auto([[\\?(var|)eps]], {
        f(function(_, snip)
            return "\\" .. (snip.captures[1] or "") .. "epsilon"
        end),
    }, { priority = 1000, condition = h.math, name = "epsilon" }),

    auto([[\\?ups]], { t("\\upsilon") }, { priority = 1000, condition = h.math, name = "upsilon" }),
    autop("kpa", { t("\\kappa") }, { condition = h.math, name = "kappa" }),
    autop("lbd", { t("\\lambda") }, { condition = h.math, name = "lambda" }),
    autop("Lbd", { t("\\Lambda") }, { condition = h.math, name = "Lambda" }),
    autop("nv", { t("\\nu") }, { condition = h.math, name = "nu" }),
    autop("mv", { t("\\mu") }, { condition = h.math, name = "mu" }),
    autop("omg", { t("\\omega") }, { condition = h.math, name = "omega" }),
    autop("Omg", { t("\\Omega") }, { condition = h.math, name = "Omega" }),
}

return {}, vim.list_extend(md_only, require("snippets.math"))
