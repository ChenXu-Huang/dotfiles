# Architecture

This document describes the structure and design of this dotfiles repository.

## Overview

This repository manages personal development-environment configuration as code.
The current scope is a [Neovim](https://neovim.io/) configuration plus
cross-platform setup scripts that link it into place.

## Repository Layout

```
.
├── nvim/                 Neovim configuration (linked to the Neovim config path)
│   ├── init.lua          Entry point: dynamic core-module loader
│   ├── lazy-lock.json    Plugin lockfile (git-ignored; machine-local)
│   └── lua/
│       ├── core/         Editor behavior, loaded eagerly in directory order
│       │   ├── basic.lua   Options (line numbers, indentation, search, UI...)
│       │   ├── keymap.lua  Global key mappings
│       │   └── lazy.lua    lazy.nvim bootstrap and plugin-spec import
│       └── plugins/      One lazy.nvim plugin spec per file (auto-imported)
├── scripts/              Setup scripts
│   ├── setup.ps1         Windows: junction %LOCALAPPDATA%\nvim -> nvim/
│   ├── setup.bat         Windows: directory symlink (cmd alternative)
│   └── setup             Unix placeholder (sh, not yet implemented)
├── docs/                 Project documentation
│   ├── ARCHITECTURE.md   This file
│   └── CHANGELOG.md      Release history (Keep a Changelog format)
├── .editorconfig         Editor style: LF, UTF-8, 4-space indentation
├── .gitignore            Ignores lazy-lock.json and temp/
└── AGENTS.md             Instructions for AI coding agents
```

## Neovim Configuration

### Startup Flow

1. `init.lua` scans `lua/core/` and `require()`s every `.lua` file it finds
   (except itself), wrapping each load in `pcall` so one failing module does
   not break startup; failures surface as a `vim.notify` error.
2. `core/basic.lua` applies editor options: hybrid line numbers, 4-space
   indentation, `ignorecase` + `smartcase` search, system-clipboard
   integration, persistent undo, rounded window borders, etc.
3. `core/keymap.lua` defines global key mappings.
4. `core/lazy.lua` bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim)
   (cloning the stable branch on first run) and imports every file in
   `lua/plugins/` as a plugin spec.

Because `lua/core/` is auto-loaded and `lua/plugins/` is auto-imported,
**adding a file to either directory is all that is needed to extend the
configuration** — no central registry must be edited.

### Plugin Set

| File | Plugin | Purpose |
| --- | --- | --- |
| `autopairs.lua` | windwp/nvim-autopairs | Automatic bracket/quote pairing |
| `blink.lua` | saghen/blink.cmp | Completion engine (with friendly-snippets) |
| `bufferline.lua` | akinsho/bufferline.nvim | Buffer tabs |
| `hop.lua` | smoka7/hop.nvim | Jump-to-anywhere motion |
| `lspsaga.lua` | nvimdev/lspsaga.nvim | LSP UI enhancements |
| `lualine.lua` | nvim-lualine/lualine.nvim | Statusline |
| `mason.lua` | mason-org/mason-lspconfig.nvim | LSP server wiring on nvim-lspconfig |
| `mason-tool-installer.lua` | WhoIsSethDaniel/mason-tool-installer.nvim | Ensures `pyright` and `ruff` are installed |
| `none-ls.lua` | nvimtools/none-ls.nvim | Non-LSP diagnostics/formatting sources |
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

The setup scripts make the in-repo `nvim/` directory visible at Neovim's
expected config location, so the configuration is edited in one place and
tracked in Git:

- **Windows (PowerShell)** — `scripts/setup.ps1` creates a *junction* from
  `%LOCALAPPDATA%\nvim` to the repo's `nvim/` folder. Junctions work without
  Administrator privileges, so this is the preferred script.
- **Windows (cmd)** — `scripts/setup.bat` does the same via `mklink /d`
  (requires Developer Mode or elevated privileges). It sets `chcp 65001` for
  UTF-8 console output.
- **Unix** — `scripts/setup` is an `sh` placeholder; a symlink-based
  implementation (targeting `~/.config/nvim`) is planned.

## Conventions

- **Editor style** (`.editorconfig`): LF line endings, UTF-8, final newline,
  4-space indentation.
- **Lockfile**: `nvim/lazy-lock.json` is git-ignored so each machine can float
  plugin versions independently.
- **Temporary files** belong in `temp/` at the repository root (git-ignored).
- **History** is recorded in [CHANGELOG.md](CHANGELOG.md) following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
