#!/bin/bash
# PreToolUse(Bash) hook: bash-guard.py で危険コマンドを判定し、
# 結果とともに <project>/.claude/bash_history に降順(新しい順)で記録する
# ブロック時は "[BLOCKED]" を付けて記録し、exit 2 で実行を止める

input=$(cat)
command=$(echo "$input" | jq -j '.tool_input.command // empty' | tr '\n' ' ')
[ -z "$command" ] && exit 0

guard_stderr=$(echo "$input" | python3 "$(dirname "$0")/bash-guard.py" 2>&1 >/dev/null)
guard_status=$?

project_dir="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.cwd')}"
history_file="$project_dir/.claude/bash_history"
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

mark=""
[ "$guard_status" -eq 2 ] && mark="[BLOCKED] "

tmp=$(mktemp)
{
  echo "$(date '+%Y-%m-%d %H:%M:%S'): ${mark}${command}"
  cat "$history_file"
} > "$tmp" && mv "$tmp" "$history_file"

if [ "$guard_status" -eq 2 ]; then
  echo "$guard_stderr" >&2
  exit 2
fi
exit 0
