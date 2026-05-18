#!/bin/bash
# Claude Code setup script
# Run this script from the dotfiles directory to set up Claude Code config files.

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/claude"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude Code from: $DOTFILES_DIR"

mkdir -p "$CLAUDE_DIR"

# settings.json
ln -sf "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked: settings.json"

# skills
rm -rf "$CLAUDE_DIR/skills"
ln -sf "$CLAUDE_SRC/skills" "$CLAUDE_DIR/skills"
echo "  Linked: skills/"

# hooks
rm -rf "$CLAUDE_DIR/hooks"
ln -sf "$CLAUDE_SRC/hooks" "$CLAUDE_DIR/hooks"
echo "  Linked: hooks/"

# agents
rm -rf "$CLAUDE_DIR/agents"
ln -sf "$CLAUDE_SRC/agents" "$CLAUDE_DIR/agents"
echo "  Linked: agents/"

# statusline
rm -rf "$CLAUDE_DIR/statusline"
ln -sf "$CLAUDE_SRC/statusline" "$CLAUDE_DIR/statusline"
echo "  Linked: statusline/"

# global gitignore
GLOBAL_GITIGNORE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
mkdir -p "$(dirname "$GLOBAL_GITIGNORE")"
touch "$GLOBAL_GITIGNORE"
GITIGNORE_PATTERNS=(
  "**/.claude/settings.local.json"
  "**/CLAUDE.local.md"
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
