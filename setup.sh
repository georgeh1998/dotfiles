#!/bin/bash
# Dotfiles setup script
# Run this script from the dotfiles directory to set up symlinks for config files.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# Link each directory under config/ into ~/.config/
mkdir -p "$CONFIG_DIR"
for dir in "$DOTFILES_DIR"/config/*/; do
  dir_name="$(basename "$dir")"
  target="$CONFIG_DIR/$dir_name"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    echo "  Skipped: $dir_name (already exists at $target)"
    continue
  fi
  ln -sf "$dir" "$target"
  echo "  Linked: config/$dir_name -> $target"
done

echo ""
echo "Done."
