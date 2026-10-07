# Architecture

This document describes the structure and design of this dotfiles repository.

## Overview

This repository manages personal development-environment configuration as code.
The current scope is a [Neovim](https://neovim.io/) configuration plus
cross-platform setup scripts that link it into place.

## Repository Layout

```
.
├── .config/                  Neovim's config home, mirrored from this repository
│   └── nvim/                 Neovim configuration (linked to the Neovim config path)
│       ├── init.lua          Entry point: dynamic core-module loader
│       ├── lsp/              One config per LSP server (auto-discovered by vim.lsp)
│       │   ├── pyright.lua     Python language server settings
│       │   └── lua_ls.lua      Lua language server settings (`vim` global)
│       ├── lazy-lock.json    Plugin lockfile (git-ignored; machine-local)
│       └── lua/
│           ├── core/         Editor behavior, loaded eagerly in list order
│           │   ├── basic.lua   Options (line numbers, indentation, search, UI...)
│           │   ├── keymap.lua  Global key mappings
│           │   ├── lazy.lua    lazy.nvim bootstrap and plugin-spec import
│           │   └── shell.lua   Login-shell commands and environment import
│           └── plugins/      One lazy.nvim plugin spec per file (auto-imported)
├── scripts/              Setup scripts
│   ├── setup.ps1         Windows: junction %LOCALAPPDATA%\nvim -> .config/nvim
│   └── setup.sh          macOS/Linux: symlink ~/.config/nvim -> .config/nvim
├── docs/                 Project documentation
│   ├── ARCHITECTURE.md   This file
│   └── CHANGELOG.md      Release history (Keep a Changelog format)
├── .editorconfig         Editor style: LF, UTF-8, 4-space indentation
├── .gitattributes        Enforces LF checkout so POSIX scripts work everywhere
├── .gitignore            Ignores lazy-lock.json, temp/ and OS metadata files
└── AGENTS.md             Instructions for AI coding agents
```

## Neovim Configuration

### Startup Flow

1. `init.lua` requires `core`, and `core/init.lua` loads the modules in a fixed
   order: `core/shell.lua`'s `sync_env()` first (so tools are resolvable before
   any plugin runs), then `core/basic.lua`, `core/keymap.lua` and
   `core/lazy.lua`.
2. `core/basic.lua` applies editor options: hybrid line numbers, 4-space
   indentation, `ignorecase` + `smartcase` search, system-clipboard
   integration, persistent undo, rounded window borders, etc. It also
   prefers `pwsh` as the shell on every OS when the executable is available,
   applying the required `shellcmdflag`/`shellquote`/`shellxquote`
   adjustments on Windows only.
3. `core/keymap.lua` defines global key mappings.
4. `core/lazy.lua` bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim)
   (cloning the stable branch on first run) and imports every file in
   `lua/plugins/` as a plugin spec.

Because `lua/plugins/` is auto-imported and `lua/core/` is one module per
concern, **adding a plugin spec file is all that is needed to extend the plugin
set**; a new core module is picked up by adding its `require` to
`core/init.lua`.

### Shell Environment

Neovide opened from Finder/Dock (or any launcher that does not read `.zshrc`)
inherits the launchd `PATH`, so nvm's `node`/`npm`, Homebrew tools and
variables such as `NVM_DIR` are missing — Mason then fails with
`Could not find executable "npm" in PATH`. `core/shell.lua` covers this in two
layers:

- `shell.cmd(program, { requires = … })` builds a command that the user's login
  shell resolves at execution time (used by toggleterm).
- `sync_env()` imports the login environment once per session: it runs
  `$SHELL -lic 'command env'`, puts the login `PATH` entries in front of the
  current ones and fills in other variables only where they are unset. The
  resolved `PATH` is cached in `stdpath("cache")/shell-path` (nothing else, so no
  secrets land on disk). A cached `PATH` is applied instantly and refreshed in
  the background; without a cache the fetch blocks startup only when the `PATH`
  looks like the launchd default, and otherwise runs in the background as well.
  A `PATH` that already contains the login entries is left alone, while missing
  variables are filled in either way, and `sync_env()` reports `synced`,
  `cached`, `async`, `failed` or `skipped` (also kept in `require("core.shell").status`).
  A missing shell, a timeout or empty output leaves the environment untouched;
  Windows is skipped; the fetch child gets a neutral `PATH`, so previously
  imported entries cannot feed back into the cache.

### LSP Server Configs

- Per-server settings live in `.config/nvim/lsp/<server>.lua` (one file per
  server, named after the lspconfig server name, returning a `vim.lsp.config`
  table).
  Neovim 0.11+ auto-discovers these files from the runtimepath and merges
  them into `vim.lsp.config()`, so no loader or registry is involved.
