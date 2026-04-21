#!/bin/bash
# PostToolUse hook: Bashツール実行のログを ./.claude/log/YYYY-MM-DD.log に追記する。
# フォーマット: "<ISO8601タイムスタンプ> [Bash] <command>"

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

LOG_DIR="./claude/log"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
DATE=$(date +"%Y-%m-%d")

printf '%s [Bash] %s\n' "$TIMESTAMP" "$COMMAND" >> "$LOG_DIR/$DATE.log"
exit 0
