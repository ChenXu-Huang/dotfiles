# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `.config/nvim/lua/core/miscellaneous.lua`: native Windows now uses
  `clipboard=unnamedplus` like the other platforms; only WSL keeps the
  `clip.exe` `TextYankPost` autocmd.

## [0.4.1] - 2026-10-19

### Added

- `.config/nvim/lua/plugins/config.lua`: `better-escape.nvim` leaves insert
  mode on `jj` without the `timeoutlen` wait a plain insert-mode mapping would
  cause. Its default mappings are disabled, so only insert-mode `jj` escapes;
  the section sets `main = "better_escape"` because the loader cannot infer
  that module name from the repository.

### Changed

- `.config/nvim/lua/plugins/config.lua`: nvim-tree hides its line numbers and
  groups empty directories.

### Fixed

- `.config/nvim/lua/core/basic.lua`: `scrolloff`/`sidescrolloff` were derived
  once from the startup window height, so the cursor drifted off-center after
  the window was resized (Neovide zoom and fullscreen both change the row
  count). They are now re-derived from `lines` on `VimResized`, keeping the
  cursor centered at every window size.
- `.config/nvim/lua/core/ft.lua`: the Python `FileType` handler ran
  `:compiler python`, which Neovim 0.12 no longer ships (`E666`); an error in
  an autocommand stops the remaining `FileType` handlers, so Python had
  neither treesitter highlighting nor pyright. The call and the `<F9>`
  `:make` mapping that never ran are removed.
- `.config/nvim/lua/core/terminal.lua`: terminal windows now set
  `sidescrolloff = 0` (window-local, on `TermOpen`/`BufWinEnter`), so moving
  the cursor right in normal mode no longer scrolls the whole view early.

## [0.4.0] - 2026-10-19

### Added

- `.config/nvim/lua/core/vscode.lua`: the configuration now detects
  vscode-neovim (`vim.g.vscode`) and trims itself down there, so one config
  serves both the standalone editor and VS Code: the LSP/completion stack
  (mason, mason-lspconfig, mason-tool-installer, none-ls, blink, lspsaga,
  nvim-lspconfig) and every rendering plugin VS Code already provides
  (lualine, indent-blankline, nvim-tree, gitsigns, telescope) stay disabled
  because the loader only loads sections marked `vscode = true`, the editor-only
  options are skipped, the login-shell import is not run, the clipboard goes
  through the VS Code API, and the `<leader>l*` and `<leader>uf` keys call the
  equivalent VS Code commands.
- `.config/nvim/lua/plugins/config.lua` and
  `.config/nvim/lua/plugins/pack.lua`: plugins, their options and their
  keymaps now live in one central table keyed by a logical name, and the loader
  turns it into `vim.pack` specs, replacing lazy.nvim. Section fields cover
  `enabled`, `version`, `main`, `opts`, `config`, `dependencies`, `init`,
  `build`, `priority` and the lazy triggers `lazy`/`event`/`ft`/`cmd`/`keys`;
  the `VeryLazy` custom event loads a plugin after `VimEnter`. Triggers are
  registered before `vim.pack.add()` runs, and lazy keymaps load and set up the
  plugin on first press before running the binding's action. The `blink`
  section registers blink.cmp's LSP capabilities through `vim.lsp.config("*")`
  when it is set up.
- `.config/nvim/lua/core/{utils,ft}.lua` and `.config/nvim/lua/lsp/`: platform
  checks plus mapping and float helpers, the `FileType`-scoped options, and the
  LSP wiring split into one module per concern (server settings, enablement and
  diagnostics, completion, formatting, and the lspsaga/trouble sections) that
  used to live inside the plugin table.
- `.config/nvim/lua/core/terminal.lua`: the terminal now runs on Neovim's
  built-in one. `Vellum.terminal` opens a float, a vertical split or a
  horizontal split, keeps a size per direction and the last mode across
  toggles, and exposes `toggle`/`toggle_current`/`dispose` plus `:VellumTerm`
  (`:VellumTerm 3 direction=vertical size=50`). `<leader>st`/`sv`/`sh` use
  `v:count1` as the terminal id, `<M-s>` toggles the terminal under the cursor,
  and `<leader>sd` keeps the `dsh-tui --resume` session with its `<Esc>`
  passthrough and exit-code handling.
