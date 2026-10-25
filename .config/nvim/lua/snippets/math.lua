local ls = require("luasnip")
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node

local h = require("snippets.utils")

local auto = h.auto
local autop = h.autop

local greek_alt = "alpha|beta|chi|delta|epsilon|varepsilon|phi|varphi|gamma|eta|iota|kappa|varkappa|lambda|mu|nu"
    .. "|omicron|pi|varpi|theta|vartheta|rho|sigma|varsigma|tau|upsilon|omega|xi|psi|zeta"
    .. "|Alpha|Beta|Chi|Delta|Epsilon|Phi|Gamma|Eta|Iota|Kappa|Lambda|Mu|Nu|Omicron|Pi|Theta|Rho|Sigma|Tau"
    .. "|Upsilon|Omega|Xi|Psi|Zeta"

local function cap(index)
    return function(_, snip)
        return snip.captures[index] or ""
    end
end

local function not_math()
    return not h.math()
end

local function math_not_aligned()
    return h.math() and not h.is_aligned_env()
end

local function math_not_unit()
    return h.math() and not h.is_unit_mode()
end

return {

    auto([[(?<=(oii|iii|ascc|mathtt|mathbb|hetan))]], { t("") }, {
        priority = 99999999,
        condition = h.math,
        name = "prevent",
    }),

    auto([[\$([^\$]*)DS]], {
        f(function(_, snip)
            local before = snip.captures[1] or ""
            return "$\\displaystyle" .. (before ~= "" and " " .. before or "")
        end),
    }, { condition = h.inline_math, name = "displaystyle" }),

    autop("...", { t("\\cdots ") }, { condition = h.math, name = "cdots" }),
    autop(",,,", { t("\\vdots ") }, { condition = h.math, name = "vdots" }),
    autop(":::", { t("\\ddots ") }, { condition = h.math, name = "ddots" }),

    auto([[(?<=[^s])(?<!\\)[iI]nt]], { t("\\int") }, { priority = 10, condition = h.math, name = "int" }),
    auto([[[\\]?iint]], { t("\\iint") }, { priority = 20, condition = h.math, name = "iint" }),
    auto([[[\\]?iiint]], { t("\\iiint") }, { priority = 100000, condition = h.math, name = "iiint" }),
    auto([[(?<!\\)oint]], { t("\\oint") }, { priority = 200000, condition = h.math, name = "oint" }),
    auto([[[\\]?oiint]], { t("\\oiint") }, { priority = 200000, condition = h.math, name = "oiint" }),

    auto([[(?<!\\)(lim|sum)]], {
        f(function(_, snip)
            return "\\" .. snip.captures[1]
        end),
    }, { condition = h.math, name = "lim/sum" }),

    auto([[(lim|limsup|liminf)d]], {
        f(cap(1)),
        t("_{"),
        i(1),
        t(" \\to "),
        i(2),
        t("}"),
        i(0),
    }, { condition = h.math, name = "lim with subscript" }),

    auto([[(int|bigcap|bigcup|sum)d]], {
        f(cap(1)),
        t("_{"),
        i(1),
        t("}^{"),
        i(2),
        t("}"),
    }, { condition = h.math, name = "int/sum with bounds" }),

    auto([[(?<=\\lim)[ ]?(inf|sup)]], { f(cap(1)) }, { condition = h.math, name = "limsup/liminf" }),

    auto([[(int|\\lim|\\sum)([a-ce-zA-CE-Z])]], {
        f(function(_, snip)
            return snip.captures[1] .. " " .. snip.captures[2]
        end),
    }, { condition = h.math, name = "space after int" }),


    autop("oo", { t("\\infty") }, { condition = h.math, name = "infinity" }),
    auto([[\\inftyp]], { t("+\\infty") }, { condition = h.math, name = "+infty" }),
    auto([[\\inftym]], { t("-\\infty") }, { condition = h.math, name = "-infty" }),


    autop("DD", {
        t("\\frac{\\mathrm{d}"),
        i(1),
        t("}{\\mathrm{d}"),
        i(2),
        t("}"),
    }, { condition = h.math, name = "derivative" }),

    autop("PP", {
        t("\\frac{\\partial "),
        i(1),
        t("}{\\partial "),
        i(2),
        t("}"),
    }, { condition = h.math, name = "partial derivative" }),

    auto([[(\w)?drm]], {
        f(function(_, snip)
            local before = snip.captures[1] or ""
            return (before ~= "" and before .. " " or "") .. "\\mathrm{\\,d}"
        end),
    }, { priority = 200, condition = h.math, name = "dif" }),

    autop("ptl", { t("\\partial ") }, { condition = h.math, name = "partial" }),


    auto([[(r|R|l|L|lr|Lr|u|U|d|D|ud|Ud|rr|ll|RR|LL|se|sw|ne|nw)a;]], {
        f(function(_, snip)
            return "\\" .. h.arrow[snip.captures[1]] .. "arrow "
        end),
    }, { priority = 10, condition = h.math, name = "arrows" }),

    autop("ia;", { t("\\implies ") }, { condition = h.math, name = "implies" }),
    autop("fa;", { t("\\iff ") }, { condition = h.math, name = "iff" }),
    autop("ta", { t("\\to ") }, { condition = h.math, name = "to" }),


    autop(">=", { t("\\geq ") }, { condition = h.math, name = "geq" }),
    autop("<=", { t("\\leq ") }, { condition = h.math, name = "leq" }),
    autop("<<", { t("\\ll ") }, { condition = h.math, name = "ll" }),
    autop(">>", { t("\\gg ") }, { condition = h.math, name = "gg" }),
    autop("<~", { t("\\lesssim ") }, { condition = h.math, name = "lesssim" }),
    autop(">~", { t("\\gtrsim ") }, { condition = h.math, name = "gtrsim" }),


    auto([[(?<!\\)sq]], {
        t("\\sqrt{"),
        i(1),
        t("}"),
    }, { condition = h.math, name = "sqrt" }),


    auto([[(RR|CC|ZZ)]], {
        f(function(_, snip)
            return "\\mathbb{" .. snip.captures[1]:sub(1, 1) .. "}"
        end),
    }, { condition = h.math, name = "sets" }),

    auto([[(\mathbb\{R\})([mnkl\d])]], {
        f(function(_, snip)
            return "\\mathbb{R}^{" .. snip.captures[2] .. "}"
        end),
    }, { priority = 2000000, condition = h.math, name = "rset^n" }),

    auto([[(\mathbb\{R\})\+]], { t("\\mathbb{R}_+") }, { priority = 2000000, condition = h.math, name = "rset_+" }),


    auto([[(?<!arc)(?<!\\)(sin|cos|tan|csc|sec|cot|ln|log|lg|det|ker|max|min)]], {
        f(function(_, snip)
            return "\\" .. snip.captures[1] .. " "
        end),
    }, { condition = h.math, name = "function" }),

    auto([[(?<!\\)arc(sin|cos|tan|csc|sec|cot)]], {
        f(function(_, snip)
            return "\\arc" .. snip.captures[1] .. " "
        end),
    }, { condition = h.math, name = "arc function" }),

    auto([[(?<=\\(sin|cos|tan|csc|sec|cot))( )h]], { t("h ") }, {
        priority = 20,
        condition = h.math,
        name = "hyperbolic function",
    }),

    auto([[(curl|div|grad)]], {
        f(function(_, snip)
            local word = snip.captures[1]
            return "\\mathrm{" .. word:sub(1, 1):upper() .. word:sub(2) .. ".}"
        end),
    }, { condition = h.math, name = "vec calculus" }),


    autop("==", { t("\\equiv ") }, { condition = math_not_aligned, name = "equiv" }),
    autop("OO", { t("\\cdot ") }, { condition = h.math, name = "cdot" }),
    autop("~~", { t("\\sim ") }, { condition = h.math, name = "sim" }),
    autop("NN", { t("\\cap ") }, { condition = h.math, name = "cap" }),
    autop("UU", { t("\\cup ") }, { condition = h.math, name = "cup" }),
    autop("II", { t("\\in ") }, { condition = h.math, name = "in" }),
    autop("XX", { t("\\times ") }, { condition = h.math, name = "times" }),
    autop("opo", { t("\\oplus ") }, { condition = h.math, name = "oplus" }),
    autop("omo", { t("\\ominus ") }, { condition = h.math, name = "ominus" }),
    autop("oxo", { t("\\otimes ") }, { condition = h.math, name = "otimes" }),
    autop("oco", { t("\\propto ") }, { condition = h.math, name = "propto" }),


    auto([[(\?)(nbl)]], { t("\\nabla ") }, { condition = h.math, name = "nabla" }),
    autop("AA", { t("\\forall ") }, { condition = h.math, name = "forall" }),
    autop("EE", { t("\\exist ") }, { condition = h.math, name = "exist" }),

    auto([[(\|\||abs)]], {
        t("\\left|"),
        i(1),
        t("\\right|"),
        i(0),
    }, { condition = h.math, name = "abs" }),

    auto([[(?<=(\$)?)VV]], {
        f(function(_, snip)
            return snip.captures[1] == "$" and "" or "\\times "
        end),
        t("10^{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "times 10^n" }),

    auto([[\!=]], { t("\\not =") }, { condition = h.math, name = "not equal" }),


    auto("[\\\\]?(" .. greek_alt .. ")", {
        f(function(_, snip)
            return "\\" .. snip.captures[1]
        end),
    }, { condition = h.math, name = "greek" }),

    auto([[(?<![a-zA-Z])([a-zA-IK-UW-Z]|v[efkpqs]);]], {
        f(function(_, snip)
            return h.greek[snip.captures[1]]
        end),
    }, { condition = h.math, name = "greek short" }),

    auto([[\\(epsilon|phi|pi|sigma|theta|kappa)[ ]?var]], {
        f(function(_, snip)
            return "\\var" .. snip.captures[1]
        end),
    }, { condition = h.math, name = "var greek" }),

    auto("\\\\(" .. greek_alt .. ")([a-zA-z])", {
        f(function(_, snip)
            return "\\" .. snip.captures[1] .. " " .. snip.captures[2]
        end),
    }, { condition = h.math, name = "space after greek" }),


    auto([[([bBpvV])?mat([1-9])([1-9])]], { d(1, h.matrix_node("mat", false)) }, {
        priority = 2000,
        condition = h.block_math,
        name = "matrix",
    }),

    auto([[([bp])?rv([1-9])]], { d(1, h.matrix_node("rv", false)) }, {
        priority = 2000000,
        condition = h.block_math,
        name = "row vector",
    }),

    auto([[([bp])?cv([1-9])]], { d(1, h.matrix_node("cv", false)) }, {
        priority = 2000000,
        condition = h.block_math,
        name = "column vector",
    }),


    auto([[([bBpvV])?mat([1-9])([1-9])]], { d(1, h.matrix_node("mat", true)) }, {
        priority = 2000,
        condition = h.inline_math,
        name = "matrix inline",
    }),

    auto([[([bp])?rv([1-9])]], { d(1, h.matrix_node("rv", true)) }, {
        priority = 2000000,
        condition = h.inline_math,
        name = "row vector inline",
    }),

    auto([[([bp])?cv([1-9])]], { d(1, h.matrix_node("cv", true)) }, {
        priority = 2000000,
        condition = h.inline_math,
        name = "column vector inline",
    }),


    autop("//", {
        t("\\frac{"),
        i(1),
        t("}{"),
        i(2),
        t("}"),
        i(0),
    }, { condition = math_not_unit, name = "fraction" }),

    auto(
        [[((\d+)|(\d*)([A-Za-z]+|[a-zA-Z]?\\(]]
            .. greek_alt
            .. [[))((\^|_)(\{\w+\}|\w)|')*)/]],
        {
            f(function(_, snip)
                return "\\frac{" .. snip.captures[1]
            end),
            t("}{"),
            i(1),
            t("}"),
            i(0),
        },
        { priority = 10, condition = math_not_unit, name = "auto fraction" }
    ),


    auto([[(?<!\\)pw]], {
        t("^{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "power" }),

    auto([[(?<!\\)sr]], { t("^{2}") }, { condition = h.math, name = "square" }),
    auto([[[_ ]?([\d]+);]], {
        f(function(_, snip)
            return "^{" .. snip.captures[1] .. "}"
        end),
    }, { condition = h.math, name = "digit power" }),

    auto([[_([a-z]);]], {
        f(function(_, snip)
            return "^" .. snip.captures[1]
        end),
    }, { condition = h.math, name = "letter power" }),

    auto([[(?<!\\)dag]], { t("^\\dagger ") }, { condition = h.math, name = "dagger" }),
    autop("coj", { t("^*") }, { condition = h.math, name = "conjugate" }),
    autop("inv", { t("^{-1}") }, { condition = h.math, name = "inverse" }),
    autop("trs", { t("^T") }, { condition = h.math, name = "transpose" }),

    auto([[(?<!\\)exp]], {
        t("\\mathrm{e}^{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "exp" }),


    auto([[(?<!(math|\\))sc]], {
        t("_{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "subscript" }),

    auto([[(?<!_)([A-Za-z][']*)(?<!mat)(\d|([a-z])\3{1})]], {
        f(function(_, snip)
            return snip.captures[1] .. "_" .. snip.captures[2]:sub(1, 1)
        end),
    }, { condition = math_not_unit, name = "auto subscript" }),

    auto("(?<!_)\\\\(" .. greek_alt .. [[)[']*[ ]?([a-z])\2{1}]], {
        f(function(_, snip)
            return "\\" .. snip.captures[1] .. "_" .. snip.captures[2]
        end),
    }, { condition = h.math, name = "greek subscript" }),

    auto("(?<=_)(([\\da-z]|\\\\(" .. greek_alt .. [[))\d)]], {
        f(function(_, snip)
            return "{" .. snip.captures[1] .. "}"
        end),
    }, { priority = 100, condition = h.math, name = "extend subscript" }),

    auto([[(?<=_)([\da-z])([a-z])\2]], {
        f(function(_, snip)
            return "{" .. snip.captures[1] .. snip.captures[2] .. " "
        end),
    }, { condition = h.math, name = "extend subscript pair" }),


    auto(
        "((?<![_\\^])\\d+|((?<![_\\^])\\d*)([A-Za-z]+|\\\\(" .. greek_alt .. [[)[ ]?))(?<!\\)(bar|fn|td|rm|hat|cr|bav|vec|bm|bf|cal|dot|vdt)]],
        {
            f(function(_, snip)
                local caps = snip.captures
                local key = caps[5]
                local p = h.prefix[key]
                if p == nil then
                    return (caps[1] or "") .. (key or "")
                end
                return p[1] .. (caps[1] or "") .. p[2]
            end),
        },
        { condition = h.math, name = "prefix mode" }
    ),

    auto(
        "((?<![_\\^])\\d+|(?:(?<![_\\^])\\d*)(?:[A-Za-z]+|\\\\(?:"
            .. greek_alt
            .. [[)[ ]?)[']*)(((\^|_)(\{\w+\}|\w))+)(?<!\\)(bar|fn|td|rm|hat|cr|bav|vec|bm|bf|cal|dot|vdt)]],
        {
            f(function(_, snip)
                local caps = snip.captures
                local key = caps[6]
                local p = h.prefix[key]
                if p == nil then
                    return (caps[1] or "") .. (caps[2] or "") .. (key or "")
                end
                return p[1] .. (caps[1] or "") .. p[2] .. (caps[2] or "")
            end),
        },
        { priority = 100, condition = h.math, name = "prefix mode with script" }
    ),


    autop("SS", {
        t("\\mathrm{\\,"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "unit mode" }),

    auto([[(?<=[A-Za-z])(\d)]], {
        f(function(_, snip)
            return "^" .. snip.captures[1]
        end),
    }, { condition = h.is_unit_mode, name = "unit power" }),

    autop("-", {
        t("^{-"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.is_unit_mode, name = "unit negative power" }),

    autop(".", { t("\\cdot ") }, { priority = 10, condition = h.is_unit_mode, name = "unit cdot" }),
    autop("cdg", { t("\\degree C") }, { priority = 10, condition = h.is_unit_mode, name = "celsius" }),

    auto([[(?<=\\mathrm\{\\,(?!.*\\mathrm\{\\,)[^\$]*\/)([^\(]*?)\.]], {
        f(function(_, snip)
            return "(" .. snip.captures[1] .. "\\cdot "
        end),
        i(1),
        t(")"),
        i(2),
    }, { priority = 20, condition = h.is_unit_mode, name = "unit denominator" }),


    auto([[(.*(?<!b|e))([be]?)aln]], {
        f(function()
            if vim.bo.filetype ~= "markdown" then
                h.add_package("amsmath")
            end
            return "\\begin{aligned}"
        end),
        t({ "", "    " }),
        f(function(_, snip)
            local before = snip.captures[1] or ""
            local mode = snip.captures[2] or ""
            local head = mode == "b" and "&" or ""
            local body = mode == "e" and before:gsub("=", "&=") or before
            return head .. body
        end),
        i(0),
        t({ "", "\\end{aligned}" }),
    }, { priority = 200, condition = h.block_math, name = "aligned" }),

    autop("==", { t("&=") }, { condition = h.is_aligned_env, name = "aligned equals" }),

    autop("Aln", {
        t("\\begin{aligned}"),
        t({ "", "    " }),
        f(function()
            return h.visual()
        end),
        i(0),
        t({ "", "\\end{aligned}" }),
    }, { priority = 300, condition = h.block_math, name = "aligned visual" }),

    auto([[(?<!\{[a-zA-Z]*)(case|rcase)]], {
        f(function(_, snip)
            return "\\begin{" .. snip.captures[1] .. "s}"
        end),
        t({ "", "    " }),
        i(1),
        f(function(_, snip)
            return "\n\\end{" .. snip.captures[1] .. "s}"
        end),
        i(0),
    }, { condition = h.math, name = "cases" }),

    auto([[(?<!\\)(txt|tst|text)]], {
        t("\\text{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "text" }),


    auto([[(\\rightarrow|\\Rightarrow|\\longrightarrow|\\Longrightarrow|\\to|\\implies)(| );]], {
        f(function(_, snip)
            return h.cycle(
                { "\\rightarrow", "\\Rightarrow", "\\longrightarrow", "\\Longrightarrow", "\\to", "\\implies" },
                snip.captures[1]
            ) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle right arrow" }),

    auto([[(\\leftarrow|\\Leftarrow|\\longleftarrow|\\Longleftarrow|\\impliedby)(| );]], {
        f(function(_, snip)
            return h.cycle(
                { "\\leftarrow", "\\Leftarrow", "\\longleftarrow", "\\Longleftarrow", "\\impliedby" },
                snip.captures[1]
            ) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle left arrow" }),

    auto([[(\\leftrightarrow|\\Leftrightarrow|\\longleftrightarrow|\\Longleftrightarrow|\\iff)(| );]], {
        f(function(_, snip)
            return h.cycle(
                { "\\leftrightarrow", "\\Leftrightarrow", "\\longleftrightarrow", "\\Longleftrightarrow", "\\iff" },
                snip.captures[1]
            ) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle leftright arrow" }),

    auto([[(\\downarrow|\\Downarrow)(| );]], {
        f(function(_, snip)
            return h.cycle({ "\\downarrow", "\\Downarrow" }, snip.captures[1]) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle down arrow" }),

    auto([[(\\uparrow|\\Uparrow)(| );]], {
        f(function(_, snip)
            return h.cycle({ "\\uparrow", "\\Uparrow" }, snip.captures[1]) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle up arrow" }),

    auto([[(\\updownarrow|\\Updownarrow)(| );]], {
        f(function(_, snip)
            return h.cycle({ "\\updownarrow", "\\Updownarrow" }, snip.captures[1]) .. (snip.captures[2] or "")
        end),
    }, { condition = h.math, name = "cycle updown arrow" }),

    auto([[(\\|\\var)(epsilon|theta|phi|pi|sigma|kappa)(| );]], {
        f(function(_, snip)
            return h.cycle({ "\\", "\\var" }, snip.captures[1])
                .. snip.captures[2]
                .. (snip.captures[3] or "")
        end),
    }, { condition = h.math, name = "cycle var greek" }),

    auto([[(\\frac|\\dfrac)\{.*\}\{.*\};]], {
        f(function(_, snip)
            local text = snip.captures[1] or ""
            if text == "" then
                text = snip.trigger or ""
            end
            return h.toggle_frac(text)
        end),
    }, { condition = h.math, name = "toggle frac" }),

    auto([[([^\$]*(\)|\])):]], {
        f(function(_, snip)
            return h.toggle_paren(snip.captures[1], snip.captures[2])
        end),
    }, { condition = h.math, name = "toggle paren bracket" }),

    auto([[([^\$]*(\)|\\right\)|\]|\\right\]|\\\}|\\right\\\}));]], {
        f(function(_, snip)
            return h.toggle_left_right(snip.captures[1], snip.captures[2])
        end),
    }, { condition = h.math, name = "toggle left right" }),


    autop("HH", {
        t("\\left(\\frac{\\partial "),
        i(1),
        t("}{\\partial "),
        i(2),
        t("}\\right)_{"),
        i(3),
        t("}"),
        i(0),
    }, { condition = h.math, name = "thermo derivative" }),

    autop("cvv", { t("c_V") }, { priority = 100000, condition = h.math, name = "c_V" }),
    autop("cvm", { t("c_{Vm}") }, { priority = 100000, condition = h.math, name = "c_Vm" }),
    autop("cpm", { t("c_{pm}") }, { priority = 100000, condition = h.math, name = "c_pm" }),

    autop("hbar", { t("\\hbar") }, { priority = 200, condition = h.math, name = "hbar" }),

    autop("avg", {
        t("\\left< "),
        i(1),
        t(" \\right>"),
        i(0),
    }, { condition = h.math, name = "average" }),

    auto([[[bB]ra]], {
        t("\\langle "),
        i(1),
        t("|"),
        i(0),
    }, { condition = h.math, name = "bra" }),

    auto([[(?<=\|[ ]?)ket]], {
        i(1),
        t("\\rangle"),
        i(0),
    }, { condition = h.math, name = "ket after bar" }),

    auto([[(?<!\|[ ]?)[kK]et]], {
        t("|"),
        i(1),
        t("\\rangle"),
        i(0),
    }, { condition = h.math, name = "ket" }),

    auto([[\\frt]], { t("\\frac{1}{sqrt{2\\pi}}\\int_{-\\infty}^{+\\infty}") }, {
        condition = h.math,
        name = "fourier transform",
    }),

    auto([[bs(j|k|i|n|h)]], {
        t("\\mathrm{\\,"),
        f(function(_, snip)
            return snip.captures[1]:upper()
        end),
        t("}_{"),
        i(1, "\\nu"),
        t("}"),
        i(0),
    }, { condition = h.math, name = "bessel" }),

    auto([[(j|k|i|n|h)bs]], {
        t("\\mathrm{\\,"),
        f(function(_, snip)
            return snip.captures[1]:upper()
        end),
        t("}_{"),
        i(1, "\\nu"),
        t("}"),
        i(0),
    }, { condition = h.math, name = "bessel reversed" }),

    autop("ldp", {
        t("\\mathrm{\\,P}_{"),
        i(1, "l"),
        t("}^{"),
        i(2),
        t("}"),
        i(0),
    }, { condition = h.math, name = "legendre" }),

    autop("grn", {
        t("G(\\boldsymbol{"),
        i(1, "r"),
        t("};\\boldsymbol{"),
        i(2, "r'"),
        t("})"),
    }, { condition = h.math, name = "green function" }),


    autop("%%", { t("$\\color{red}\\bigstar$") }, { condition = not_math, name = "big star" }),

    autop("BB", {
        t("\\boxed{"),
        i(1),
        t("}"),
        i(0),
    }, { condition = h.math, name = "boxed" }),

    auto([[([^$]*)@@]], {
        f(function(_, snip)
            local left = h.split_eval_at(snip.captures[1] or "")
            return left
        end),
        t("\\left."),
        f(function(_, snip)
            local _, right = h.split_eval_at(snip.captures[1] or "")
            return right
        end),
        t("\\right|_{"),
        i(1),
        t("}^{"),
        i(2),
        t("}"),
    }, { condition = h.math, name = "evaluate at" }),

    autop("latex", { t("\\LaTeX") }, { condition = not_math, name = "LaTeX" }),

    auto([[\\(red|green|blue) ]], {
        t("{\\color{"),
        f(cap(1)),
        t("}"),
        i(1),
        t("}"),
    }, { condition = h.math, name = "color" }),

    auto([[\\(red|green|blue);]], {
        t("{\\color{"),
        f(cap(1)),
        t("}"),
        f(function()
            return h.visual()
        end),
        t("}"),
    }, { condition = h.math, name = "color visual" }),


    auto([[(|_|\^)(?<!\\frac)\{\}([^\$]+)]], {
        f(function(_, snip)
            return snip.captures[2] or ""
        end),
    }, { condition = h.math, name = "delete empty script" }),

    auto([[\+!]], { t("+1") }, { condition = h.math, name = "plus one" }),
    auto([[\+@]], { t("+2") }, { condition = h.math, name = "plus two" }),
    autop("、、", { t("\\\\") }, { condition = h.math, name = "newline" }),

    auto([[([ ]*)》 ]], {
        f(function(_, snip)
            local matched = (snip.captures[1] or "") .. "》 "
            local pos = vim.api.nvim_win_get_cursor(0)
            local line = vim.api.nvim_get_current_line()
            if line:sub(1, pos[2]) == matched and line:sub(pos[2] + 1) == "" then
                return (snip.captures[1] or "") .. "> "
            end
            return matched
        end),
    }, { name = "quote" }),
}
