---
name: visualize
description: 調査結果（claude/tasks/[task-name]/explore.md）を、テーブルやアスキー図を使った視覚的に分かりやすいレポートに変換する。ユーザーが `/visualize [task-name]` と入力したときのみ起動する。
disable-model-invocation: true
---

# Visualize スキル

`/visualize [task-name]` コマンドに応答して、visualizer エージェントに調査結果の視覚化を委譲するスキル。

## ワークフロー

1. `claude/tasks/[task-name]/explore.md` の存在確認（なければ `/explore` を先に実行するよう促す）
2. visualizer エージェントの定義を読み込む
3. Agent ツールでサブエージェントを起動:
   - prompt: visualizer.md の内容 + explore.md の内容（+ spec.md があればその内容も）
   - 「explore.md の調査結果を視覚的なレポートに変換せよ」と指示
4. エージェントの結果を `claude/tasks/[task-name]/visualize.md` に書き出す
5. レポートの構成（使った図の種類とセクション数）を簡潔にユーザーへ伝える
