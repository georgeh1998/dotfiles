#!/bin/bash
# Dotfiles setup script
# Run this script from the dotfiles directory to set up symlinks for config files.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# Add source line to ~/.zshrc if not already present
SOURCE_LINE="source $DOTFILES_DIR/zsh/zshrc"
if ! grep -qF "$SOURCE_LINE" ~/.zshrc 2>/dev/null; then
  echo "$SOURCE_LINE" >> ~/.zshrc
  echo "  Added source line to ~/.zshrc"
else
  echo "  Skipped: source line already in ~/.zshrc"
fi

echo ""
echo "Done."
