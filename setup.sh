#!/bin/bash
# Dotfiles setup script
# Run this script from the dotfiles directory to set up symlinks for config files.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# Link .tmux.conf to ~/.tmux.conf
TMUX_CONF="$HOME/.tmux.conf"
if [ -L "$TMUX_CONF" ]; then
  rm "$TMUX_CONF"
elif [ -e "$TMUX_CONF" ]; then
  echo "  Skipped: .tmux.conf (already exists at $TMUX_CONF)"
fi
if [ ! -e "$TMUX_CONF" ]; then
  ln -sf "$DOTFILES_DIR/.tmux.conf" "$TMUX_CONF"
  echo "  Linked: .tmux.conf -> $TMUX_CONF"
fi

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
