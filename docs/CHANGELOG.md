# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `scripts/setup.sh` (macOS-first) and `scripts/setup.ps1` environment
  checks: they warn when Neovim is missing or older than 0.11 and verify the
  external dependencies of the main-branch nvim-treesitter (tree-sitter CLI
  and a C compiler). Missing dependencies are installed automatically with
  Homebrew on macOS and with Scoop on Windows; other cases print install
  hints.
- `-f`/`--force` (`-Force` on Windows) option for both setup scripts: a
  foreign link at the target is removed, a real file or directory is backed
  up to `nvim.bak.<timestamp>` before linking.
- `scripts/setup.sh` strict mode (`set -eu`), platform detection, `--help`,
  and colored output on interactive terminals.
- `desc` descriptions on all custom key mappings (core, bufferline, lspsaga,
  nvim-tree, hop, toggleterm) so they show up in keymap listings; also fixed
  the descriptions in `nvim/lua/core/keymap.lua` being passed as an ignored
  fifth argument to `vim.keymap.set` instead of inside the options table.
- Window title (`vim.opt.titlestring`) showing the current working directory,
  and the lualine statusline now displays the working-directory basename next
  to the git branch.
- nvim-autopairs angle-bracket (`<`/`>`) rule for html, xml, lua, c, cpp,
  typescript, and rust that only expands after a word character or a closing
  delimiter.

### Changed

- Both setup scripts now skip only when the target link already points at
  this repository; a link pointing elsewhere is reported (and replaced with
  `-f`/`-Force`) instead of being silently skipped.
- nvim-tree follows the working directory (`sync_root_with_cwd`,
  `respect_buf_cwd`) and reveals the focused file, updating the tree root
  accordingly.

### Fixed

- `scripts/setup.sh` installed the wrong Homebrew package for the
  nvim-treesitter dependency: the `tree-sitter` formula ships only the
  `libtree-sitter` library, so the CLI was still missing afterwards. It now
  installs the `tree-sitter-cli` formula.
- `nvim/lua/core/shell.lua`: `shell.cmd(program, { args, requires })` builds the
  command string for a terminal program. When the editor's own `PATH` cannot
  resolve it (`requires` names anything else it needs, such as `node` for a
  `#!/usr/bin/env node` shim), it defers to the user's login shell in
  interactive mode (`$SHELL -lic 'exec …'`), which loads `~/.zshrc`/`~/.profile`
  itself; Windows always gets the plain command, since the registry `PATH` is
  visible to GUI processes.
- `nvim/lua/plugins/toggleterm.lua`: `<leader>td` uses that helper for
  `dsh-tui --resume`. toggleterm runs commands through a non-interactive shell
  (`&shell -c`), which never reads `~/.zshrc` — the file where nvm and friends
  put themselves on `PATH` — so the mapping failed with `command not found`
  whenever the editor had not inherited them. The terminal also sets
  `close_on_exit = false` — the option the spec misspelled as `close_on_edit`,
  which toggleterm does not have — so a failing `dsh-tui` leaves its window and
  error text on screen instead of vanishing instantly (a clean exit still
  closes the window).

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
