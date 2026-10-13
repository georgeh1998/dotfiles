---
name: harness-implement
description: plan.json の指定タスク1つだけを、関連するテストも含めて実装する。bin/harness の run フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-implement

引数: `<task-name> <task-id>`

`claude/tasks/<task-name>/` の `spec.md`・`explore.md`・`plan.json` を読み、`plan.json` の `id` が `<task-id>` のタスクだけを実装する。関連するテストも一緒に書く。

## ルール

- 対象タスク以外の変更はしない(他のタスクは後で別に実装される)
- `git commit` はしない(コミットはハーネスが行う)
- ビルド・テストはハーネスが実行するので自分で通す必要はないが、壊れないよう注意する
- 作業ツリーに既存の変更があれば、前回の途中成果として引き継ぐ
- `spec.md` と `explore.md` の規約・パターンに従う
