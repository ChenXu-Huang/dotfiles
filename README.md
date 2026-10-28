# dotfiles

Personal development-environment configuration as code: a
[Neovim](https://neovim.io/) configuration, the VS Code user settings, a pandoc
user data directory, a Windows PowerShell 7 profile and the skill definitions
for the agent CLIs, plus cross-platform setup scripts that link them into
place, so everything is edited in one repository and tracked in Git.

## Requirements

- **Neovim 0.12 or newer** — the configuration is built on `vim.pack`, relies on
  `vim.lsp.config` auto-discovery and uses the `main` branch of nvim-treesitter;
  the setup scripts warn when the version is older.
- **Git** — `vim.pack` clones plugins into `stdpath("data")` on first start.
- **Build tools** — a C compiler and `cmake` (telescope-fzf-native), `cargo`
  (blink.cmp's fuzzy matcher), `node` and `npm` (markdown-preview and most mason
  packages), the `tree-sitter` CLI (parser compilation; on Windows that means
  MSVC's `cl.exe` in `PATH`), `python3` and `gzip` or `7z` (mason packages).
  `rg` and `fd` keep telescope's grep and file pickers fast; `tokei` enables
  `:VellumTokei`, and `dsh-tui` backs the `<leader>sd` session.
  `:checkhealth core` reports what is missing.
- Optional: a Nerd Font (`JetBrainsMono Nerd Font Mono` is the configured GUI
  font), [Neovide](https://neovide.dev), and `pwsh` — on Windows Neovim uses
  it as `shell`.
- Optional: **VS Code** with the
  [vscode-neovim](https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim)
  extension — the same configuration detects it and trims itself down, see
  [VS Code (vscode-neovim)](#vs-code-vscode-neovim).
- Optional: **PowerShell 7** on Windows — `scripts/setup.ps1` links the
  profile in `.config/powershell/` into the per-user configuration directory
  that `pwsh` reads.
- Optional: an agent CLI that reads skills from `~/.agents/skills` or
  `~/.claude/skills` — the setup scripts link `.agents/skills` into both.

## Installation

The setup scripts link `.config/nvim` to Neovim's config location,
`.config/vscode` to VS Code's user directory, `.config/pandoc` to pandoc's user
data directory, the zsh startup files to `~/.zshrc` and `~/.zprofile` (macOS)
and, on Windows, the PowerShell 7 profile to the directory `pwsh` reads it
from, checking the environment first. They are safe to re-run.

```sh
git clone https://github.com/ChenXu-Huang/dotfiles.git
cd dotfiles
./scripts/setup.sh
```

```powershell
git clone https://github.com/ChenXu-Huang/dotfiles.git
cd dotfiles
.\scripts\setup.ps1
```

Each script links the repository's sources into that platform's locations:

| Platform | Link created |
| --- | --- |
| macOS / Linux | `${XDG_CONFIG_HOME:-~/.config}/nvim`, a symbolic link |
| macOS / Linux | VS Code's `Code/User` (under `~/Library/Application Support` on macOS, `${XDG_CONFIG_HOME:-~/.config}` on Linux): `settings.json` and `keybindings.json` |
| macOS / Linux | `${XDG_DATA_HOME:-~/.local/share}/pandoc`, a symbolic link |
| macOS | `${ZDOTDIR:-~}/.zshrc` and `${ZDOTDIR:-~}/.zprofile`, symbolic links |
| macOS / Linux | `~/.agents/skills` and `~/.claude/skills`, symbolic links |
| Windows | `%LOCALAPPDATA%\nvim`, a junction (no Administrator rights) |
| Windows | `%APPDATA%\Code\User`: VS Code `settings.json` and `keybindings.json` |
| Windows | `%APPDATA%\pandoc`, a junction |
| Windows | `Documents\PowerShell`: profile and `powershell.config.json` |
| Windows | `%USERPROFILE%\.agents\skills` and `.claude\skills`, junctions |

Both scripts also:

- warn when Neovim is missing or older than 0.12;
- link `.agents/skills` into both the agent and the Claude Code skills
  directories, creating a missing target directory;
- leave an existing target alone: they skip when it already points at this
  repository, and report an error instead of touching anything else;
- on Windows, resolve `Documents\PowerShell` through
  `[Environment]::GetFolderPath('MyDocuments')`, so a Documents folder
  redirected to OneDrive works (Windows PowerShell 5.1 reads
  `Documents\WindowsPowerShell` and is left alone).

`-f`/`--force` (`-Force` on Windows) replaces the target instead: a foreign
link is removed and a real file or directory is backed up to
`<target>.bak.<timestamp>` first. `-h`/`--help` prints the usage. The first
Neovim start installs the plugins with `vim.pack`, which needs network access.

### Shell Configuration

`scripts/setup.sh` links the two zsh startup files on macOS — zsh reads
`.zshenv`, `.zprofile`, `.zshrc` and `.zlogin` from `${ZDOTDIR:-$HOME}` and
never looks in `.config/`:

| Source | Target |
| --- | --- |
| `.config/zsh/.zshrc` | `${ZDOTDIR:-$HOME}/.zshrc` |
| `.config/zsh/.zprofile` | `${ZDOTDIR:-$HOME}/.zprofile` |

An existing real file at the target is reported and left alone; `--force` backs
it up to `<target>.bak.<timestamp>` first. Afterwards anything that appends to
`~/.zshrc` writes into the repository file.

`.zprofile` (login shells) puts Homebrew on `PATH` and defines
`HOMEBREW_PREFIX`; `.zshrc` (every interactive shell) loads oh-my-zsh, nvm,
rustup and the aliases, falling back to `/opt/homebrew` when it was started
without reading `.zprofile`.

### Uninstall

```sh
rm ~/.config/nvim ~/.agents/skills ~/.claude/skills
rm ~/.zshrc ~/.zprofile
rm "${XDG_DATA_HOME:-$HOME/.local/share}/pandoc"
# VS Code user settings, linked as files:
#   macOS: ~/Library/Application Support/Code/User/{settings.json,keybindings.json}
#   Linux: ${XDG_CONFIG_HOME:-~/.config}/Code/User/{settings.json,keybindings.json}
```

```powershell
Remove-Item "$env:LOCALAPPDATA\nvim" -Force
Remove-Item "$env:APPDATA\pandoc" -Force
Remove-Item "$env:APPDATA\Code\User\settings.json" -Force
Remove-Item "$env:APPDATA\Code\User\keybindings.json" -Force
Remove-Item "$env:USERPROFILE\.agents\skills" -Force
Remove-Item "$env:USERPROFILE\.claude\skills" -Force
$docs = [Environment]::GetFolderPath('MyDocuments')
Remove-Item "$docs\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
Remove-Item "$docs\PowerShell\powershell.config.json" -Force
```

They remove the links, junctions and hard links only — the repository keeps
its files, and `Documents\PowerShell` itself stays in place.
Plugins and the shell-path cache live outside it, in `stdpath("data")` and
`stdpath("cache")`, so remove those directories as well for a clean slate.

## Repository Layout

```
.agents/skills/       Skill definitions, linked into ~/.agents and ~/.claude
.config/nvim/         Neovim configuration, linked in by the setup scripts
.config/pandoc/       pandoc user data directory (templates and defaults)
.config/powershell/   PowerShell 7 profile, linked into Documents\PowerShell
.config/vscode/       VS Code settings.json and keybindings.json
.config/zsh/          zsh startup files, linked into $HOME on macOS
scripts/              setup.sh (macOS/Linux) and setup.ps1 (Windows)
docs/                 ARCHITECTURE.md and CHANGELOG.md
```

Inside `.config/nvim/`:

- `init.lua` creates the global `Vellum` table, loads `lua/core/` — which
  imports the login-shell environment first and then the editor options, the
  commands, the terminal, the filetype behavior and the mappings — and finally
  loads `lua/plugins/`, which builds the central plugin table and pulls in
  `lua/lsp/`.
- `lua/plugins/config.lua` is the single source of truth for plugins: one
  section per plugin holds its repository, options and keymaps, and
  `lua/plugins/pack.lua` turns that table into `vim.pack` specs with lazy
  loading (see [Plugin management](#plugin-management)).
- `lua/lsp/` holds the LSP wiring: the per-server settings table, the mason and
  mason-lspconfig sections, completion, formatting and the extra sections.
- `lua/core/vscode.lua` is loaded only when Neovim runs inside vscode-neovim.

The plugin set covers LSP and tooling (mason, mason-lspconfig, nvim-lspconfig,
none-ls, lspsaga, trouble, fidget), completion (blink.cmp with blink.lib,
LuaSnip and friendly-snippets), navigation (nvim-tree, telescope with
fzf-native, hop),
editing (autopairs, surround, indent-blankline, grug-far, better-escape),
folding (nvim-ufo), git (gitsigns, neogit) and appearance (lualine, dashboard,
which-key, scrollview, colorful-winsep, transparent, colorizer, todo-comments,
markdown-preview). Eight colorschemes ship with it — tokyonight, kanagawa,
nightfox, gruvbox, everforest, cyberdream, monet and vague — and `<C-k><C-t>`
opens a picker that previews them live; the choice is remembered across
sessions.

Syntax highlighting comes from the `main` branch of nvim-treesitter: the
parsers in `ensure_installed` (BibTeX, C, C#, C++, CSS, Dockerfile, fish, Go,
HTML, INI, JavaScript/TypeScript, JSON, LaTeX, Lua, Markdown, Python, query,
Rust, TOML, Typst, TSX, Vim, Vimdoc and YAML) are installed on first start, the
highlighter and its `indentexpr` attach per filetype, and rainbow-delimiters
colors the bracket pairs. Language-specific plugins — flutter-tools,
rustaceanvim and typst-preview — switch on with the `enabled` flag of the
matching `Vellum.lsp` entry. The terminal is Neovim's built-in one
(`lua/core/terminal.lua`).

The enabled LSP servers are lua-language-server, pyright and texlab, with
StyLua, ruff and tex-fmt as their formatters — mason installs all six on first
start. The other entries in `lua/lsp/lsp.lua` (clangd, gopls, the HTML/CSS/JSON
and TypeScript servers, tinymist and more) stay off until their section gets
`enabled = true`.

Buffer switching is telescope's `buffers` picker: `bufferline.nvim` has had no
release since January 2025, so `<leader>bi` opens that picker, which selects a
buffer with `<CR>`, opens it in a split with `<M-s>`/`<M-v>`, and deletes the
selected one with `<M-d>`.

### Plugin management

Plugins are managed by `vim.pack`: they are installed on first start, live in
`stdpath("data")/site/pack/core/opt`, and `nvim-pack-lock.json` next to
`init.lua` pins the revisions. The lockfile is git-ignored (`*-lock.json`), so
every machine pins its own; copy it over by hand to reproduce an exact plugin
set elsewhere.

| Command | Action |
| --- | --- |
| `:VellumProfile` | List every plugin with its state (`loaded`, `not loaded`, `disabled`) |
| `:VellumUpdate` | Update all plugins with `vim.pack.update()` and pull the repository |

Adding a plugin means adding one section to `lua/plugins/config.lua`; the
field-by-field reference lives in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#plugin-management).

## Key Mappings

`<leader>` is `Space` and `<localleader>` is `,`. `<C-z>` is mapped globally,
the Neovide mappings are added when the GUI is detected, and the terminal keys
live in `core/keymap.lua`; the rest comes from the plugin table, so it loads
lazily. All of them carry `desc` descriptions that show up in keymap listings
such as `:map`.

| Mapping | Action |
| --- | --- |
| `<leader>uf` | Toggle the file tree (VS Code: the sidebar) |
| `<leader>uw` | Toggle line wrap |
| `<C-k><C-t>` | Colorscheme picker (live preview) |
| `<leader>st` | Toggle the terminal (float) |
| `<leader>sv` / `<leader>sh` | Vertical / horizontal terminal |
| `<leader>sd` | Toggle a `dsh-tui --resume` session |
| `<leader>bh` / `<leader>bl` | Previous / next buffer |
| `<leader>bi` | Buffer picker (telescope `buffers`; `<M-d>` deletes the selection) |
| `<leader>bd` / `<leader>bo` | Delete this buffer / the other buffers |
| `<leader>tf` / `<leader>t<C-f>` | Find files / live grep (telescope) |
| `<leader>lf` | Format the buffer (ruff for Python, StyLua for Lua) |
| `<leader>lr` | Rename symbol |
| `<leader>lc` | Code action |
| `<leader>ld` / `<leader>lD` | Go to definition / peek definition |
| `<leader>li` | Go to implementation |
| `<leader>lh` | Hover documentation |
| `<leader>lR` | Find references |
| `<leader>ln` / `<leader>lp` | Next / previous diagnostic |
| `<leader>le` / `<leader>lE` | Next / previous error |
| `<leader>lP` / `<leader>lt` | Line diagnostics / trouble panel |
| `<leader>gn` / `<leader>gp` | Next / previous git hunk |
| `<leader>gP` / `<leader>gs` | Preview / stage git hunk |
| `<leader>gu` / `<leader>gr` | Undo stage / reset hunk |
| `<leader>gb` / `<leader>gl` | Git blame / blame line |
| `<leader>gB` | Stage the buffer |
| `<leader>gt` | Neogit |
| `<leader>hp` | Hop to word |
| `<leader>ug` | Project-wide find and replace (grug-far) |
| `<leader>ul` / `<leader>uu` | Plugin list / undotree |
| `<leader>uc` / `<leader>ut` | View configuration / todo list |
| `<leader>qn` / `<leader>qp` / `<leader>qo` / `<leader>qc` | Quickfix next / prev / open / close |
| `<C-z>` | Undo, in normal, visual and insert mode |
| `jj` | Leave insert or terminal mode (better-escape.nvim) |
| `<F11>` / `<C-=>` / `<C-->` | Neovide: fullscreen, zoom in, zoom out |

Inside the file tree `g?` lists its own mappings; the configuration remaps a
few of them — `<CR>` opens media and office files with the system, `V`/`H` open
vertical/horizontal splits, `.` toggles hidden files and `<F5>` reloads — and
git integration is turned off. A terminal opens in insert mode,
`<Esc>` leaves terminal mode, `<M-s>` toggles it, and a count picks another
terminal: `2<leader>st` toggles terminal 2. `:VellumTerm` does the same from the
command line — `:VellumTerm 3 direction=vertical size=50`, `:VellumTerm dsh`.

## VS Code (vscode-neovim)

Install the [vscode-neovim](https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim)
extension and leave its options untouched — with `vscode-neovim.neovimClean`,
`vscode-neovim.NVIM_APPNAME` and `vscode-neovim.neovimInitVimPaths.*` at their
defaults it reads this same configuration, and Neovim detects the editor
through `vim.g.vscode`.

In that environment the configuration trims itself down, because VS Code already
provides the corresponding features:

- the plugin loader only loads the sections marked `vscode = true` in
  `lua/plugins/config.lua` — currently `grug-far`, `hop`, `nvim-surround` and
  `nvim-autopairs`; add the flag to any other section (telescope, say) to use
  it inside VS Code too;
- the LSP and completion stack (`mason`, `none-ls`, `blink.cmp`, `lspsaga`,
  `nvim-lspconfig`) stays off, and no Neovim LSP client is started;
- no rendering plugin fights the VS Code UI (`lualine`, `indent-blankline`,
  `nvim-tree`, `gitsigns` and friends are all off);
- the clipboard goes through the VS Code API, and the login-shell environment
  import is skipped.

`lua/core/vscode.lua` rebinds the keys those disabled plugins would have owned
to the equivalent VS Code commands, so the muscle memory carries over:
formatting, rename, code actions, definition/hover/references, the diagnostics
panel, quick open, find in files, the theme picker, the sidebar and terminal
toggles, the SCM view, git-hunk navigation and staging, and folding all stay on
the keys you already know.

## Notes

- The central plugin table and its loader are adapted from
  [IceNvim](https://github.com/Shaobin-Jiang/IceNvim).
- `nvim-pack-lock.json` pins the plugin revisions per machine — it is
  git-ignored, so it is not shared through the repository; `:VellumUpdate`
  moves it forward.
- `temp/` is the scratch directory for throwaway files and is git-ignored.
- Because `core/shell.lua` imports the login-shell environment once per
  session, a Neovide started from Finder/Dock still finds `node`, `npm` and
  other tools.

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — repository layout, Neovim
  startup flow, plugin set, setup scripts and conventions.
- [docs/CHANGELOG.md](docs/CHANGELOG.md) — release history, following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- [AGENTS.md](AGENTS.md) — instructions for AI coding agents working here.

## License

[MIT](LICENSE) © ChenXu Huang
