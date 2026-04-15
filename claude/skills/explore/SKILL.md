---
name: explore
description: タスク仕様（claude/tasks/[task-name]/spec.md）に基づいてコードベースを調査し、調査結果をまとめる。ユーザーが `/explore [task-name]` と入力したときのみ起動する。
disable-model-invocation: true
---

# Explore スキル

`/explore [task-name]` コマンドに応答して、code-explorer エージェントにコードベース調査を委譲するスキル。

## ワークフロー

1. `claude/tasks/[task-name]/spec.md` の存在確認（なければ停止）
2. code-explorer エージェントの定義を読み込む
3. Agent ツールでサブエージェントを起動:
   - prompt: code-explorer.md の内容 + spec.md の内容
   - 「spec.md の要件に基づいてコードベースを調査せよ」と指示
4. エージェントの調査結果を `claude/tasks/[task-name]/explore.md` に書き出す
5. 主な発見を簡潔にユーザーへ伝える
