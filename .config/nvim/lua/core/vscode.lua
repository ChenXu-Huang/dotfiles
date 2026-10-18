-- Loaded only when Neovim runs inside vscode-neovim: the editor owns the UI and
-- the LSP client, so `lua/plugins/pack.lua` loads just the plugin sections
-- marked `vscode = true` and the mappings below hand everything else over to
-- VS Code itself.
--
-- The module is deliberately named `core.vscode` and never `vscode`: the
-- extension ships a `vscode` Lua module of its own, and a module of the same
-- name in the config would shadow it.
vim.g.clipboard = vim.g.vscode_clipboard

Vellum.keymap.open_terminal = nil

local function action(name)
    return ("<Cmd>lua require('vscode').action('%s')<CR>"):format(name)
end

Vellum.keymap.format_buffer = { "n", "<leader>lf", action("editor.action.formatDocument") }
Vellum.keymap.format_selection = { "v", "<leader>lf", action("editor.action.formatSelection") }
Vellum.keymap.rename_symbol = { "n", "<leader>lr", action("editor.action.rename") }
Vellum.keymap.code_action = { "n", "<leader>lc", action("editor.action.quickFix") }
Vellum.keymap.goto_definition = { "n", "<leader>ld", action("editor.action.revealDefinition") }
Vellum.keymap.peek_definition = { "n", "<leader>lD", action("editor.action.peekDefinition") }
Vellum.keymap.goto_implementation = { "n", "<leader>li", action("editor.action.goToImplementation") }
Vellum.keymap.hover_documentation = { "n", "<leader>lh", action("editor.action.showHover") }
Vellum.keymap.find_references = { "n", "<leader>lR", action("editor.action.referenceSearch.trigger") }
Vellum.keymap.next_diagnostic = { "n", "<leader>ln", action("editor.action.marker.next") }
Vellum.keymap.prev_diagnostic = { "n", "<leader>lp", action("editor.action.marker.prev") }
Vellum.keymap.problems_panel = { "n", "<leader>lt", action("workbench.actions.view.problems") }
Vellum.keymap.find_file = { "n", "<leader>tf", action("workbench.action.quickOpen") }
Vellum.keymap.live_grep = { "n", "<leader>t<C-f>", action("workbench.action.findInFiles") }
Vellum.keymap.manage_buffers = { "n", "<leader>bi", action("workbench.action.showAllEditors") }
Vellum.keymap.view_configuration = { "n", "<leader>uc", action("workbench.action.openSettingsJson") }
Vellum.keymap.select_colorscheme = { "n", "<C-k><C-t>", action("workbench.action.selectTheme") }
Vellum.keymap.toggle_sidebar = { "n", "<leader>uf", action("workbench.action.toggleSidebarVisibility") }
Vellum.keymap.toggle_terminal = { "n", "<leader>st", action("workbench.action.terminal.toggleTerminal") }
Vellum.keymap.scm_view = { "n", "<leader>gt", action("workbench.view.scm") }
Vellum.keymap.next_hunk = { "n", "<leader>gn", action("editor.action.dirtydiff.next") }
Vellum.keymap.prev_hunk = { "n", "<leader>gp", action("editor.action.dirtydiff.prev") }
Vellum.keymap.stage_hunk = { "n", "<leader>gs", action("git.stageSelectedRanges") }
Vellum.keymap.unstage_hunk = { "n", "<leader>gu", action("git.unstageSelectedRanges") }
Vellum.keymap.reset_hunk = { "n", "<leader>gr", action("git.revertSelectedRanges") }
Vellum.keymap.open_all_folds = { "n", "zR", action("editor.unfoldAll") }
Vellum.keymap.close_all_folds = { "n", "zM", action("editor.foldAll") }

local has_vscode_api, vscode = pcall(require, "vscode")
if has_vscode_api and vscode.notify then
    vim.notify = vscode.notify
end