- `plugins/mason.lua` only defines the shared `vim.lsp.config("*", ...)`
  defaults (blink.cmp capabilities, formatting delegated to none-ls) and the
  global diagnostic appearance. Language servers keep their formatting
  capability disabled on purpose, so `<leader>lf` never mixes two formatters.
- mason-lspconfig auto-enables every server installed by Mason; the packages
  themselves are kept installed via `plugins/mason-tool-installer.lua`.

### Plugin Set

| File | Plugin | Purpose |
| --- | --- | --- |
| `autopairs.lua` | windwp/nvim-autopairs | Automatic bracket/quote pairing |
| `blink.lua` | saghen/blink.cmp | Completion engine (with friendly-snippets) |
| `bufferline.lua` | akinsho/bufferline.nvim | Buffer tabs |
| `gitsigns.lua` | lewis6991/gitsigns.nvim | Git hunk signs in the signcolumn with `]h`/`[h` and `<leader>uh` mappings |
| `hop.lua` | smoka7/hop.nvim | Jump-to-anywhere motion |
| `lspsaga.lua` | nvimdev/lspsaga.nvim | LSP UI enhancements |
| `lualine.lua` | nvim-lualine/lualine.nvim | Statusline |
| `mason.lua` | mason-org/mason-lspconfig.nvim | LSP server wiring on nvim-lspconfig |
| `mason-tool-installer.lua` | WhoIsSethDaniel/mason-tool-installer.nvim | Ensures `pyright`, `ruff`, `stylua` and `lua-language-server` (`lua_ls`) are installed |
| `none-ls.lua` | nvimtools/none-ls.nvim | Dedicated formatting/diagnostics sources: ruff (Python) and stylua (Lua); `<leader>lf` formats through it |
| `surround.lua` | kylechui/nvim-surround | Surrounding-pair editing |
| `toggleterm.lua` | akinsho/toggleterm.nvim | Toggleable terminal |
| `tokyonight.lua` | folke/tokyonight.nvim | Colorscheme |
| `tree.lua` | nvim-tree/nvim-tree.lua | File explorer |
| `treesitter.lua` | nvim-treesitter/nvim-treesitter | Syntax highlighting and folding |

### Treesitter Notes

- `vim.env.CC = "gcc"` forces the parser compiler (important on Windows where
  MSVC may be the default).
- Parsers are installed for: lua, vim, vimdoc, query, python, requirements,
  powershell, bash, markdown(+inline), json, yaml, toml, gitcommit, gitignore,
  diff, regex.
- A `FileType` autocommand enables Treesitter highlighting per buffer and
  switches folding to the Treesitter expression; `foldlevel` starts at 99 so
  files open unfolded.

## Setup Scripts

The setup scripts make the in-repo `.config/nvim/` directory visible at
Neovim's expected config location, so the configuration is edited in one place
and tracked in Git:

- **Windows (PowerShell)** — `scripts/setup.ps1` creates a *junction* from
  `%LOCALAPPDATA%\nvim` to the repo's `.config/nvim/` folder. Junctions work
  without Administrator privileges. Missing external dependencies of the
  main-branch nvim-treesitter (`tree-sitter` CLI, `gcc`) are installed
  automatically with [Scoop](https://scoop.sh) when it is available; the script
  also warns when Neovim itself is missing or older than 0.11.
- **macOS / Linux (POSIX sh)** — `scripts/setup.sh` creates a *symbolic link*
  from `${XDG_CONFIG_HOME:-~/.config}/nvim` to the repo's `.config/nvim/`
  folder, creating the config home first if needed. macOS is the primary
  target; it also installs the external dependencies of the main-branch
  nvim-treesitter with Homebrew (the `tree-sitter-cli` formula — `tree-sitter`
  itself ships only the library; the C compiler comes from the Xcode Command
  Line Tools) and warns when Neovim itself is missing or older than
  0.11. On Linux the same checks only print install hints.

Both scripts check the environment before linking and are safe to re-run:
when the target already points at this repository they skip; when a foreign
link, real directory, or file occupies the target they warn and exit. Passing
`-f`/`--force` (`-Force` on Windows) replaces the target instead — a foreign
link is removed (never its contents), a real file or directory is backed up
to `nvim.bak.<timestamp>` first.

## Conventions

- **Editor style** (`.editorconfig`): LF line endings, UTF-8, final newline,
  4-space indentation. `.gitattributes` enforces LF on checkout so
  `scripts/setup.sh` also works from a Windows clone.
- **Lockfile**: `.config/nvim/lazy-lock.json` is git-ignored so each machine
  can float plugin versions independently.
- **Temporary files** belong in `temp/` at the repository root (git-ignored).
- **History** is recorded in [CHANGELOG.md](CHANGELOG.md) following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
