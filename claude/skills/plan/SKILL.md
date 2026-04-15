---
name: plan
description: タスク仕様（claude/tasks/[task-name]/spec.md）と調査結果（claude/tasks/[task-name]/explore.md）に基づいて実装計画を作成する。ユーザーが `/plan [task-name]` と入力したときのみ起動する。
disable-model-invocation: true
---

# Plan スキル

`/plan [task-name]` コマンドに応答して、planner エージェントに実装計画の作成を委譲するスキル。

## ワークフロー

1. `claude/tasks/[task-name]/spec.md` と `claude/tasks/[task-name]/explore.md` の存在確認（explore.md がなければ `/explore` を先に実行するよう促す）
2. planner エージェントの定義を読み込む
3. Agent ツールでサブエージェントを起動:
   - prompt: planner.md の内容 + spec.md の内容 + explore.md の内容
   - 「spec.md の要件と explore.md の調査結果に基づいて実装計画を作成せよ」と指示
4. エージェントの計画結果を `claude/tasks/[task-name]/plan.md` に書き出す
5. タスク数と概要を簡潔にユーザーへ伝える
