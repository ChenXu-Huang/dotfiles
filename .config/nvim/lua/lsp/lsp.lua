local lsp = {
    ["bash-language-server"] = {
        formatter = "shfmt",
    },
    clangd = {},
    ["css-lsp"] = {
        formatter = "prettier",
        setup = {
            settings = {
                css = {
                    validate = true,
                    lint = {
                        unknownAtRules = "ignore",
                    },
                },
                less = {
                    validate = true,
                    lint = {
                        unknownAtRules = "ignore",
                    },
                },
                scss = {
                    validate = true,
                    lint = {
                        unknownAtRules = "ignore",
                    },
                },
            },
        },
    },
    ["emmet-ls"] = {
        setup = {
            filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
        },
    },
    emmylua_ls = {
        formatter = "stylua",
        setup = {},
    },
    flutter = {
        managed_by_plugin = true,
    },
    gopls = {
        formatter = "gofumpt",
        setup = {
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                },
            },
        },
    },
    ["html-lsp"] = {
        formatter = "prettier",
    },
    ["json-lsp"] = {
        formatter = "prettier",
    },
    ["lua-language-server"] = {
        formatter = "stylua",
        setup = {
            settings = {
                Lua = {
                    runtime = {
                        version = "LuaJIT",
                        path = (function()
                            local runtime_path = vim.split(package.path, ";")
                            table.insert(runtime_path, "lua/?.lua")
                            table.insert(runtime_path, "lua/?/init.lua")
                            return runtime_path
                        end)(),
                    },
                    diagnostics = {
                        globals = { "vim" },
                    },
                    hint = {
                        enable = true,
                    },
                    workspace = {
                        library = {
                            vim.env.VIMRUNTIME,
                            "${3rd}/luv/library",
                        },
                        checkThirdParty = false,
                    },
                    telemetry = {
                        enable = false,
                    },
                },
            },
        },
        enabled = true,
    },
    omnisharp = {
        formatter = "csharpier",
        setup = {
            cmd = {
                "dotnet",
                vim.fs.joinpath(vim.fn.stdpath("data"), "mason/packages/omnisharp/libexec/Omnisharp.dll"),
            },
            on_attach = function(client, _)
                client.server_capabilities.semanticTokensProvider = nil
            end,
        },
    },
    pyright = {
        formatter = { "ruff", "ruff_format" },
        setup = {
            settings = {
                pyright = { disableTaggedHints = false },
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "openFilesOnly",
                        typeCheckingMode = "basic",
                    },
                },
            },
            on_attach = function(client, bufnr)
                local candidates = { require("core.utils").get_root() }
                local level = 0
                for dir in vim.fs.parents(vim.api.nvim_buf_get_name(bufnr)) do
                    candidates[#candidates + 1] = dir
                    level = level + 1
                    if level >= 3 then
                        break
                    end
                end
                for _, candidate in ipairs(candidates) do
                    local venv_pythons = { vim.fs.joinpath(candidate, ".venv", "bin", "python3") }
                    if require("core.utils").is_windows then
                        table.insert(venv_pythons, 1, vim.fs.joinpath(candidate, ".venv", "Scripts", "python.exe"))
                    end
                    for _, python in ipairs(venv_pythons) do
                        if vim.uv.fs_stat(python) then
                            client.settings.python = vim.tbl_deep_extend(
                                "force",
                                client.settings.python --[[@as table]],
                                { pythonPath = python }
                            )
                            return
                        end
                    end
                end
            end,
        },
        enabled = true,
    },
    rust = {
        managed_by_plugin = true,
    },
    texlab = {
        formatter = "tex_fmt",
        setup = {},
    },
    tinymist = {
        setup = {
            settings = {
                formatterMode = "typstyle",
                formatterPrintWidth = 120,
                formatterProseWrap = true,
            },
        },
    },
    ["typescript-language-server"] = {
        formatter = "prettier",
        setup = {
            root_dir = function(_, on_dir)
                on_dir(require("core.utils").get_root())
            end,
            on_attach = function(client)
                if #vim.lsp.get_clients({ name = "denols" }) > 0 then
                    client.stop()
                end
            end,
        },
    },
}

Vellum.lsp = lsp