- `.config/nvim/lua/plugins/profile.lua`: `:VellumProfile` lists every plugin
  with its state (`loaded`, `not loaded`, `disabled`) and `:VellumUpdate` wraps
  `vim.pack.update()`.
- `.config/nvim/lua/core/basic.lua`: Markdown and plain-text buffers now
  soft-wrap at word boundaries (`wrap` + `linebreak` set buffer-locally via a
  `FileType` autocommand); other file types keep the global `nowrap`.
- `.agents/skills/code-style`: new skill holding the per-language code style
  rules. `SKILL.md` is a router that states no rule of its own and dispatches to
  one self-contained file per language under `references/` (Python, Lua,
  PowerShell, Bash), so work in one language never loads another language's
  rules, and `assets/language-template.md` is the skeleton for adding more. Its
  Python file routes every environment and dependency operation through `uv`
  (`uv run`, `uvx`) rather than a bare `pip` or a hand-activated virtual
  environment, leaves dependency changes (`uv add`/`uv remove`, `uv lock`,
  `uv sync`, `uv python install`) to the user or to an approved escalation so
  every such run keeps using the shared global uv cache, and allows
  `UV_CACHE_DIR=./temp/uv-cache` only as a temporary, single-command escape
  hatch for a dependency-free `uv run` that a sandbox would otherwise fail; a
  command that downloads must be announced first.

### Changed

- `.config/nvim`: the configuration now requires **Neovim 0.12 or newer**
  (`vim.pack`, treesitter bundled with Neovim) instead of 0.11; the setup
  scripts check for the new version and no longer install the nvim-treesitter
  build dependencies (`tree-sitter` CLI, a C compiler).
- `.config/nvim/nvim-pack-lock.json` replaces `lazy-lock.json` as the plugin
  lockfile, and unlike it is tracked in Git so every machine installs the same
  revisions; `:VellumUpdate` (or `vim.pack.update()`) moves it forward.
- `.config/nvim/lua/core/keymap.lua`: the `<C-z>` undo mapping is registered for
  normal, insert and visual mode only, so in a terminal it reaches the running
  job again instead of being swallowed by a no-op mapping.
- `.agents/skills/commit`: release mode (`/commit v{version}`) now tags the
  release commit `v{version}` itself (lightweight, matching the existing
  tags) instead of leaving tagging to a manual follow-up, so the changelog
  compare links work as soon as the release lands; the skill also spells out
  that pushing such a tag needs an explicit refspec, since `--follow-tags`
  only carries annotated ones.
- `AGENTS.md` and `.agents/skills/commit`: documentation is now written while a
  commit is prepared rather than after a change — `docs/CHANGELOG.md` and
  `docs/ARCHITECTURE.md` are updated from the staged diff in that pass, and the
  later staging steps name only the files the skill wrote instead of running
  `git add .`, so unrelated working-tree changes stay out of the commit.
- `.agents/skills/commit`: a commit with nothing staged now stops instead of
  inventing work, reworking something that is still only an `Unreleased`
  addition extends that entry rather than filing a `Changed` one, and release
  mode bumps the project's own version file (refreshing `uv.lock` under uv) and
  picks the tag style the repository's history shows.

### Removed

- `.config/nvim`: lazy.nvim and its one-spec-per-file layout in `lua/plugins/`
  are gone in favour of `vim.pack` and the central plugin table, and
  nvim-treesitter was dropped because Neovim 0.12 bundles treesitter
  highlighting and parsers; the parsers already installed under
  `stdpath("data")/site` keep working. Since no parser is compiled during
  setup any more, the `tree-sitter` CLI and C compiler requirements are gone
  as well.
