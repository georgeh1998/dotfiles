#!/bin/bash
# Dotfiles setup script
# このスクリプトだけ実行すれば、zsh / PATH / Claude Code の設定がすべて反映されます。
#   使い方: ./setup.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/claude"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# ---------------------------------------------------------------------------
# zsh / PATH
# ---------------------------------------------------------------------------
echo ""
echo "[zsh]"

ZSHRC="$HOME/.zshrc"

# 指定の行が ~/.zshrc になければ追記する
add_line_once() {
  local line="$1"
  if grep -qF "$line" "$ZSHRC" 2>/dev/null; then
    echo "  Skipped: already in ~/.zshrc: $line"
  else
    echo "$line" >> "$ZSHRC"
    echo "  Added to ~/.zshrc: $line"
  fi
}

add_line_once "source $DOTFILES_DIR/zsh/zshrc"
add_line_once "export PATH=\"$DOTFILES_DIR/bin:\$PATH\""

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
echo ""
echo "[Claude Code]"

mkdir -p "$CLAUDE_DIR"

# settings.json
ln -sf "$CLAUDE_SRC/settings.json" "$CLAUDE_DIR/settings.json"
echo "  Linked: settings.json"

# skills: claude/skills 直下のうち SKILL.md を含むディレクトリだけを ~/.claude/skills/ に1つずつリンクする
# 同名が既にあれば上書きする（隠しファイル/ディレクトリ、SKILL.md の無いものは対象外）
mkdir -p "$CLAUDE_DIR/skills"
for src in "$CLAUDE_SRC"/skills/*; do
  [ -f "$src/SKILL.md" ] || continue
  name="$(basename "$src")"
  dest="$CLAUDE_DIR/skills/$name"
  rm -rf "$dest"
  ln -s "$src" "$dest"
  echo "  Linked: skills/$name"
done

# hooks
rm -rf "$CLAUDE_DIR/hooks"
ln -sfn "$CLAUDE_SRC/hooks" "$CLAUDE_DIR/hooks"
echo "  Linked: hooks/"

# agents
rm -rf "$CLAUDE_DIR/agents"
ln -sfn "$CLAUDE_SRC/agents" "$CLAUDE_DIR/agents"
echo "  Linked: agents/"

# statusline
rm -rf "$CLAUDE_DIR/statusline"
ln -sfn "$CLAUDE_SRC/statusline" "$CLAUDE_DIR/statusline"
echo "  Linked: statusline/"

# global gitignore
echo ""
echo "[global gitignore]"

GLOBAL_GITIGNORE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
mkdir -p "$(dirname "$GLOBAL_GITIGNORE")"
touch "$GLOBAL_GITIGNORE"

GITIGNORE_PATTERNS=(
  "**/.claude/settings.local.json"
  "**/CLAUDE.local.md"
  "**/claude/tasks/**"
  "**/.claude/bash_history"
)
for pattern in "${GITIGNORE_PATTERNS[@]}"; do
  if ! grep -qF "$pattern" "$GLOBAL_GITIGNORE"; then
    echo "$pattern" >> "$GLOBAL_GITIGNORE"
    echo "  Added: $pattern"
  else
    echo "  Already present: $pattern"
  fi
done

echo ""
echo "Done."
