# dotfiles

Personal development-environment configuration as code: a
[Neovim](https://neovim.io/) configuration, a Windows PowerShell 7 profile and
the skill definitions for the agent CLIs, plus cross-platform setup scripts
that link them into place, so everything is edited in one repository and
tracked in Git.

## Requirements

- **Neovim 0.11 or newer** — the configuration relies on `vim.lsp.config`
  auto-discovery, and the setup scripts warn when the version is older.
- **Git** — lazy.nvim clones plugins into `stdpath("data")` on first start.
- **nvim-treesitter dependencies** — the `tree-sitter` CLI and a C compiler
  (`cc`, `gcc` or `clang`) to build parsers.
- Optional: a Nerd Font (`JetBrainsMono Nerd Font Mono` is the configured GUI
  font), [Neovide](https://neovide.dev), and `pwsh` — on Windows Neovim uses
  it as `shell`.
- Optional: **PowerShell 7** on Windows — `scripts/setup.ps1` links the
  profile in `.config/powershell/` into the per-user configuration directory
  that `pwsh` reads.
- Optional: an agent CLI that reads skills from `~/.agents/skills` or
  `~/.claude/skills` — the setup scripts link `.agents/skills` into both.

## Installation

The setup scripts link `.config/nvim` to Neovim's config location, the zsh
startup files to `~/.zshrc` and `~/.zprofile` (macOS) and, on Windows, the
PowerShell 7 profile to the directory `pwsh` reads it from, checking the
environment first. They are safe to re-run.

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
| macOS | `${ZDOTDIR:-~}/.zshrc` and `${ZDOTDIR:-~}/.zprofile`, symbolic links |
| macOS / Linux | `~/.agents/skills` and `~/.claude/skills`, symbolic links |
| Windows | `%LOCALAPPDATA%\nvim`, a junction (no Administrator rights) |
| Windows | `Documents\PowerShell`: profile and `powershell.config.json` |
| Windows | `%USERPROFILE%\.agents\skills` and `.claude\skills`, junctions |

Both scripts also:

- warn when Neovim is missing or older than 0.11;
- install the nvim-treesitter dependencies with [Homebrew](https://brew.sh) on
  macOS and with [Scoop](https://scoop.sh) on Windows, printing install hints
  when the package manager is unavailable;
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
Neovim start bootstraps lazy.nvim and installs the plugins, which needs network
access.

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
```

```powershell
Remove-Item "$env:LOCALAPPDATA\nvim" -Force
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
.config/powershell/   PowerShell 7 profile, linked into Documents\PowerShell
.config/zsh/          zsh startup files, linked into $HOME on macOS
scripts/              setup.sh (macOS/Linux) and setup.ps1 (Windows)
docs/                 ARCHITECTURE.md and CHANGELOG.md
```

Inside `.config/nvim/`:

- `init.lua` requires `lua/core/`, which imports the login-shell environment
  first and then the editor options, the global mappings and the lazy.nvim
  bootstrap, in that order.
- `lua/plugins/` holds one lazy.nvim spec per plugin and is auto-imported, so
  adding a file there is all it takes to extend the plugin set.
- `lsp/` holds one `vim.lsp.config` table per language server, auto-discovered
  by Neovim 0.11+.

The plugin set covers LSP and tooling (mason, none-ls, lspsaga), completion
(blink.cmp with friendly-snippets), navigation (nvim-tree, bufferline, hop),
editing (autopairs, surround, indent-blankline, grug-far), git (gitsigns),
terminals (toggleterm) and appearance (tokyonight, lualine, nvim-treesitter).

## Key Mappings

`<leader>` is `Space` and `<localleader>` is `,`. `<C-z>` is mapped globally
and the Neovide mappings are added when the GUI is detected; everything else
comes from plugin specs, so it loads lazily and carries `desc` descriptions
that show up in keymap listings such as `:map`.

| Mapping | Action |
| --- | --- |
| `<leader>uf` | Toggle the file tree |
| `<leader>uw` | Toggle line wrap |
| `<leader>tt` | Toggle the terminal (vertical by default) |
| `<leader>tf` | Float terminal |
| `<leader>tv` | Vertical terminal |
| `<leader>th` | Horizontal terminal |
| `<leader>t1` / `<leader>t2` | Toggle terminal 1 / 2 |
| `<leader>td` | Toggle a `dsh-tui --resume` session |
| `<leader>bh` / `<leader>bl` | Previous / next buffer |
| `<leader>bp` / `<leader>bc` | Pick a buffer / pick a buffer to close |
| `<leader>bd` / `<leader>bo` | Delete buffer / close other buffers |
| `<leader>lf` | Format the buffer (ruff for Python, StyLua for Lua) |
| `<leader>lr` | Rename symbol |
| `<leader>lc` | Code action |
| `<leader>ld` | Go to definition |
| `<leader>lh` | Hover documentation |
| `<leader>lR` | Find references |
| `<leader>ln` / `<leader>lp` | Next / previous diagnostic |
| `<leader>uhp` | Preview git hunk |
| `<leader>uhs` | Stage git hunk |
| `<leader>uhr` | Reset git hunk |
| `<leader>uhb` / `<leader>uhd` | Blame line / diff this file |
| `]h` / `[h` | Next / previous git hunk |
| `<leader>hp` | Hop to word |
| `<C-z>` | Undo, in normal and insert mode |
| `<F11>` / `<C-=>` / `<C-->` | Neovide: fullscreen, zoom in, zoom out |

Inside the file tree `g?` lists its own mappings, and `I`, `H` and `U` toggle
the git-ignored, dotfile and custom filters. In a terminal `<Esc><Esc>` leaves
terminal mode, `<C-h>`/`<C-j>`/`<C-k>`/`<C-l>` move between windows, and
`<A-t>` closes the terminal.

## Notes

- `lazy-lock.json` is git-ignored on purpose, so every machine floats plugin
  versions independently.
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