- `.config/nvim`: `bufferline.nvim` was replaced by `telescope.nvim`, whose
  `buffers` picker covers selecting, previewing and deleting buffers and is
  actively maintained, where bufferline has had no release since January 2025.
  `<leader>bi` opens that picker (deletion is `<M-d>` inside it), `<leader>bh`/
  `<leader>bl` cycle buffers, `<leader>bd` deletes the current buffer and
  `<leader>bo` closes the others; `<leader>tf` and `<leader>t<C-f>` open
  `find_files` and `live_grep`.
- `.config/nvim/lua/plugins/config.lua`: `toggleterm.nvim` is gone — the
  built-in terminal in `core/terminal.lua` covers the float and split toggles,
  the terminal-scoped keys and the `dsh-tui` session, so the plugin and its
  `nvim-pack-lock.json` entry were dropped.

### Fixed

- `.config/nvim/lua/core/basic.lua`: the Windows shell option was spelled
  `shellpip`, which Neovim does not have — assigning it raised
  `Unknown option 'shellpip'` and aborted the rest of `core/init.lua`, so the
  later core modules never loaded and no key mappings were registered. It is now
  set as `shellpipe`, which also lets the lines below it run again on Windows
  (`shellquote`, `shellxquote`).

## [0.3.0] - 2026-10-11

### Changed

- `.config/nvim/lua/core/basic.lua`: `pwsh` is set as `shell` on Windows only
  (previously on every OS where it was executable), with expanded Windows
  shell integration flags (UTF-8 output, `-NoProfile`, `shellredir` and
  `shellpipe`).
