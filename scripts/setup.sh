#!/bin/sh
ROOT_DIR=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
TARGET="$CONFIG_HOME/nvim"

if [ -L "$TARGET" ]; then
    echo "Skipped: $TARGET is already a link."
    exit 0
elif [ -e "$TARGET" ]; then
    echo "Warning: $TARGET already exists." >&2
    echo "Back it up or remove it yourself, then re-run this script." >&2
    exit 1
fi

mkdir -p "$CONFIG_HOME"
ln -s "$ROOT_DIR/nvim" "$TARGET"
echo "Linked: $TARGET -> $ROOT_DIR/nvim"
