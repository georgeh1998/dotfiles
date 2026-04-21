#!/bin/bash
# Claude Code setup script
# Run this script from the dotfiles directory to set up symlinks for Claude Code.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude Code from: $DOTFILES_DIR"

mkdir -p "$CLAUDE_DIR"

# CLAUDE.md
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "  Linked: CLAUDE.md"

# settings.json
ln -sf "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked: settings.json"

# skills
rm -rf "$CLAUDE_DIR/skills"
ln -sf "$DOTFILES_DIR/claude/skills" "$CLAUDE_DIR/skills"
echo "  Linked: skills/"

# hooks
rm -rf "$CLAUDE_DIR/hooks"
ln -sf "$DOTFILES_DIR/claude/hooks" "$CLAUDE_DIR/hooks"
chmod +x "$DOTFILES_DIR/claude/hooks/"*.sh
echo "  Linked: hooks/"

# agents
rm -rf "$CLAUDE_DIR/agents"
ln -sf "$DOTFILES_DIR/claude/agents" "$CLAUDE_DIR/agents"
echo "  Linked: agents/"

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
  "**/CLAUDE.local.md",
  "**/claude/tasks/**"
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
