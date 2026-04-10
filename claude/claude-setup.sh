#!/bin/bash
# Claude Code setup script
# Run this script from the dotfiles directory to set up symlinks for Claude Code.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude Code from: $DOTFILES_DIR"

mkdir -p "$CLAUDE_DIR"

# settings.json
ln -sf "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked: settings.json"

# skills
rm -rf "$CLAUDE_DIR/skills"
ln -sf "$DOTFILES_DIR/claude/skills" "$CLAUDE_DIR/skills"
echo "  Linked: skills/"

# statusline
rm -rf "$CLAUDE_DIR/statusline"
ln -sf "$DOTFILES_DIR/claude/statusline" "$CLAUDE_DIR/statusline"
chmod +x "$DOTFILES_DIR/claude/statusline/"*.sh
echo "  Linked: statusline/"

# global gitignore
GLOBAL_GITIGNORE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
mkdir -p "$(dirname "$GLOBAL_GITIGNORE")"
touch "$GLOBAL_GITIGNORE"
GITIGNORE_PATTERNS=(
  "**/.claude/settings.local.json"
  "**/CLAUDE.local.md"
)
for pattern in "${GITIGNORE_PATTERNS[@]}"; do
  if ! grep -qF "$pattern" "$GLOBAL_GITIGNORE"; then
    echo "$pattern" >> "$GLOBAL_GITIGNORE"
    echo "  Added to global gitignore: $pattern"
  else
    echo "  Already in global gitignore: $pattern"
  fi
done

echo ""
echo "Done. Claude Code is set up."
