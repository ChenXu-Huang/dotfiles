# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `desc` descriptions on all custom key mappings (core, bufferline, lspsaga,
  nvim-tree, hop, toggleterm) so they show up in keymap listings; also fixed
  the descriptions in `nvim/lua/core/keymap.lua` being passed as an ignored
  fifth argument to `vim.keymap.set` instead of inside the options table.

## [0.1.0] - 2026-10-03

### Added

- `nvim/lua/plugins/mason.lua`: `lua_ls` (lua-language-server) configuration
  that registers `vim` as a recognized global for diagnostics;
  `nvim/lua/plugins/mason-tool-installer.lua` now also ensures
  `lua-language-server` is installed (using the Mason package name because the
  lspconfig-name mapping is unavailable while mason-lspconfig lazy-loads).
- `docs/ARCHITECTURE.md` describing the repository layout, Neovim startup
  flow, plugin set, and setup scripts.
- `docs/CHANGELOG.md` as the running history of the project.
- `AGENTS.md` rewrite: project overview, conventions, and a reference to
  `docs/ARCHITECTURE.md`.
- `scripts/setup.sh`: POSIX sh setup for macOS and Linux that symlinks
  `${XDG_CONFIG_HOME:-~/.config}/nvim` to the repo's `nvim/` directory.
- `.gitattributes` enforcing LF checkout so the POSIX setup script works when
  the repository is cloned on Windows.
- `nvim/lua/plugins/grug-far.lua`: grug-far.nvim for project-wide search and
  replace, lazy-loaded on its `GrugFar` command.
- `nvim/lua/plugins/indent-blankline.lua`: indent-blankline.nvim (`ibl`) for
  indentation guides.
- Neovide GUI settings in `nvim/lua/core/basic.lua`: JetBrainsMono Nerd Font,
  0.85 scale factor, 0.95 opacity, and 144 Hz refresh rate.
- Neovim configuration under `nvim/` with an auto-loading `lua/core/`
  directory (`basic.lua`, `keymap.lua`, `lazy.lua`) and per-plugin specs under
  `lua/plugins/` managed by lazy.nvim.
- Plugin set: blink.cmp, bufferline, hop, lspsaga, lualine, mason +
  mason-lspconfig + mason-tool-installer (pyright, ruff), none-ls,
  nvim-autopairs, nvim-surround, nvim-tree, toggleterm, tokyonight, and
  nvim-treesitter.
- Windows setup scripts (`scripts/setup.ps1`, `scripts/setup.bat`) linking the
  repo's `nvim/` folder to `%LOCALAPPDATA%\nvim`; Unix `scripts/setup`
  placeholder.
- Repository hygiene: `.editorconfig` (LF, UTF-8, 4-space indent), `.gitignore`
  (excludes `lazy-lock.json` and `temp/`), and initial `AGENTS.md`.

### Changed

- `nvim/lua/plugins/mason.lua`: per-server LSP settings (pyright, lua_ls)
  were extracted from the plugin spec's `init` into `nvim/lsp/<server>.lua`
  files, which Neovim 0.11+ auto-discovers from the runtimepath; all
  language-server configs now live in one directory.
- `scripts/setup.ps1` and `scripts/setup.sh` now skip when the target is
  already a link, and warn and exit when a real config occupies the target,
  leaving the backup to the user.
- `nvim/lua/core/keymap.lua`: `maplocalleader` changed from `\` to `,`.

### Removed

- `scripts/setup.bat`; the PowerShell script is the single Windows setup
  entry point.

### Fixed

- `nvim/lua/plugins/mason-tool-installer.lua`: pyright and ruff were never
  installed because the spec lazy-loaded the plugin on `VeryLazy`.
  mason-tool-installer triggers its initial install from a one-shot `VimEnter`
  autocmd registered when it is sourced, and `VeryLazy` fires after `VimEnter`,
  so the autocmd never fired and `ensure_installed` was silently ignored. The
  plugin now loads eagerly (`lazy = false`).
- `nvim/lua/plugins/toggleterm.lua`: the vertical-terminal mapping crashed on
  a `vim.o.coloums` typo and recreated the terminal object on every keypress
  (so it opened but never toggled closed); the terminal is now created lazily
  once and reused, the split width is floored to an integer, and the key is
  spelled `<C-A-Bslash>`.
- Shell configuration: replaced the broken `vim.opt.shell = shell`
  (undefined variable, left the shell at `cmd.exe`) with a cross-platform
  block that prefers `pwsh` whenever the executable is available; on Windows
  it also sets `shellcmdflag`, `shellquote` and `shellxquote` (Neovim does
  not adjust them automatically), so toggleterm and external commands run
  under PowerShell 7 there.

[Unreleased]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ChenXu-Huang/dotfiles/releases/tag/v0.1.0
