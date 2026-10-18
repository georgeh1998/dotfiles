#!/bin/bash
# PreToolUse(Bash) hook: 実行コマンドを時刻とともに
# <project>/.claude/bash_history に降順(新しい順)で記録する

input=$(cat)
command=$(echo "$input" | jq -j '.tool_input.command // empty' | tr '\n' ' ')
[ -z "$command" ] && exit 0

project_dir="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.cwd')}"
history_file="$project_dir/.claude/bash_history"
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

tmp=$(mktemp)
{
  echo "$(date '+%Y-%m-%d %H:%M:%S'): ${command}"
  cat "$history_file"
} > "$tmp" && mv "$tmp" "$history_file"

exit 0
