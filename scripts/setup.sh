#!/bin/sh
# Link this repository's configuration into its locations in $HOME: the Neovim
# configuration, the VS Code user settings, the pandoc user data directory,
# the skills for the agent CLIs, and the zsh startup files on macOS.
# Primary target: macOS (Darwin); Linux works identically via XDG paths.
set -eu

FORCE=0

usage() {
    cat <<'EOF'
Usage: setup.sh [-f|--force] [-h|--help]

Links the repository's configuration into place:
  .config/nvim    -> ${XDG_CONFIG_HOME:-~/.config}/nvim
  .config/vscode  -> Code/User under ~/Library/Application Support (macOS)
                     or ${XDG_CONFIG_HOME:-~/.config} (Linux)
  .config/pandoc  -> ${XDG_DATA_HOME:-~/.local/share}/pandoc
  .agents/skills  -> ~/.agents/skills
  .agents/skills  -> ~/.claude/skills
  .config/zsh     -> ${ZDOTDIR:-~}/.zshrc and .zprofile (macOS)

Options:
  -f, --force   Replace an existing target: a foreign link is removed, a real
                file or directory is backed up to <target>.bak.<timestamp>.
  -h, --help    Show this help and exit.

Without --force the script never touches an existing target: it skips when
the link already points at this repository and exits with an error otherwise.
EOF
}

# Colors only when stdout is an interactive terminal.
if [ -t 1 ]; then
    C_INFO=$(printf '\033[32m')
    C_WARN=$(printf '\033[33m')
    C_ERR=$(printf '\033[31m')
    C_HINT=$(printf '\033[36m')
    C_OFF=$(printf '\033[0m')
else
    C_INFO='' C_WARN='' C_ERR='' C_HINT='' C_OFF=''
fi

info() { printf '%s%s%s\n' "$C_INFO" "$*" "$C_OFF"; }
warn() { printf '%sWarning: %s%s\n' "$C_WARN" "$*" "$C_OFF" >&2; }
error() { printf '%sError: %s%s\n' "$C_ERR" "$*" "$C_OFF" >&2; }
hint() { printf '%s  -> %s%s\n' "$C_HINT" "$*" "$C_OFF" >&2; }

# link_config <source> <target>: symlink <target> to <source>. Skips when the
# link is already correct, replaces a foreign link or backs up a real file or
# directory with --force, and returns non-zero when the target is left alone.
link_config() {
    src=$1
    dst=$2

    if [ ! -e "$src" ]; then
        error "expected source not found at $src"
        hint "run this script from a full clone of the dotfiles repository."
        return 1
    fi

    if [ -L "$dst" ]; then
        current=$(readlink "$dst")
        if [ "$current" = "$src" ]; then
            info "Skipped: $dst already points to $src."
            return 0
        fi
        if [ "$FORCE" -eq 1 ]; then
            rm -f "$dst"  # removes the link only; also clears broken links
            info "Removed old link: $dst -> $current"
        else
            error "$dst is a link to $current, not to this repository."
            hint "Re-run with --force to replace it, or remove it yourself."
            return 1
        fi
    elif [ -e "$dst" ]; then
        if [ "$FORCE" -eq 1 ]; then
            backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
            mv "$dst" "$backup"
            info "Backed up existing config: $backup"
        else
            error "$dst already exists."
            hint "Back it up or remove it yourself, or re-run with --force to back it up automatically."
            return 1
        fi
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    info "Linked: $dst -> $src"
}

while [ $# -gt 0 ]; do
    case $1 in
        -f|--force) FORCE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) error "unknown option: $1"; usage >&2; exit 2 ;;
    esac
    shift
done

# --- Platform detection (macOS first) -------------------------------------

OS=$(uname -s)
case "$OS" in
    Darwin) PLATFORM=macOS ;;
    Linux) PLATFORM=Linux ;;
    *) PLATFORM=$OS ;;
esac
info "Platform: $PLATFORM"

# --- Environment checks ----------------------------------------------------

if ! command -v nvim >/dev/null 2>&1; then
    warn "Neovim is not installed or not on PATH."
    case "$PLATFORM" in
        macOS)
            if command -v brew >/dev/null 2>&1; then
                hint "Install it with: brew install neovim"
            else
                hint "Install Homebrew first (https://brew.sh), then: brew install neovim"
            fi
            ;;
        Linux)
            hint "Install it with your package manager, e.g.: sudo apt install neovim"
            ;;
    esac
else
    # This configuration relies on Neovim 0.12+ (vim.pack and bundled treesitter).
    NVIM_VERSION=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')
    case "$NVIM_VERSION" in
        0.*)
            minor=${NVIM_VERSION#0.}
            case "$minor" in
                ''|*[!0-9]*) : ;;  # unparsable, skip the check
                *)
                    if [ "$minor" -lt 12 ]; then
                        warn "Neovim $NVIM_VERSION detected; this configuration requires Neovim 0.12 or newer."
                    fi
                    ;;
            esac
            ;;
    esac
fi

# --- Link targets ----------------------------------------------------------

ROOT_DIR=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
ZDOT_DIR=${ZDOTDIR:-"$HOME"}

if [ "$PLATFORM" = macOS ]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="$CONFIG_HOME/Code/User"
fi

FAILED=0

link_config "$ROOT_DIR/.config/nvim" "$CONFIG_HOME/nvim" || FAILED=1
link_config "$ROOT_DIR/.config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json" || FAILED=1
link_config "$ROOT_DIR/.config/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json" || FAILED=1
link_config "$ROOT_DIR/.config/pandoc" "${XDG_DATA_HOME:-$HOME/.local/share}/pandoc" || FAILED=1
link_config "$ROOT_DIR/.agents/skills" "$HOME/.agents/skills" || FAILED=1
link_config "$ROOT_DIR/.agents/skills" "$HOME/.claude/skills" || FAILED=1

if [ "$PLATFORM" = macOS ]; then
    link_config "$ROOT_DIR/.config/zsh/.zshrc" "$ZDOT_DIR/.zshrc" || FAILED=1
    link_config "$ROOT_DIR/.config/zsh/.zprofile" "$ZDOT_DIR/.zprofile" || FAILED=1
fi

if [ "$FAILED" -eq 1 ]; then
    exit 1
fi
