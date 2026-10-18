#!/bin/bash
# モデル名を表示するステータスラインスクリプト
# 配置先: ~/.claude/statusline-model.sh
# 設定: settings.json の statusLine で登録
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')

echo "[$MODEL]"
