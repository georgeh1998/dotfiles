#!/bin/bash
# ステータスラインのラッパースクリプト
# statusline-context-window.sh と statusline-cost.sh の出力を結合する
input=$(cat)

line1=$(echo "$input" | bash ~/.claude/statusline/statusline-model.sh)
line2=$(echo "$input" | bash ~/.claude/statusline/statusline-context-window.sh)
line3=$(echo "$input" | bash ~/.claude/statusline/statusline-cost.sh)

echo "$line1 | $line2 | $line3"
