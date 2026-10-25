local config = {}
local symbols = Vellum.symbols
local config_root = vim.fn.stdpath("config")

config.colorizer = {
    "NvChad/nvim-colorizer.lua",
    main = "colorizer",
    event = "VellumLoad",
    opts = {
        lazy_load = true,
        options = {
            parsers = {
                css = true,
                css_fn = true,
                names = false,
            },
            display = {
                mode = "virtualtext",
                virtualtext = { position = "after" },
            },
            always_update = true,
        },
    },
    config = function(opts)
        require("colorizer").setup(opts)
        vim.cmd("ColorizerToggle")
    end,
}

config.dashboard = {
    "nvimdev/dashboard-nvim",
    event = "VellumAfter colorscheme",
    opts = {
        theme = "doom",
        config = {
            vertical_center = true,
            header = {
                " ",
                "██╗   ██╗███████╗██╗     ██╗     ██╗   ██║███╗   ███╗",
                "██║   ██║██╔════╝██║     ██║     ██║   ██║████╗ ████║",
                "██║   ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║",
                "╚██╗ ██╔╝██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║",
                " ╚████╔╝ ███████╗███████╗███████╗╚██████╔╝██║ ╚═╝ ██║",
                "  ╚═══╝  ╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝",
                " ",
                string.format("                      %s                       ", require("core.utils").version),
                " ",
            },
            center = {
                {
                    icon = " ",
                    desc = "Vellum Plugin Profile",
                    action = "VellumProfile",
                },
                {
                    icon = " ",
                    desc = "Edit plugin registry",
                    action = string.format("edit %s/lua/plugins/config.lua", config_root),
                },
                {
                    icon = " ",
                    desc = "Mason",
                    action = "execute 'doautocmd User Dashboard-Mason' | Mason",
                },
                {
                    icon = " ",
                    desc = "About Vellum",
                    action = "VellumAbout",
                },
            },
            footer = { "📜 Hope that you enjoy using Vellum 😀😀😀" },
        },
    },
    config = function(opts)
        require("dashboard").setup(opts)

        if vim.api.nvim_buf_get_name(0) == "" then
            vim.cmd("Dashboard")
        end

        vim.cmd("highlight DashboardFooter cterm=NONE gui=NONE")
    end,
}

config.fidget = {
    "j-hui/fidget.nvim",
    event = "VeryLazy",
    opts = {
        notification = {
            override_vim_notify = true,
            window = {
                winblend = 0,
                x_padding = 2,
                align = "top",
            },
        },
        integration = {
            ["nvim-tree"] = {
                enable = false,
            },
        },
    },
}

config.gitsigns = {
    "lewis6991/gitsigns.nvim",
    event = "VellumLoad",
    main = "gitsigns",
    opts = {},
    keys = {
        { "<leader>gn", "<Cmd>Gitsigns next_hunk<CR>", desc = "next hunk", silent = true },
        { "<leader>gp", "<Cmd>Gitsigns prev_hunk<CR>", desc = "prev hunk", silent = true },
        { "<leader>gP", "<Cmd>Gitsigns preview_hunk<CR>", desc = "preview hunk", silent = true },
        { "<leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", desc = "stage hunk", silent = true },
        { "<leader>gu", "<Cmd>Gitsigns undo_stage_hunk<CR>", desc = "undo stage", silent = true },
        { "<leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", desc = "reset hunk", silent = true },
        { "<leader>gB", "<Cmd>Gitsigns stage_buffer<CR>", desc = "stage buffer", silent = true },
        { "<leader>gb", "<Cmd>Gitsigns blame<CR>", desc = "git blame", silent = true },
        { "<leader>gl", "<Cmd>Gitsigns blame_line<CR>", desc = "git blame line", silent = true },
    },
}

config["grug-far"] = {
    "MagicDuck/grug-far.nvim",
    vscode = true,
    opts = {
        startInInsertMode = true,
        windowCreationCommand = "tabnew %",
    },
    keys = {
        { "<leader>ug", "<Cmd>GrugFar<CR>", desc = "find and replace", silent = true },
    },
}

config.hop = {
    "smoka7/hop.nvim",
    vscode = true,
    main = "hop",
    opts = function()
        return {
            hint_position = require("hop.hint").HintPosition.END,
            keys = "fjghdksltyrueiwoqpvbcnxmza",
        }
    end,
    keys = {
        { "<leader>hp", "<Cmd>HopWord<CR>", desc = "hop word", silent = true },
    },
}

