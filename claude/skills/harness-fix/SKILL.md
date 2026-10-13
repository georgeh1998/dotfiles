---
name: harness-fix
description: ビルドまたはテストの失敗ログを読み、原因を最小限の修正で直す。bin/harness の run フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-fix

引数: `<task-name> <task-id>`

直前の実装でビルドまたはテストが失敗した。`claude/tasks/<task-name>/logs/task<task-id>-failure.txt`(失敗ログ)と、`plan.json` の `id` が `<task-id>` のタスクを読み、原因を直す。

## ルール

- 対象タスクの範囲内で最小限の修正をする
- テストを削除・緩和して通すことはしない
- `git commit` はしない(コミットはハーネスが行う)
