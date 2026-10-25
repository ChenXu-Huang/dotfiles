local ls = require("luasnip")
local t = ls.text_node
local i = ls.insert_node

local M = {}

M.greek = {
    a = "\\alpha",
    b = "\\beta",
    c = "\\chi",
    d = "\\delta",
    e = "\\epsilon",
    ve = "\\varepsilon",
    f = "\\phi",
    vf = "\\varphi",
    g = "\\gamma",
    h = "\\eta",
    i = "\\iota",
    j = "\\varphi",
    k = "\\kappa",
    vk = "\\varkappa",
    l = "\\lambda",
    m = "\\mu",
    n = "\\nu",
    o = "\\omicron",
    p = "\\pi",
    vp = "\\varpi",
    q = "\\theta",
    vq = "\\vartheta",
    r = "\\rho",
    s = "\\sigma",
    vs = "\\varsigma",
    t = "\\tau",
    u = "\\upsilon",
    v = "\\varpi",
    w = "\\omega",
    x = "\\xi",
    y = "\\psi",
    z = "\\zeta",
    A = "\\Alpha",
    B = "\\Beta",
    C = "\\Chi",
    D = "\\Delta",
    E = "\\Epsilon",
    F = "\\Phi",
    G = "\\Gamma",
    H = "\\Eta",
    I = "\\Iota",
    K = "\\Kappa",
    L = "\\Lambda",
    M = "\\Mu",
    N = "\\Nu",
    O = "\\Omicron",
    P = "\\Pi",
    Q = "\\Theta",
    R = "\\Rho",
    S = "\\Sigma",
    T = "\\Tau",
    U = "\\Upsilon",
    W = "\\Omega",
    X = "\\Xi",
    Y = "\\Psi",
    Z = "\\Zeta",
}

M.prefix = {
    bar = { "\\overline{", "}" },
    fn = { "\\overset{\\frown}{", "}" },
    td = { "\\widetilde{", "}" },
    rm = { "\\mathrm{", "}" },
    hat = { "\\hat{", "}" },
    cr = { "\\mathscr{", "}" },
    bav = { "\\hat{\\boldsymbol{", "}}" },
    vec = { "\\vec{", "}" },
    bm = { "\\boldsymbol{", "}" },
    bf = { "\\mathbf{", "}" },
    cal = { "\\mathcal{", "}" },
    dot = { "\\dot{", "}" },
    vdot = { "\\dot{\\boldsymbol{", "}}" },
}

M.arrow = {
    r = "right",
    R = "Right",
    l = "left",
    L = "Left",
    lr = "leftright",
    Lr = "Leftright",
    u = "up",
    U = "Up",
    d = "down",
    D = "Down",
    ud = "updown",
    Ud = "Updown",
    rr = "longright",
    ll = "longleft",
    RR = "Longright",
    LL = "Longleft",
    se = "se",
    sw = "sw",
    ne = "ne",
    nw = "nw",
}

M.block = {
    tm = { "Thm", "brown", "▶", 0 },
    tt = { "Thm", "brown", "▶", 1 },
    ex = { "Ex", "teal", "▶", 0 },
    pf = { "Pf", "green", "▶", 0 },
    pb = { "Problem", "teal", "▶", 0 },
    sn = { "Sol", "green", "▶", 0 },
    df = { "Def", "purple", "▶", 0 },
    dd = { "Def", "purple", "▶", 1 },
    st = { "Step", "orange", "▶", 0 },
    md = { "Method", "brown", "■", 0 },
    cc = { "Case", "brown", "●", 0 },
    ds = { "Discussion", "brown", "■", 0 },
}