config["indent-blankline"] = {
    "lukas-reineke/indent-blankline.nvim",
    event = "VellumAfter treesitter",
    main = "ibl",
    opts = {
        exclude = {
            filetypes = { "dashboard", "terminal", "help", "log", "markdown", "TelescopePrompt" },
        },
        indent = {
            highlight = {
                "IblIndent",
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        },
    },
}

config.lualine = {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VellumLoad",
    main = "lualine",
    opts = {
        options = {
            theme = "auto",
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            disabled_filetypes = { "nvim-undotree", "diff" },
        },
        extensions = { "nvim-tree" },
        sections = {
            lualine_b = {
                function()
                    return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                end,
                "branch",
                "diff",
            },
            lualine_c = {
                { "filename", symbols = { modified = "%#WarningMsg#●" } },
                { "diagnostics", update_in_insert = true },
            },
            lualine_x = {
                "filesize",
                { "fileformat", symbols = { unix = symbols.Unix, dos = symbols.Dos, mac = symbols.Mac } },
                "encoding",
                "filetype",
            },
        },
    },
}

config.luasnip = {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    opts = {
        enable_autosnippets = true,
    },
    config = function(opts)
        local luasnip = require("luasnip")
        luasnip.setup(opts)
        luasnip.filetype_extend("plaintex", { "tex" })

        local from_vscode = require("luasnip.loaders.from_vscode")
        from_vscode.lazy_load({
            paths = vim.fs.joinpath(vim.fn.stdpath("config"), "snippets"),
        })
        vim.api.nvim_create_autocmd("User", {
            pattern = "VellumAfter blink-cmp",
            once = true,
            callback = function()
                from_vscode.lazy_load()
            end,
        })

        require("luasnip.loaders.from_lua").lazy_load({
            paths = vim.fs.joinpath(vim.fn.stdpath("config"), "lua/snippets"),
        })
    end,
}

config["markdown-preview"] = {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    config = function()
        vim.g.mkdp_filetypes = { "markdown" }
        vim.g.mkdp_auto_close = 0
    end,
    build = "cd app && npm install",
    keys = {
        {
            "<A-b>",
            "<Cmd>MarkdownPreviewToggle<CR>",
            desc = "markdown preview",
            ft = "markdown",
            silent = true,
        },
    },
}

config.neogit = {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    main = "neogit",
    opts = {
        disable_hint = true,
        status = {
            recent_commit_count = 30,
        },
        commit_editor = {
            kind = "auto",
            show_staged_diff = false,
        },
    },
    keys = {
        { "<leader>gt", "<Cmd>Neogit<CR>", desc = "neogit", silent = true },
    },
    config = function(opts)
        require("neogit").setup(opts)
        Vellum.ft.NeogitCommitMessage = function()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
        end
        Vellum.ft["Neogit*"] = function()
            vim.wo.colorcolumn = ""
        end
    end,
}

config.autopairs = {
    "windwp/nvim-autopairs",
    vscode = true,
    event = "InsertEnter",
    main = "nvim-autopairs",
    opts = {},
    config = function()
        local npairs = require("nvim-autopairs")
        npairs.setup({})
        local Rule = require("nvim-autopairs.rule")
        npairs.add_rule(Rule("<", ">", {
            "lua",
            "c",
            "cpp",
            "typescript",
            "rust",
        }):with_pair(function(opts)
            local prev = opts.line:sub(opts.col - 1, opts.col - 1)
            return prev:match("[%w_:)'\"]") ~= nil
        end))
    end,
}

config.scrollview = {
    "dstein64/nvim-scrollview",
    event = "VellumLoad",
    main = "scrollview",
    opts = {
        excluded_filetypes = { "nvimtree" },
        current_only = true,
        winblend = 75,
        base = "right",
        column = 1,
    },
}

config.transparent = {
    "xiyaowong/transparent.nvim",
    event = "VeryLazy",
    opts = {
        extra_groups = {
            "NvimTreeNormal",
            "NvimTreeNormalNC",
            "TelescopeNormal",
        },
        exclude_groups = {
            "CursorLine",
        },
    },
    init = function()
        Vellum.__TRANSPARENT_AUGROUP = vim.api.nvim_create_augroup("transparent", { clear = true })
        Vellum.__FORCE_TRANSPARENT_AUTOCMD = vim.api.nvim_create_autocmd("ColorScheme", {
            group = Vellum.__TRANSPARENT_AUGROUP,
            callback = function()
                vim.api.nvim_set_hl(0, "Normal", { fg = vim.api.nvim_get_hl(0, { name = "Normal" }).fg })
            end,
        })
    end,
    config = function(opts)
        vim.api.nvim_del_autocmd(Vellum.__FORCE_TRANSPARENT_AUTOCMD)
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = Vellum.__TRANSPARENT_AUGROUP,
            callback = function()
                local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
                local foreground = string.format("#%06x", normal_hl.fg)
                local background = string.format("#%06x", normal_hl.bg or 0)
                vim.cmd("highlight default VellumNormal guifg=" .. foreground .. " guibg=" .. background)

                require("transparent").clear()
            end,
        })

        local transparent_cache = vim.fs.joinpath(vim.fn.stdpath("data"), "transparent_cache")
        if not vim.uv.fs_stat(transparent_cache) then
            local f = io.open(transparent_cache, "w")
            f:write("true")
            f:close()
        end

        require("transparent").setup(opts)

        vim.api.nvim_exec_autocmds("ColorScheme", { group = "transparent" })

        local old_get_hl = vim.api.nvim_get_hl
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.api.nvim_get_hl = function(ns_id, opt)
            if opt.name == "Normal" then
                local attempt = old_get_hl(0, { name = "VellumNormal" })
                if next(attempt) ~= nil then
                    opt.name = "VellumNormal"
                end
            end
            return old_get_hl(ns_id, opt)
        end

        local old_set_hl = vim.api.nvim_set_hl
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.api.nvim_set_hl = function(ns_id, name, val)
            if val.bg == "bg" then
                val.bg = old_get_hl(0, { name = "VellumNormal" }).bg
            end
            return old_set_hl(ns_id, name, val)
        end
    end,
}

