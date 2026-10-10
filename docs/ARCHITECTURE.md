# Architecture

This document describes the structure and design of this dotfiles repository.

## Overview

This repository manages personal development-environment configuration as code.
The current scope is a [Neovim](https://neovim.io/) configuration, a Windows
PowerShell 7 profile and the macOS zsh startup files, plus cross-platform setup
scripts that link them into place.

## Repository Layout

```
├── .config/                  Config home, mirrored from this repository
│   ├── powershell/           PowerShell 7 profile, linked into Documents\PowerShell
│   ├── zsh/                  zsh startup files (linked into $HOME on macOS)
│   │   ├── .zprofile           Homebrew environment, read by login shells
│   │   └── .zshrc              oh-my-zsh, nvm, rustup, aliases and functions
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
│           │   └── shell.lua   Login-shell environment import
│           └── plugins/      One lazy.nvim plugin spec per file (auto-imported)
├── .agents/                  Skill definitions for the agent CLIs
│   └── skills/               One directory per skill, linked into ~/.agents and ~/.claude
├── scripts/              Setup scripts
│   ├── setup.ps1         Windows: links .config/nvim, the pwsh profile and the skills
│   └── setup.sh          macOS/Linux: links .config/nvim, the skills and the zsh files
├── docs/                 Project documentation
│   ├── ARCHITECTURE.md   This file
│   └── CHANGELOG.md      Release history (Keep a Changelog format)
├── README.md             Entry point: requirements, installation, mappings
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
   integration, persistent undo, rounded window borders, etc. On Windows it
   sets `shell` to `pwsh` with the required
   `shellcmdflag`/`shellquote`/`shellxquote`/`shellredir`/`shellpipe`
   adjustments (UTF-8 output, no profile); other platforms keep the default
   shell.
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
`Could not find executable "npm" in PATH`. `core/shell.lua` covers this with
`sync_env()`, which imports the login environment once per session: it runs
`$SHELL -lic 'command env'`, puts the login `PATH` entries in front of the
current ones and fills in other variables only where they are unset. The
resolved `PATH` is cached in `stdpath("cache")/shell-path` (nothing else, so
no secrets land on disk) and counts as valid only while the cache file is
newer than the shell startup files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
and nvm's default-version alias; anything else is treated as a cache miss.
A valid cached `PATH` is applied instantly and refreshed in
the background; on a miss the fetch blocks startup only when
the `PATH` looks like the launchd default, and otherwise runs in the
background as well. A `PATH` that already contains the login entries is left
alone, while missing variables are filled in either way, and `sync_env()`
returns `synced`, `cached`, `async`, `failed` or `skipped`. A missing shell,
a timeout or empty output leaves the environment untouched; Windows is
skipped; the fetch child gets a neutral `PATH`, so previously imported
entries cannot feed back into the cache.

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
  diff, regex, comment.
- The `comment` parser (upstream `tree-sitter-comment`) is injected into the
  comments of every language whose `injections.scm` ships that rule, so tags
  such as `TODO`, `NOTE`, `FIXME`, `HACK`, `WARNING` and `XXX` are highlighted
  through the built-in `@comment.todo` / `@comment.note` / `@comment.warning` /
  `@comment.error` capture groups instead of a separate plugin or a
  `#match?`-based highlight query in this repository.
- A `FileType` autocommand enables Treesitter highlighting per buffer and
  switches folding to the Treesitter expression; `foldlevel` starts at 99 so
  files open unfolded.

## Setup Scripts

The setup scripts make the in-repo configuration visible where the tools read
it — Neovim's config path, PowerShell's per-user configuration directory (on
Windows), the skill directories of the agent CLIs and, on macOS, the zsh
startup files — so everything is edited in one place and tracked in Git:

- **Windows (PowerShell)** — `scripts/setup.ps1` walks one table of
  source/target pairs through a shared `New-ConfigLink` helper: a *junction*
  from `%LOCALAPPDATA%\nvim` to the repo's `.config/nvim/` folder, and *hard
  links* for the PowerShell 7 profile (`Microsoft.PowerShell_profile.ps1` and
  `powershell.config.json`) in `Documents\PowerShell`. Junctions and hard links
  need no Administrator privileges; where a hard link is impossible (the
  repository sits on another volume) the helper falls back to a symbolic link,
  which needs Developer Mode. The PowerShell directory is resolved with
  `[Environment]::GetFolderPath('MyDocuments')`, so a Documents folder
  redirected to OneDrive works as well; Windows PowerShell 5.1 reads
  `Documents\WindowsPowerShell` instead and is deliberately left alone. The
  skills are junctions into `%USERPROFILE%\.agents\skills` and
  `%USERPROFILE%\.claude\skills`. Missing external dependencies of the
  main-branch nvim-treesitter (`tree-sitter` CLI,
  `gcc`) are installed automatically with [Scoop](https://scoop.sh) when it is
  available; the script also warns when Neovim itself is missing or older than
  0.11.
- **macOS / Linux (POSIX sh)** — `scripts/setup.sh` calls the same kind of
  `link_config` helper once per pair: a *symbolic link* from
  `${XDG_CONFIG_HOME:-~/.config}/nvim` to the repo's `.config/nvim/` folder,
  one for each skills location (`~/.agents/skills`, `~/.claude/skills`),
  creating a missing target directory first, and — on macOS only — one for each
  zsh startup file (`.config/zsh/.zshrc` and `.zprofile`, linked into
  `${ZDOTDIR:-$HOME}`; see [Zsh Configuration](#zsh-configuration)). macOS is
  the primary target; it also installs the external dependencies of the
  main-branch
  nvim-treesitter with Homebrew (the `tree-sitter-cli` formula — `tree-sitter`
  itself ships only the library; the C compiler comes from the Xcode Command
  Line Tools) and warns when Neovim itself is missing or older than
  0.11. On Linux the same checks only print install hints.

Both scripts check the environment before linking and are safe to re-run:
when the target already points at this repository they skip, and every pair is
processed even when one of them conflicts, after which the run exits non-zero.
A foreign link, a real directory or a file at the target is reported and left
untouched; the Windows script additionally accepts a file whose content equals
the source (that is how a hard link is recognized, since it carries no reparse
point), and the POSIX script compares link texts, so a link that reaches the
repository only through another link counts as foreign. Passing `-f`/`--force`
(`-Force` on Windows) replaces the target instead — a foreign link is removed
(never its contents), a real file or directory is backed up to
`<target>.bak.<timestamp>` first. Because a hard link shares the file with the
repository, an editor or `git` operation that replaces the file instead of
rewriting it in place leaves the linked copy behind; re-run
`scripts/setup.ps1 -Force` to relink it.

## Agent Skills

`.agents/skills/` holds the skill definitions for the agent CLIs, one directory
per skill (`.agents/skills/<name>/SKILL.md`) as those tools expect them. Every
skill is authored in this repository and linked into both locations the CLIs
read, so one edit applies everywhere:

| Location | POSIX | Windows |
| --- | --- | --- |
| agent skills directory | `~/.agents/skills` | `%USERPROFILE%\.agents\skills` |
| Claude Code skills directory | `~/.claude/skills` | `%USERPROFILE%\.claude\skills` |

`scripts/setup.sh` creates symbolic links, `scripts/setup.ps1` junctions; both
create the parent directory when it does not exist yet. A pre-existing
`~/.claude/skills` that only points at `~/.agents/skills` is treated as foreign
and needs one `--force` run to become a direct link.

## PowerShell Profile

`.config/powershell/` holds the Windows PowerShell 7 configuration, which
`scripts/setup.ps1` links into `Documents\PowerShell`:

- `Microsoft.PowerShell_profile.ps1` switches the console to UTF-8, hooks
  `scoop-search`, loads posh-git, oh-my-posh (the built-in `stelbent.minimal`
  theme) and Terminal-Icons, configures PSReadLine (Emacs mode, predictions
  from history and plugins in list view) and PSFzf (`Ctrl+f`, `Ctrl+r`), adds
  the `vim`, `g`, `grep` and `which` shortcuts, and puts the `x64` bin
  directory of the newest installed Windows SDK on `PATH` — the version folders
  are sorted as versions, not as strings.
- `powershell.config.json` sets `Microsoft.PowerShell:ExecutionPolicy` to
  `RemoteSigned`. PowerShell only reads this key from the user-scope
  configuration directory (or from `$PSHOME` for all users), so linking the
  file next to the profile is what makes it apply; inside the repository alone
  it would have no effect.

## Zsh Configuration

`.config/zsh/` holds the macOS zsh startup files. zsh reads `.zshenv`,
`.zprofile`, `.zshrc` and `.zlogin` from `${ZDOTDIR:-$HOME}` and never looks in
`.config/`, so `scripts/setup.sh` links both files where zsh expects them:

| Source | Target |
| --- | --- |
| `.config/zsh/.zshrc` | `${ZDOTDIR:-$HOME}/.zshrc` |
| `.config/zsh/.zprofile` | `${ZDOTDIR:-$HOME}/.zprofile` |

An existing real file at the target is reported and left alone without
`--force`, which backs it up to `<target>.bak.<timestamp>` first; afterwards
every append to `~/.zshrc` writes into the repository.

The split follows when zsh sources each file:

- `.zprofile` is read by *login* shells only, which is where Homebrew's
  `brew shellenv` belongs: it exports `HOMEBREW_PREFIX`, fixes `MANPATH` and
  `INFOPATH`, adds Homebrew's `site-functions` to `fpath`, and puts
  `/opt/homebrew/bin` and `/opt/homebrew/sbin` in front of the rest of `PATH`.
- `.zshrc` is read by every *interactive* shell. It starts oh-my-zsh
  (`ZSH_THEME="robbyrussell"`, `plugins=(git)`), sets `LANG`/`LC_ALL` and
  `EDITOR`/`BUNDLER_EDITOR`, loads nvm and its bash-completion file (which
  detects zsh and routes through `bashcompinit`), prepends the rustup and
  `~/.cargo/bin` directories to `PATH`, and defines the `vim` and `buu` aliases
  plus the `y` yazi wrapper that changes directory when yazi quits.
- A non-login interactive shell (a nested `zsh -i`, some IDE terminals) never
  reads `.zprofile`, so `.zshrc` does not depend on it:
  `_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"` feeds the nvm and rustup
  lines, and `unset _brew_prefix` follows the last line that uses it, so the
  helper does not stay in the session. The lower-case name marks it as a
  shell-local variable rather than an environment variable. Every load is
  guarded by `[ -s … ]`, so an empty prefix would otherwise skip nvm and rustup
  without a word. The literal `/opt/homebrew` fallback is deliberate: the
  repository targets one Apple-silicon machine, so no probe for Intel or
  Linuxbrew prefixes is included.

`core/shell.lua` fetches the environment with `$SHELL -lic`, so a Neovim started
from Finder/Dock sees what an interactive login shell produces, nvm's `node`
included.

## Conventions

- **Editor style** (`.editorconfig`): LF line endings, UTF-8, final newline,
  4-space indentation. `.gitattributes` enforces LF on checkout so
  `scripts/setup.sh` also works from a Windows clone.
- **Lockfile**: `.config/nvim/lazy-lock.json` is git-ignored so each machine
  can float plugin versions independently.
- **Temporary files** belong in `temp/` at the repository root (git-ignored).
- **History** is recorded in [CHANGELOG.md](CHANGELOG.md) following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
