#!/bin/sh
# Link this repository's nvim/ directory into Neovim's config location.
# Primary target: macOS (Darwin); Linux works identically via XDG paths.
set -eu

FORCE=0

usage() {
    cat <<'EOF'
Usage: setup.sh [-f|--force] [-h|--help]

Links the repository's nvim/ directory to ${XDG_CONFIG_HOME:-~/.config}/nvim.

Options:
  -f, --force   Replace an existing target: a foreign link is removed, a real
                file or directory is backed up to nvim.bak.<timestamp>.
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

# brew_install <formula> <command>: install <formula> with Homebrew when
# <command> is missing; only warns when Homebrew itself is unavailable.
brew_install() {
    if command -v "$2" >/dev/null 2>&1; then
        info "Found: $2"
        return 0
    fi
    if command -v brew >/dev/null 2>&1; then
        info "Installing $1 with Homebrew..."
        if brew install "$1"; then
            return 0
        fi
        warn "brew install $1 failed; install it manually."
    else
        warn "$2 is not installed and Homebrew was not found."
        hint "Install Homebrew first (https://brew.sh), then: brew install $1"
    fi
    return 1
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
    # This configuration relies on Neovim 0.11+ (vim.lsp auto-discovery).
    NVIM_VERSION=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')
    case "$NVIM_VERSION" in
        0.*)
            minor=${NVIM_VERSION#0.}
            case "$minor" in
                ''|*[!0-9]*) : ;;  # unparsable, skip the check
                *)
                    if [ "$minor" -lt 11 ]; then
                        warn "Neovim $NVIM_VERSION detected; this configuration requires Neovim 0.11 or newer."
                    fi
                    ;;
            esac
            ;;
    esac
fi

# --- nvim-treesitter external dependencies ----------------------------------
# The configuration uses the main-branch nvim-treesitter, which shells out to
# the tree-sitter CLI and a C compiler (vim.env.CC = "gcc") to build parsers.

MISSING_DEPS=0

if [ "$PLATFORM" = macOS ]; then
    # The tree-sitter formula ships only libtree-sitter; the CLI lives in the
    # separate tree-sitter-cli formula.
    brew_install tree-sitter-cli tree-sitter || MISSING_DEPS=1
    if command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 \
        || command -v clang >/dev/null 2>&1; then
        info "Found: C compiler"
    else
        warn "no C compiler found; parser compilation will fail."
        hint "Install the Xcode Command Line Tools: xcode-select --install"
        MISSING_DEPS=1
    fi
else
    if ! command -v tree-sitter >/dev/null 2>&1; then
        warn "tree-sitter CLI is not installed; nvim-treesitter needs it to build parsers."
        hint "Install it via your package manager or: npm install -g tree-sitter-cli"
        MISSING_DEPS=1
    fi
    if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 \
        && ! command -v clang >/dev/null 2>&1; then
        warn "no C compiler found; parser compilation will fail."
        hint "Install one with your package manager, e.g.: sudo apt install build-essential"
        MISSING_DEPS=1
    fi
fi

# --- Resolve paths ---------------------------------------------------------

ROOT_DIR=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
SOURCE="$ROOT_DIR/nvim"
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
TARGET="$CONFIG_HOME/nvim"

if [ ! -d "$SOURCE" ]; then
    error "expected nvim/ directory not found at $SOURCE"
    exit 1
fi

# --- Handle an existing target ---------------------------------------------

if [ -L "$TARGET" ]; then
    CURRENT=$(readlink "$TARGET")
    if [ "$CURRENT" = "$SOURCE" ]; then
        info "Skipped: $TARGET already points to $SOURCE."
        exit 0
    fi
    if [ "$FORCE" -eq 1 ]; then
        rm -f "$TARGET"  # removes the link only; also clears broken links
        info "Removed old link: $TARGET -> $CURRENT"
    else
        error "$TARGET is a link to $CURRENT, not to this repository."
        hint "Re-run with --force to replace it, or remove it yourself."
        exit 1
    fi
elif [ -e "$TARGET" ]; then
    if [ "$FORCE" -eq 1 ]; then
        BACKUP="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
        mv "$TARGET" "$BACKUP"
        info "Backed up existing config: $BACKUP"
    else
        error "$TARGET already exists."
        hint "Back it up or remove it yourself, or re-run with --force to back it up automatically."
        exit 1
    fi
fi

# --- Create the link --------------------------------------------------------

mkdir -p "$CONFIG_HOME"
ln -s "$SOURCE" "$TARGET"
info "Linked: $TARGET -> $SOURCE"

if [ "$MISSING_DEPS" -eq 1 ]; then
    warn "some dependencies are still missing; fix the items above, then run :TSUpdate inside Neovim."
fi