config.tree = {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            local opt = { buffer = bufnr, silent = true }

            api.config.mappings.default_on_attach(bufnr)

            require("core.utils").group_map({
                edit = {
                    "n",
                    "<CR>",
                    function()
                        local node = api.tree.get_node_under_cursor()
                        if node.name ~= ".." and node.fs_stat.type == "file" then
                            -- stylua: ignore start
                            local extensions_opened_externally = {
                                "avi", "bmp", "doc", "docx", "exe", "flv", "gif", "jpg", "jpeg", "m4a", "mov", "mp3",
                                "mp4", "mpeg", "mpg", "pdf", "png", "ppt", "pptx", "psd", "pub", "rar", "rtf", "tif",
                                "tiff", "wav", "xls", "xlsx", "zip",
                            }
                            -- stylua: ignore end
                            if table.find(extensions_opened_externally, node.extension) then
                                api.node.run.system()
                                return
                            end
                        end

                        api.node.open.edit()
                    end,
                },
                vertical_split = { "n", "V", api.node.open.vertical },
                horizontal_split = { "n", "H", api.node.open.horizontal },
                toggle_hidden_file = { "n", ".", api.tree.toggle_hidden_filter },
                reload = { "n", "<F5>", api.tree.reload },
                create = { "n", "a", api.fs.create },
                remove = { "n", "d", api.fs.remove },
                rename = { "n", "r", api.fs.rename },
                cut = { "n", "x", api.fs.cut },
                copy = { "n", "y", api.fs.copy.node },
                paste = { "n", "p", api.fs.paste },
                system_run = { "n", "s", api.node.run.system },
                show_info = { "n", "i", api.node.show_info_popup },
            }, opt)
        end,
        renderer = {
            group_empty = true,
        },
        git = {
            enable = false,
        },
        update_focused_file = {
            enable = true,
        },
        filters = {
            dotfiles = false,
            custom = { "node_modules", "^Desktop\\.ini$", "^\\.DS_Store$", "^\\.git$" },
            exclude = { ".gitignore" },
        },
        respect_buf_cwd = true,
        view = {
            width = 30,
            side = "left",
            signcolumn = "yes",
        },
        actions = {
            open_file = {
                resize_window = true,
                quit_on_open = true,
            },
        },
    },
    keys = {
        { "<leader>uf", "<Cmd>NvimTreeToggle<CR>", desc = "toggle nvim tree", silent = true },
    },
}

