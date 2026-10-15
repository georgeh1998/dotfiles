---
name: harness-implement
description: plan.json の指定サイクル・指定タスク1つだけを、関連するテストも含めて実装する。bin/harness の implement フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-implement

引数: `<task-name> <cycle> <task-id>`

`claude/tasks/<task-name>/` の `spec.md`・`explore.md`・`plan.json` を読み、`plan.json` の `.cycles[] | select(.n == <cycle>) | .tasks[] | select(.id == <task-id>)` のタスクだけを実装する。関連するテストも一緒に書く。

`<cycle>` が 2 以上なら修正サイクル。`logs/cycle<cycle>-input.md`(verify の失敗ログまたは review の MUST 指摘)も読み、その原因を直す。

## ルール

- 対象タスク以外の変更はしない(他のタスクは後で別に実装される)
- `git commit` はしない(コミットはハーネスが行う)
- ビルド・検証は全タスクの後に verify.sh でまとめて行われる。自分で通す必要はないが、各タスクの終了時点で壊さないよう注意する
- テストを削除・緩和して通すことはしない
- 作業ツリーに既存の変更があれば、前回の途中成果として引き継ぐ
- `spec.md` と `explore.md` の規約・パターンに従う
