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
cp "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Copied: settings.json"

# skills
rm -rf "$CLAUDE_DIR/skills"
cp -r "$CLAUDE_SRC/skills" "$CLAUDE_DIR/skills"
echo "  Copied: skills/"

# hooks
rm -rf "$CLAUDE_DIR/hooks"
cp -r "$CLAUDE_SRC/hooks" "$CLAUDE_DIR/hooks"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "  Copied: hooks/"

# agents
rm -rf "$CLAUDE_DIR/agents"
cp -r "$CLAUDE_SRC/agents" "$CLAUDE_DIR/agents"
echo "  Copied: agents/"

# statusline
rm -rf "$CLAUDE_DIR/statusline"
cp -r "$CLAUDE_SRC/statusline" "$CLAUDE_DIR/statusline"
chmod +x "$CLAUDE_DIR/statusline/"*.sh
echo "  Copied: statusline/"

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

# git hooks
git -C "$DOTFILES_DIR" config core.hooksPath git/hooks
chmod +x "$DOTFILES_DIR/git/hooks/"*
echo "  Configured: core.hooksPath -> git/hooks"

echo ""
echo "Done. Claude Code is set up."
