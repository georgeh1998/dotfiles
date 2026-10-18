---
name: harness-implement
description: plan.json の指定サイクル・指定タスク 1 つだけを実装する。bin/harness の implement フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-implement

引数: `<task-name> <cycle> <task-id>`

`claude/tasks/<task-name>/` の `spec.md`・`explore.md`・`plan.json` を読み、`plan.json` の `.cycles[] | select(.n == <cycle>) | .tasks[] | select(.id == <task-id>)` のタスクだけを実装する。修正サイクル(`<cycle>` が 2 以上)なら `logs/cycle<cycle>-input.md` も読み、その原因を直す。

テストの追加、ビルドやテストの実行による確認は、必要だと思う範囲で行ってよい。

## 守ること

- 対象タスク以外の変更はしない(他のタスクは別に実装される)
- `git commit` はしない(harness がする)
- テストを削除・緩和して通さない
- `claude/tasks/<task-name>/local.patch` の変更は commit されない一時的な変更(bypass など)。変更・削除しない
- それ以外の未コミットの変更は、前回の途中成果として引き継ぐ。すでに実装済みなら何も変えなくてよい
- タスクに `local: true` が付いていたら、動作確認のための一時的な変更として実装する。commit されず `local.patch` に記録される