config.treesitter = {
    "nvim-treesitter/nvim-treesitter",
    version = "main",
    build = ":TSUpdate",
    dependencies = { "hiphish/rainbow-delimiters.nvim" },
    event = "VellumAfter colorscheme",
    opts = {
        -- stylua: ignore start
        ensure_installed = {
            "c", "c_sharp", "cpp", "css", "dockerfile", "fish", "go", "html", "ini", "javascript", "json",
            "latex", "lua", "markdown", "markdown_inline", "python", "query", "rust", "toml", "typescript", "typst",
            "tsx", "vim", "vimdoc", "yaml", "bibtex"
        },
        -- stylua: ignore end
    },
    config = function(opts)
        local nvim_treesitter = require("nvim-treesitter")
        nvim_treesitter.setup()

        vim.treesitter.language.register("latex", { "tex", "plaintex" })

        local builtin_syntax_filetypes = { sh = true, bash = true, zsh = true, ps1 = true }

        local pattern = {}
        for _, parser in ipairs(opts.ensure_installed) do
            local has_parser, _ = pcall(vim.treesitter.language.inspect, parser)

            if not has_parser then
                nvim_treesitter.install(parser)
            else
                for _, ft in ipairs(vim.treesitter.language.get_filetypes(parser)) do
                    if not builtin_syntax_filetypes[ft] then
                        pattern[#pattern + 1] = ft
                    end
                end
            end
        end

        local group = vim.api.nvim_create_augroup("NvimTreesitterFt", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = pattern,
            callback = function(ev)
                local max_filesize = Vellum.max_file_size or (1024 * 1024)
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
                if not (ok and stats and stats.size > max_filesize) then
                    vim.treesitter.start()
                    if vim.bo.filetype ~= "dart" then
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end
            end,
        })

        local rainbow_delimiters = require("rainbow-delimiters")

        vim.g.rainbow_delimiters = {
            strategy = {
                [""] = rainbow_delimiters.strategy["global"],
                vim = rainbow_delimiters.strategy["local"],
            },
            query = {
                [""] = "rainbow-delimiters",
                lua = "rainbow-blocks",
            },
            highlight = {
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
        }
        rainbow_delimiters.enable()

        vim.treesitter.language.register("query", "scheme")

        vim.api.nvim_exec_autocmds("FileType", { group = "NvimTreesitterFt" })
    end,
}

config.surround = {
    "kylechui/nvim-surround",
    vscode = true,
    event = "VellumLoad",
}

config.telescope = {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && "
                .. "cmake --build build --config Release && "
                .. "cmake --install build --prefix build",
        },
    },
    cmd = "Telescope",
    opts = {
        defaults = {
            initial_mode = "insert",
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",
                    ["<C-k>"] = "move_selection_previous",
                    ["<C-n>"] = "cycle_history_next",
                    ["<C-p>"] = "cycle_history_prev",
                    ["<C-c>"] = "close",
                    ["<C-u>"] = "preview_scrolling_up",
                    ["<C-d>"] = "preview_scrolling_down",
                },
            },
        },
        pickers = {
            buffers = {
                mappings = {
                    i = {
                        ["<M-d>"] = function(...)
                            local actions = require("telescope.actions")

                            local old_buf_delete = vim.api.nvim_buf_delete
                            vim.api.nvim_buf_delete = function(bufnr)
                                local result = require("core.utils").bdelete(bufnr)
                                vim.api.nvim_buf_delete = old_buf_delete
                                if not result then
                                    error("Buffer not deleted")
                                end
                            end

                            actions.delete_buffer(...)
                        end,
                        ["<M-v>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "buffers", "vsplit | buffer")
                        end,
                        ["<M-s>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "buffers", "split | buffer")
                        end,
                    },
                },
            },
            live_grep = {
                mappings = {
                    i = {
                        ["<M-v>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "live_grep", "vsplit")
                        end,
                        ["<M-s>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "live_grep", "split")
                        end,
                    },
                },
            },
            find_files = {
                mappings = {
                    i = {
                        ["<M-v>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "find_files", "vsplit")
                        end,
                        ["<M-s>"] = function(bufnr)
                            Vellum._telescope_split(bufnr, "find_files", "split")
                        end,
                    },
                },
            },
        },
        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
        },
    },
    config = function(opts)
        local telescope = require("telescope")

        Vellum._telescope_split = function(prompt_bufnr, prompt_buf_type, split_cmd)
            local selection = require("telescope.actions.state").get_selected_entry()
            local target = ""
            local lnum = 1
            local col = 0
            if selection ~= nil then
                if prompt_buf_type == "buffers" then
                    target = selection.bufnr
                    lnum = selection.lnum
                end
                if prompt_buf_type == "live_grep" then
                    target = selection.cwd .. "/" .. selection.filename
                    lnum = selection.lnum
                    col = selection.col
                end
                if prompt_buf_type == "find_files" then
                    target = selection.cwd .. "/" .. selection[1]
                end
            end
            target = string.gsub(target, " ", "\\ ")
            require("telescope.actions").close(prompt_bufnr)
            if target ~= "" then
                vim.cmd(split_cmd .. " " .. target)
                vim.api.nvim_win_set_cursor(0, { lnum, col })
            end
        end

        telescope.setup(opts)
        telescope.load_extension("fzf")
    end,
    keys = {
        { "<leader>tf", "<Cmd>Telescope find_files<CR>", desc = "find file", silent = true },
        { "<leader>t<C-f>", "<Cmd>Telescope live_grep<CR>", desc = "live grep", silent = true },
        { "<C-k><C-t>", require("plugins.utils").select_colorscheme, desc = "select colorscheme" },
        { "<leader>uc", require("plugins.utils").view_configuration, desc = "view configuration" },
        { "<leader>bi", "<Cmd>Telescope buffers<CR>", desc = "manage buffers" },
    },
}

config["todo-comments"] = {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VellumLoad",
    main = "todo-comments",
    opts = {},
    keys = {
        { "<leader>ut", "<Cmd>TodoTelescope<CR>", desc = "todo list", silent = true },
    },
}

config.ufo = {
    "kevinhwang91/nvim-ufo",
    dependencies = {
        "kevinhwang91/promise-async",
    },
    event = "VeryLazy",
    opts = {
        preview = {
            win_config = {
                border = "rounded",
                winhighlight = "Normal:Folded",
                winblend = 0,
            },
        },
    },
    config = function(opts)
        vim.opt.foldenable = true

        require("ufo").setup(opts)
    end,
    keys = {
        {
            "zR",
            function()
                require("ufo").openAllFolds()
            end,
            desc = "Open all folds",
        },
        {
            "zM",
            function()
                require("ufo").closeAllFolds()
            end,
            desc = "Close all folds",
        },
        {
            "zp",
            function()
                require("ufo").peekFoldedLinesUnderCursor()
            end,
            desc = "Preview folded content",
        },
    },
}

config["which-key"] = {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        icons = {
            mappings = false,
        },
        plugins = {
            marks = true,
            registers = true,
            spelling = {
                enabled = false,
            },
            presets = {
                operators = false,
                motions = true,
                text_objects = true,
                windows = true,
                nav = true,
                z = true,
                g = true,
            },
        },
        spec = {
            { "<leader>b", group = "+buffer" },
            { "<leader>c", group = "+comment" },
            { "<leader>g", group = "+git" },
            { "<leader>h", group = "+hop" },
            { "<leader>l", group = "+lsp" },
            { "<leader>q", group = "+quickfix" },
            { "<leader>s", group = "+shell" },
            { "<leader>t", group = "+telescope" },
            { "<leader>u", group = "+utils" },
        },
        win = {
            border = "none",
            padding = { 1, 0, 1, 0 },
            wo = {
                winblend = 0,
            },
            zindex = 1000,
        },
    },
}

config.winsep = {
    "nvim-zh/colorful-winsep.nvim",
    event = "VellumAfter colorscheme",
    opts = {
        border = "single",
        highlight = function()
            vim.cmd("highlight link ColorfulWinsep VellumNormal")
        end,
        animate = {
            enabled = false,
        },
    },
}

config["better-escape"] = {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    main = "better_escape",
    opts = {
        default_mappings = false,
        mappings = {
            i = { j = { j = "<Esc>" } },
            t = { j = { j = [[<C-\><C-n>]] } }
        },
    },
}

config["cyberdream"] = { "scottmckendry/cyberdream.nvim", lazy = true }
config["everforest"] = { "sainnhe/everforest", lazy = true }
config["gruvbox"] = { "ellisonleao/gruvbox.nvim", lazy = true }
config["kanagawa"] = { "rebelot/kanagawa.nvim", lazy = true }
config["monet"] = { "fynnfluegge/monet.nvim", lazy = true }
config["nightfox"] = { "EdenEast/nightfox.nvim", lazy = true }
config["tokyonight"] = { "folke/tokyonight.nvim", lazy = true }
config["vague"] = { "vague-theme/vague.nvim", lazy = true }

Vellum.plugins = config
