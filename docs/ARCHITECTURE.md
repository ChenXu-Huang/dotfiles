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
│       ├── init.lua          Entry point: plugin table, core modules, plugin loader
│       ├── lsp/              LSP wiring, one module per concern
│       │   ├── init.lua        Requires the modules below
│       │   ├── lsp.lua         `Vellum.lsp`: per-server settings
│       │   ├── plugins.lua     mason, mason-lspconfig and server enablement
│       │   ├── completion.lua  blink.cmp section
│       │   ├── format.lua      none-ls section
│       │   └── extra.lua       lspsaga and trouble sections
│       ├── nvim-pack-lock.json  Plugin lockfile written by vim.pack (tracked)
│       └── lua/
│           ├── core/         Editor behavior, loaded eagerly in list order
│           │   ├── basic.lua        Options (indentation, search, shell...)
│           │   ├── commands.lua     `:Vellum*` user commands
│           │   ├── ft.lua           FileType specific options
│           │   ├── health.lua       `:checkhealth core`
│           │   ├── keymap.lua       Global key mappings
│           │   ├── miscellaneous.lua  Auto-chdir and small editor behaviors
│           │   ├── shell.lua        Login-shell environment import
│           │   ├── symbols.lua      Icon table
│           │   ├── terminal.lua     Built-in terminal and `:VellumTerm`
│           │   ├── utils.lua        Platform checks, mapping and float helpers
│           │   └── vscode.lua       VS Code specifics, loaded only under vscode-neovim
│           └── plugins/
│               ├── config.lua     Central plugin table (single source for plugins)
│               ├── pack.lua       vim.pack specs, lazy loading and the VeryLazy event
│               ├── colorscheme.lua  Colorscheme list and switching
│               ├── init.lua       Requires the table, colorschemes and `lsp/`
│               ├── profile.lua    `:VellumProfile` state panel and `:VellumUpdate`
│               └── utils.lua      Colorscheme and plugin helpers
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
├── .gitignore            Ignores temp/ and OS metadata files
└── AGENTS.md             Instructions for AI coding agents
```

## Neovim Configuration

### Startup Flow

1. `init.lua` creates the global `Vellum` table and requires `core.init` and
   `plugins.init`. Under vscode-neovim it then also requires `core.vscode`,
   registers `Vellum.keymap` and installs the `Vellum.ft` filetype options.
2. `core/init.lua` loads the modules in a fixed order: `core/shell.lua`'s
   `sync_env()` first (so tools are resolvable before any plugin runs), then
   `core/basic.lua`, `core/commands.lua`, `core/terminal.lua`, `core/ft.lua`,
   `core/keymap.lua`, `core/miscellaneous.lua` and `core/symbols.lua`. The
   shell import is skipped when Neovim runs inside VS Code, where the editor
   already provides the environment.
3. `core/basic.lua` applies the editor options: 4-space indentation,
   `ignorecase` + `smartcase` search, system-clipboard integration, persistent
   undo, `foldlevel = 99`, and — on Windows — `shell` set to `pwsh` with the
   required `shellcmdflag`/`shellquote`/`shellxquote`/`shellredir`/`shellpipe`
   adjustments (UTF-8 output, no profile). The options that only make sense for
   the standalone editor (line numbers, `cursorline`, `colorcolumn`,
   `signcolumn`, `winborder`, `termguicolors`, and the `wrap`/`showmode`
   defaults) are set in a `if not vim.g.vscode then` block, because
   vscode-neovim forces or synchronizes them itself.
4. `core/keymap.lua` defines global key mappings (including the terminal keys),
   `core/ft.lua` the `FileType`-scoped ones (soft wrapping at word boundaries
   for Markdown and plain text), `core/commands.lua` the `:Vellum*` commands,
   and `core/terminal.lua` the built-in terminal.
5. `plugins/config.lua` fills `Vellum.plugins` with one section per plugin,
   `plugins/init.lua` requires it together with `plugins/colorscheme.lua` and
   `lua/lsp/` (which adds the LSP sections), and `plugins/pack.lua` turns the
   table into `vim.pack` package specs and installs/loads them.

Because every plugin lives in the central table, **adding a plugin is adding one
section to `plugins/config.lua`**; a new core module is picked up by adding
its `require` to `core/init.lua`.

### Plugin Management

Plugins are installed and updated by `vim.pack` (Neovim 0.12+): sources land in
`stdpath("data")/site/pack/core/opt`, the lockfile is
`nvim-pack-lock.json` next to `init.lua` and is tracked in Git, updates run
through `:VellumUpdate` (or `vim.pack.update()`), and `:VellumProfile` lists
every section with its state.

`plugins/config.lua` is the single source of truth: keyed by a logical name
that is also the name used by dependencies and by `:VellumProfile`, each
section starts with the GitHub repository and supports:

| Field | Meaning |
| --- | --- |
| `enabled` | boolean or function; a disabled section is neither installed nor loaded and shows as `disabled` in `:VellumProfile` |
| `version` | branch, tag or commit; a constraint such as `"1.*"` selects the newest matching semver tag |
| `main` | module passed to `setup()`; guessed from the repository name when omitted |
| `opts` / `config` | options for `setup()`, or a `function(opts)` that replaces the automatic `setup()` call |
| `dependencies` | logical names or inline sections, loaded before this plugin and skipped with it |
| `init` | function run right before the plugin is loaded |
| `build` | shell command, `:command` or function run after install and update (`PackChanged`) |
| `lazy`, `event`, `ft`, `cmd`, `keys` | lazy-loading triggers |
| `priority` | lower values load earlier (default 100) |

`plugins/pack.lua` registers every trigger *before* `vim.pack.add()` runs, so a
plugin that loads during startup still finds its events in place. Lazy keymaps
are placeholders that load and set up the plugin when first pressed, then run the
binding's action (a function, an Ex command or a `<Cmd>` mapping) directly;
`desc` is preserved for `:map` and keymap pickers. Next to the Neovim events,
`VeryLazy` is available (after `VimEnter`).

A section without `opts`, `main` and `config` is only loaded, never set up: that
is what plugins such as nvim-lspconfig expect, since they configure themselves
through their own `plugin/` scripts.

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
entries cannot feed back into the cache. `core/init.lua` calls `sync_env()`
only when Neovim runs standalone: inside vscode-neovim the editor already
provides the environment, and a blocking fetch would only delay the extension.

### LSP Server Configs

- Per-server settings live in `.config/nvim/lua/lsp/lsp.lua` as the
  `Vellum.lsp` table, keyed by the lspconfig server name; the `formatter`,
  `setup` and `managed_by_plugin` fields are what the rest of the LSP wiring
  reads.
- `lua/lsp/plugins.lua` adds the mason, mason-lspconfig and editor-plugin
  sections to `Vellum.plugins`, enables the installed servers and holds the
  global diagnostic appearance (`vim.diagnostic.config`). The `blink` section
  registers blink.cmp's LSP capabilities through `vim.lsp.config("*")` when it
  is set up, so servers started later advertise them. `lua/lsp/format.lua`
  builds the none-ls sources from each server's `formatter` field, so
  `<leader>lf` formats through that one source.
- mason-lspconfig auto-enables every server installed by Mason; the packages
  themselves are kept installed through the `mason-tool-installer` section of
  the central plugin table.

### Plugin Set

| Section | Plugin | Purpose |
| --- | --- | --- |
| `autopairs` | windwp/nvim-autopairs | Automatic bracket/quote pairing |
| `blink` | saghen/blink.cmp | Completion engine (with friendly-snippets) |
| `gitsigns` | lewis6991/gitsigns.nvim | Git hunk signs in the signcolumn with `<leader>gn`/`<leader>gp` navigation and `<leader>gs`/`<leader>gr` staging |
| `grug-far` | MagicDuck/grug-far.nvim | Project-wide search and replace |
| `hop` | smoka7/hop.nvim | Jump-to-anywhere motion |
| `indent-blankline` | lukas-reineke/indent-blankline.nvim | Indentation guides |
| `lspsaga` | nvimdev/lspsaga.nvim | LSP UI enhancements |
| `lualine` | nvim-lualine/lualine.nvim | Statusline |
| `mason` / `mason-lspconfig` | mason-org/mason.nvim, mason-lspconfig.nvim | LSP server wiring on nvim-lspconfig |
| `mason-tool-installer` | WhoIsSethDaniel/mason-tool-installer.nvim | Ensures `pyright`, `ruff`, `stylua` and `lua-language-server` (`lua_ls`) are installed |
| `none-ls` (+ `none-ls-extras`) | nvimtools/none-ls.nvim | Dedicated formatting sources: ruff (Python) and stylua (Lua); `<leader>lf` formats through it |
| `surround` | kylechui/nvim-surround | Surrounding-pair editing |
| `telescope` | nvim-telescope/telescope.nvim | Fuzzy finder; its `buffers` picker replaced bufferline (selection, preview and `<M-d>` deletion), plus `find_files` and `live_grep` |
| `tokyonight` | folke/tokyonight.nvim | Colorscheme |
| `tree` | nvim-tree/nvim-tree.lua | File explorer |

bufferline was dropped because it stopped receiving releases in January 2025;
telescope covers the same job and is actively maintained. `<leader>bi` opens the
`buffers` picker (selection, preview and `<M-d>` deletion), `<leader>bh`/
`<leader>bl` cycle buffers, `<leader>bd` deletes the current buffer and
`<leader>bo` closes the others.

The terminal is not a plugin: `core/terminal.lua` builds it on Neovim's built-in
terminal (see [Terminal](#terminal)), which is also why `toggleterm.nvim` no
longer appears in the table.

### Terminal

`core/terminal.lua` implements the toggleable terminal on Neovim's built-in
terminal (`jobstart(..., { term = true })`) instead of a plugin. Every terminal
id owns a buffer, a window and its per-direction size; `toggle(id, direction)`
opens a float (rounded border), a vertical split (35% of the columns by
default) or a horizontal split (15 lines), and closing a terminal only hides
its window, so the running job survives. Closing records the window size and
whether the buffer was in normal mode, and the next open restores both.

When the job exits, the window is closed and the buffer deleted unless the
terminal installed an `on_exit` handler: `dsh-tui` uses that to report a
non-zero exit code, keeps `<Esc>` for the TUI (elsewhere `<Esc>` is the global
"leave terminal mode" mapping) and disposes only on a clean exit.
`<leader>st`/`sv`/`sh` read `v:count1` as the terminal id, `<M-s>` toggles the
terminal under the cursor, `<C-t>` still opens a plain split terminal, and
`:VellumTerm` exposes the same API with `id`, `direction=` and `size=`
arguments.

### Treesitter

Treesitter support comes from Neovim itself (0.12+): the bundled parsers and
queries cover C, Lua, Markdown, Vimscript, Vimdoc and query files, and Neovim
starts the highlighter for any buffer whose language has a parser, so no
plugin, `FileType` autocommand or folding setup is involved. Parsers for other
languages live in `parser/` directories on the runtimepath — the ones already
installed under `stdpath("data")/site` keep working after the treesitter plugin
was dropped — and are loaded only when a buffer needs them.

### vscode-neovim

The same configuration runs unchanged inside the vscode-neovim extension, which
starts Neovim with its own prelude that sets `vim.g.vscode = 1` before the user
`init.lua` is read. The extension passes no `-u`, no `--clean` and no
`NVIM_APPNAME`, so it reads the very same `stdpath("config")`; the only
requirement is to leave `vscode-neovim.neovimClean`, `vscode-neovim.NVIM_APPNAME`
and `vscode-neovim.neovimInitVimPaths.*` at their defaults. Neovim 0.12 or
newer is required here as well, since the configuration is built on `vim.pack`.

What changes under `vim.g.vscode`:

- Sections without `vscode = true` stay disabled: the whole LSP and
  completion stack (mason, mason-lspconfig, mason-tool-installer, none-ls,
  blink, lspsaga), nvim-lspconfig and every rendering plugin that VS Code
  already provides (lualine, indent-blankline, nvim-tree, gitsigns,
  telescope). VS Code serves the language features and the UI, so nothing is
  lost.
- `core/basic.lua` leaves out the options the extension forces or synchronizes
  (`wrap`, `cursorline`, `colorcolumn`, `signcolumn`, `winborder`,
  `termguicolors`, `number`/`relativenumber`), and `core/shell.lua` is not
  called at all.
- `core/vscode.lua` routes the clipboard through `vim.g.vscode_clipboard` and
  rebinds the `<leader>l*` and `<leader>uf` mappings to the equivalent VS Code
  commands, so the keys that the disabled plugins would have owned keep working.

Nothing in the repository has to differ for VS Code: the behaviour is derived
from `vim.g.vscode` alone.

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
  `%USERPROFILE%\.claude\skills`; the script also warns when Neovim itself is
  missing or older than 0.12.
- **macOS / Linux (POSIX sh)** — `scripts/setup.sh` calls the same kind of
  `link_config` helper once per pair: a *symbolic link* from
  `${XDG_CONFIG_HOME:-~/.config}/nvim` to the repo's `.config/nvim/` folder,
  one for each skills location (`~/.agents/skills`, `~/.claude/skills`),
  creating a missing target directory first, and — on macOS only — one for each
  zsh startup file (`.config/zsh/.zshrc` and `.zprofile`, linked into
  `${ZDOTDIR:-$HOME}`; see [Zsh Configuration](#zsh-configuration)). macOS is
  the primary target; it warns when Neovim itself is missing or older than
  0.12. On Linux the same checks only print install hints.

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

### `code-style`

Per-language code style rules for Python, Lua, PowerShell, and Bash: one
self-contained file per language, with `assets/language-template.md` as the
starting point for adding another.

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
- **Lockfile**: `.config/nvim/nvim-pack-lock.json` is tracked, so every machine
  installs the same plugin revisions; `vim.pack.update()` moves it forward.
- **Temporary files** belong in `temp/` at the repository root (git-ignored).
- **History** is recorded in [CHANGELOG.md](CHANGELOG.md) following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