- `.config/nvim/lua/core/shell.lua`: the `PATH` cache is now validated before
  use — a cached `PATH` is applied only while the cache file is newer than
  the shell startup files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`) and nvm's
  default-version alias, so a stale cache (edited `.zshrc`, a switched nvm
  default) is refetched instead of silently imported.

### Removed

- `.config/nvim/lua/core/shell.lua`: `shell.cmd()`, its `requires` probing and
  the write-only `status` field. `sync_env()` already makes programs
  resolvable before any plugin runs, so toggleterm now launches `dsh-tui`
  with a plain command string and nothing consumed the status.

### Added

- `<leader>uw` toggles line wrap for the current window.
- `NOTE`, `TODO`, `FIXME` and other tags inside comments are highlighted via
  the built-in nvim-treesitter mechanism: the `comment` parser is added to the
  installed parser list and injected into the comments of every language whose
  upstream queries ship that rule, so tags map onto the `@comment.todo`,
  `@comment.note`, `@comment.warning` and `@comment.error` capture groups the
  colorscheme already styles — no extra plugin and no custom highlight query.

### Fixed

- `.config/nvim/lua/plugins/lspsaga.lua`: the `<leader>ld` mapping called
  `:Lspsaga definition`, a command the plugin no longer provides, so the key
  errored out; it now calls `:Lspsaga goto_definition`.

## [0.2.0] - 2026-10-09

### Added

- `scripts/setup.sh` (macOS-first) and `scripts/setup.ps1` environment
  checks: they warn when Neovim is missing or older than 0.11 and verify the
  external dependencies of the main-branch nvim-treesitter (tree-sitter CLI
  and a C compiler). Missing dependencies are installed automatically with
  Homebrew on macOS and with Scoop on Windows; other cases print install
  hints.
- `-f`/`--force` (`-Force` on Windows) option for both setup scripts: a
  foreign link at the target is removed, a real file or directory is backed
  up to `<target>.bak.<timestamp>` before linking.
- `scripts/setup.sh` strict mode (`set -eu`), platform detection, `--help`,
  and colored output on interactive terminals.
- `desc` descriptions on all custom key mappings (core, bufferline, lspsaga,
  nvim-tree, hop, toggleterm) so they show up in keymap listings; also fixed
  the descriptions in `.config/nvim/lua/core/keymap.lua` being passed as an
  ignored fifth argument to `vim.keymap.set` instead of inside the options
  table.
- Window title (`vim.opt.titlestring`) showing the current working directory,
  and the lualine statusline now displays the working-directory basename next
  to the git branch.
- nvim-autopairs angle-bracket (`<`/`>`) rule for html, xml, lua, c, cpp,
  typescript, and rust that only expands after a word character or a closing
  delimiter.
- `.config/nvim/lua/plugins/none-ls.lua`: StyLua as the Lua formatter
  (`null-ls.builtins.formatting.stylua`), so Lua is formatted by a dedicated
  formatter like Python already is with ruff. The style comes from the existing
  `.editorconfig` (4 spaces, LF) — StyLua reads it when no `stylua.toml`
  exists, so none is added.
  `.config/nvim/lua/plugins/mason-tool-installer.lua` ensures the `stylua`
  binary is installed (`:MasonToolsUpdate`; the automatic check on
  start is throttled by `debounce_hours`).
- `.config/nvim/lua/core/shell.lua`: `sync_env()` imports the login-shell
  environment when the editor is started outside a terminal, where `.zshrc`
  never ran — that is why Neovide from Finder/Dock could not find nvm's
  `node`/`npm`, Homebrew tools or `NVM_DIR`, and why Mason failed with
  `Could not find executable "npm" in PATH`. `PATH` is merged, other variables
  are filled in only when unset, and the resolved `PATH` is cached in
  `stdpath("cache")/shell-path` so later starts apply it without paying for
  another shell startup; the fetch blocks startup only when the `PATH` looks
  like the launchd default and runs in the background otherwise, and failures
  and Windows leave the environment untouched.
  `.config/nvim/lua/core/init.lua` calls it before the other core modules load.
- `.config/nvim/lua/plugins/gitsigns.lua`: gitsigns.nvim for git hunk signs,
  with hunk navigation on `]h`/`[h` and `<leader>uh` mappings for preview,
  stage, reset, blame and diff.
- `README.md`: the user-facing entry point — requirements, installation with
  both setup scripts (flags, what they link, how to undo it), repository
  layout, the key mappings and links into `docs/`.
- `.config/powershell/`: the Windows PowerShell 7 configuration, linked into
  the per-user `Documents\PowerShell` directory by `scripts/setup.ps1`.
  `Microsoft.PowerShell_profile.ps1` switches the console to UTF-8, hooks
  `scoop-search`, loads posh-git, oh-my-posh (`stelbent.minimal`) and
  Terminal-Icons, configures PSReadLine (Emacs mode, list-view predictions from
  history and plugins) and PSFzf (`Ctrl+f`, `Ctrl+r`), adds `vim`, `g`, `grep`
  and `which` shortcuts, and puts the `x64` bin directory of the newest
  installed Windows SDK on `PATH`; `powershell.config.json` sets
  `Microsoft.PowerShell:ExecutionPolicy` to `RemoteSigned` for the current
  user, which only takes effect from that directory (or from `$PSHOME` for all
  users).
- `.agents/skills/`: the skill definitions for the agent CLIs are tracked in
  the repository — one directory per skill (`.agents/skills/<name>/SKILL.md`)
  — and linked into both locations those tools read: `~/.agents/skills` and
  `~/.claude/skills`, or `%USERPROFILE%\.agents\skills` and
  `%USERPROFILE%\.claude\skills` on Windows, so one copy serves every CLI.
- `.config/zsh/`: the macOS zsh startup files — `.zprofile` evaluates Homebrew's
  `brew shellenv`, `.zshrc` loads oh-my-zsh, nvm (with its completion file),
  rustup, the `EDITOR`/`BUNDLER_EDITOR` variables, the `vim`/`buu` aliases and
  the `y` yazi wrapper. `scripts/setup.sh` links both into `${ZDOTDIR:-$HOME}`
  on macOS; an existing real file there is reported and left alone unless
  `--force` backs it up first (the `link_config` helper now accepts files, not
  only directories). `.zshrc` resolves the Homebrew prefix as
  `_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"` — lower case, like a
  shell-local helper rather than an environment variable — and unsets it after
  the rustup line, so it does not linger in the session, while nvm and rustup
  still load in a shell that never read `.zprofile` (a non-login interactive
  shell), where every `[ -s … ]` guard would otherwise fail silently.

### Changed

- The Neovim configuration moved from `nvim/` to `.config/nvim/`, mirroring
  the layout of the XDG config home; both setup scripts and the documentation
  now resolve the configuration from `.config/nvim`.
- Both setup scripts now skip only when the target link already points at
  this repository; a link pointing elsewhere is reported (and replaced with
  `-f`/`-Force`) instead of being silently skipped.
- nvim-tree follows the working directory (`sync_root_with_cwd`,
  `respect_buf_cwd`) and reveals the focused file, updating the tree root
  accordingly.
- nvim-tree no longer hides git-ignored entries
  (`filters.git_ignored = false`) and dims them through
  `renderer.highlight_git = "name"`, which renders the `!!` status with
  `NvimTreeGitFileIgnoredHL` (linked to `Comment`).
- `filters.dotfiles` stays at its default `false`, which means names starting
  with `.` are *not* filtered and stay visible. `.DS_Store` and `Desktop.ini`
  are therefore excluded explicitly, by name at any depth, through
  `filters.custom = { "^\.DS_Store$", "^Desktop\.ini$" }`; the `I` and `H`
  toggles do not affect them, only the custom-filter toggle `U` does.
- `AGENTS.md`: the code style now forbids comments unless the user asks for
  one; the explanatory comments that came with the StyLua support were removed
  to match.
- `.config/nvim/lua/core/basic.lua`: the Neovide scale factor is 0.9 instead
  of 0.85.
- `scripts/setup.ps1` links a table of source/target pairs through one
  `New-ConfigLink` helper instead of handling the single Neovim junction
  inline: a missing target directory is created, the link types are tried in
  order (a junction for the Neovim config and the skills, a hard link with a
  symbolic-link fallback for the PowerShell files), an existing target is still
  skipped, replaced with `-Force`, or backed up to `<target>.bak.<timestamp>`
  first, and the script exits non-zero when any link was not created;
  `docs/ARCHITECTURE.md` and `README.md` describe the new layout.
- `scripts/setup.sh` links every pair through one `link_config` helper instead
  of handling the single Neovim symlink inline, matching `scripts/setup.ps1`:
  it creates a missing target directory, skips a correct link, replaces a
  foreign link or backs up a real file or directory with `--force`, and works
  through the remaining pairs before exiting non-zero.

### Fixed

- `scripts/setup.sh` installed the wrong Homebrew package for the
  nvim-treesitter dependency: the `tree-sitter` formula ships only the
  `libtree-sitter` library, so the CLI was still missing afterwards. It now
  installs the `tree-sitter-cli` formula.
- `.config/nvim/lua/core/shell.lua`: `shell.cmd(program, { args, requires })`
  builds the command string for a terminal program. When the editor's own
  `PATH` cannot resolve it (`requires` names anything else it needs, such as
  `node` for a `#!/usr/bin/env node` shim), it defers to the user's login
  shell in interactive mode (`$SHELL -lic 'exec …'`), which loads
  `~/.zshrc`/`~/.profile` itself; Windows always gets the plain command, since
  the registry `PATH` is visible to GUI processes.
- `.config/nvim/lua/plugins/toggleterm.lua`: `<leader>td` uses that helper
  for `dsh-tui --resume`. toggleterm runs commands through a non-interactive
  shell (`&shell -c`), which never reads `~/.zshrc` — the file where nvm and
  friends put themselves on `PATH` — so the mapping failed with
  `command not found` whenever the editor had not inherited them. The terminal
  also sets `close_on_exit = false` — the option the spec misspelled as
  `close_on_edit`, which toggleterm does not have — so a failing `dsh-tui`
  leaves its window and error text on screen instead of vanishing instantly (a
  clean exit still closes the window).
- `.config/powershell/Microsoft.PowerShell_profile.ps1`: the Windows SDK `x64`
  bin directory was picked by sorting the version folders as strings, where
  `10.0.9999.0` outranks `10.0.10240.0`; the folders are now sorted as
  `[version]` values, so the newest installed SDK wins.

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

[Unreleased]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.4.0...HEAD
[0.4.1]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ChenXu-Huang/dotfiles/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ChenXu-Huang/dotfiles/releases/tag/v0.1.0