function M.cycle(arr, str)
    local count = 0
    repeat
        count = count + 1
    until str == arr[count] or count >= #arr
    return arr[(count % #arr) + 1]
end

function M.visual()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local srow, scol = start_pos[2], start_pos[3]
    local erow, ecol = end_pos[2], end_pos[3]
    if srow == 0 or erow == 0 then
        return ""
    end
    local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
    if #lines == 0 then
        return ""
    end
    lines[#lines] = lines[#lines]:sub(1, ecol)
    lines[1] = lines[1]:sub(scol)
    return table.concat(lines, "\n")
end

local asked_packages = {}

function M.add_package(package)
    local bufnr = vim.api.nvim_get_current_buf()
    local key = bufnr .. ":" .. package
    if asked_packages[key] then
        return
    end
    local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
    if text:find(package, 1, true) then
        return
    end
    asked_packages[key] = true
    vim.schedule(function()
        vim.ui.select({ "Yes", "No" }, {
            prompt = string.format("Package '%s' not detected. Import it now?", package),
        }, function(choice)
            if choice ~= "Yes" then
                return
            end
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
            if current:find(package, 1, true) then
                return
            end
            vim.api.nvim_buf_set_lines(bufnr, 1, 1, false, { "\\usepackage{" .. package .. "}" })
        end)
    end)
end

local TEX_MATH_NODES = {
    inline_formula = true,
    displayed_equation = true,
    math_environment = true,
}

local TEX_BLOCK_NODES = {
    displayed_equation = true,
    math_environment = true,
}

local function ts_math_state()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "latex")
    if not ok or parser == nil then
        return false, false
    end
    pcall(function()
        parser:parse()
    end)
    local node_ok, node = pcall(vim.treesitter.get_node, {
        bufnr = bufnr,
        lang = "latex",
        ignore_injections = false,
    })
    if not node_ok or node == nil then
        return false, false
    end
    local in_math, in_block = false, false
    while node do
        local node_type = node:type()
        if TEX_BLOCK_NODES[node_type] then
            in_block = true
        end
        if TEX_MATH_NODES[node_type] then
            in_math = true
        end
        node = node:parent()
    end
    return in_math, in_block
end

local function md_math_state()
    local pos = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, pos[1], false)
    local in_block = false
    local inline_count = 0
    for lnum = 1, #lines do
        local text = lines[lnum]
        if lnum == #lines then
            text = text:sub(1, pos[2])
        end
        local idx = 1
        while idx <= #text do
            local pair = text:sub(idx, idx + 1)
            if pair == "$$" then
                in_block = not in_block
                idx = idx + 2
            elseif not in_block and text:sub(idx, idx) == "$" then
                inline_count = inline_count + 1
                idx = idx + 1
            else
                idx = idx + 1
            end
        end
    end
    local in_math = in_block or inline_count % 2 == 1
    return in_math, in_block
end

local function math_state()
    if vim.bo.filetype == "markdown" then
        return md_math_state()
    end
    return ts_math_state()
end

function M.math()
    local in_math = math_state()
    return in_math
end

function M.inline_math()
    local in_math, in_block = math_state()
    return in_math and not in_block
end

function M.block_math()
    local _, in_block = math_state()
    return in_block
end

function M.is_aligned_env()
    local pos = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, pos[1], false)
    if #lines > 0 then
        lines[#lines] = lines[#lines]:sub(1, pos[2])
    end
    local text = table.concat(lines, "\n")
    text = text:gsub("\\begin%{aligned%}[^$]-\\end%{aligned%}", "")
    return text:find("\\begin{aligned}", 1, true) ~= nil
end

function M.is_unit_mode()
    local pos = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line():sub(1, pos[2])
    line = line:gsub("\\mathrm%{\\,[^$]-%}", "")
    return line:find("\\mathrm{\\,", 1, true) ~= nil
end

function M.autoclosing()
    local pos = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local ch = line:sub(pos[2] + 2, pos[2] + 2)
    if ch == "" then
        return true
    end
    return ch:match("[;:.,=)>%]`%s*|\\$*]") ~= nil
end

function M.matrix_node(kind, inline)
    return function(_, snip)
        local flag = snip.captures[1]
        local nrow, ncol
        if kind == "mat" then
            nrow = tonumber(snip.captures[2])
            ncol = tonumber(snip.captures[3])
        elseif kind == "rv" then
            nrow, ncol = 1, tonumber(snip.captures[2])
        else
            nrow, ncol = tonumber(snip.captures[2]), 1
        end
        if flag == nil or flag == "" then
            flag = (kind == "rv" or kind == "cv") and "b" or ""
        end
        if nrow == nil or ncol == nil then
            return ls.snippet_node(nil, { t("") })
        end
        M.add_package("amsmath")
        local nodes = { t("\\begin{" .. flag .. "matrix}") }
        local order = 1
        for _ = 1, nrow do
            if inline then
                nodes[#nodes + 1] = t("  ")
            else
                nodes[#nodes + 1] = t({ "", "  " })
            end
            for col = 1, ncol do
                nodes[#nodes + 1] = i(order)
                order = order + 1
                nodes[#nodes + 1] = t(col == ncol and " \\\\" or " & ")
            end
        end
        if inline then
            nodes[#nodes + 1] = t("\\end{" .. flag .. "matrix}")
        else
            nodes[#nodes + 1] = t({ "", "\\end{" .. flag .. "matrix}" })
        end
        return ls.snippet_node(nil, nodes)
    end
end

function M.toggle_frac(text)
    local str = text:gsub("\\frac", "\1"):gsub("\\dfrac", "\2")
    local chars = {}
    for k = 1, #str do
        chars[k] = str:sub(k, k)
    end
    local depth, test = 0, 0
    local idx = #chars
    while idx >= 1 do
        local ch = chars[idx]
        if ch == "}" then
            depth = depth + 1
        end
        if ch == "{" then
            depth = depth - 1
        end
        if test == 2 and depth == 0 then
            if ch == "\1" then
                chars[idx] = "\2"
                break
            end
            if ch == "\2" then
                chars[idx] = "\1"
                break
            end
        end
        if depth == 0 then
            test = test + 1
        end
        idx = idx - 1
    end
    if idx < 1 then
        return text
    end
    return (table.concat(chars):gsub("\1", "\\frac"):gsub("\2", "\\dfrac"))
end

function M.toggle_paren(text, closing)
    local bra = { "(", "[" }
    local ket = { ")", "]" }
    local idx = closing == "]" and 2 or 1
    local other = idx == 1 and 2 or 1
    local chars = {}
    for k = 1, #text do
        chars[k] = text:sub(k, k)
    end
    local pos = #chars
    chars[pos] = ket[other]
    local depth = 1
    while pos >= 1 do
        if chars[pos] == ket[idx] then
            depth = depth + 1
        end
        if chars[pos] == bra[idx] then
            depth = depth - 1
        end
        if depth == 0 then
            chars[pos] = bra[other]
            break
        end
        pos = pos - 1
    end
    return table.concat(chars)
end

function M.toggle_left_right(text, closing)
    local bracket, test_bracket
    if closing == ")" then
        bracket = { "\\left(", "\\right)", "(", ")" }
        test_bracket = { "\\left%(", "\\right%)", "%(", "%)" }
    elseif closing == "]" then
        bracket = { "\\left[", "\\right]", "[", "]" }
        test_bracket = { "\\left%[", "\\right%]", "%[", "%]" }
    elseif closing == "\\}" then
        bracket = { "\\left\\{", "\\right\\}", "\\{", "\\}" }
        test_bracket = { "\\left\\%{", "\\right\\%}", "\\%{", "\\%}" }
    else
        return text
    end
    local rep = { "\1", "\2", "\3", "\4" }
    for k = 1, 4 do
        text = text:gsub(test_bracket[k], rep[k])
    end
    local chars = {}
    for k = 1, #text do
        chars[k] = text:sub(k, k)
    end
    local pos = #chars
    chars[pos] = chars[pos] == "\4" and "\2" or "\4"
    local depth = 0
    while pos >= 1 do
        if chars[pos] == "\2" or chars[pos] == "\4" then
            depth = depth + 1
        end
        if chars[pos] == "\3" or chars[pos] == "\1" then
            depth = depth - 1
        end
        if depth == 0 then
            chars[pos] = chars[pos] == "\3" and "\1" or "\3"
            break
        end
        pos = pos - 1
    end
    local str = table.concat(chars)
    for k = 4, 1, -1 do
        str = str:gsub(rep[k], bracket[k])
    end
    return str
end

function M.split_eval_at(text)
    local depth = 0
    local pos = #text
    while true do
        local ch = text:sub(pos, pos)
        if ch == "}" or ch == ")" or ch == "]" then
            depth = depth + 1
        end
        if ch == "{" or ch == "(" or ch == "[" then
            depth = depth - 1
        end
        if ((ch == "+" or ch == "=" or ch == "-" or ch == "&" or ch == ",") and depth == 0) or depth < 0 then
            break
        end
        pos = pos - 1
        if pos < 1 then
            break
        end
    end
    return text:sub(1, pos), text:sub(pos + 1)
end

function M.auto(trigger, nodes, opts)
    return ls.snippet(
        vim.tbl_extend("force", {
            trig = trigger,
            regTrig = true,
            trigEngine = "ecma",
            wordTrig = false,
        }, opts or {}),
        nodes
    )
end

function M.autop(trigger, nodes, opts)
    return ls.snippet(
        vim.tbl_extend("force", {
            trig = trigger,
            wordTrig = false,
        }, opts or {}),
        nodes
    )
end

return M
