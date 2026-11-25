#!/usr/bin/env bash
# harness.sh <task_name>
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: harness.sh <task_name>" >&2; exit 1; }
TASK=$1
cd "$(git rev-parse --show-toplevel)"
STEPS=".agents/$TASK/steps.json"

# 前段: 未コミットの変更があれば終了
[ -z "$(git status --porcelain)" ] || { echo "local に変更があります" >&2; exit 1; }

# 1. steps.json を作る(すでにあればスキップ)
[ -f "$STEPS" ] || claude -p --dangerously-skip-permissions "/plan-steps $TASK"

# 2. 簡易チェック(JSON 配列で、空でないこと)
jq -e 'type == "array" and length > 0' "$STEPS" >/dev/null || { echo "steps.json が不正です" >&2; exit 1; }

# 3〜6. 未完了のステップを順に実装 → commit → done
while n=$(jq -r 'map(select(.done | not)) | .[0].step_number // empty' "$STEPS"); [ -n "$n" ]; do
  claude -p --dangerously-skip-permissions "/implement-step $TASK $n"
  msg=$(jq -r --argjson n "$n" '.[] | select(.step_number == $n) | .commit_message' "$STEPS")
  jq --argjson n "$n" 'map(if .step_number == $n then .done = true else . end)' "$STEPS" > "$STEPS.tmp"
  mv "$STEPS.tmp" "$STEPS"
  git add -A -- . ':!.agents'
  git commit -m "$msg"
done
