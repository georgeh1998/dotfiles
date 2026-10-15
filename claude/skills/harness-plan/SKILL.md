---
name: harness-plan
description: spec.md と explore.md から実装タスクの一覧を作り、構造化出力で返す。修正モードでは verify 失敗ログや review の MUST 指摘から修正タスクを作る。bin/harness の plan フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-plan

引数: `<task-name> [fix <cycle>]`

コードは変更しない。

## 初回モード(`<task-name>` のみ)

`claude/tasks/<task-name>/spec.md` と `explore.md` を読み、実装タスクの一覧を作る。

## 修正モード(`<task-name> fix <cycle>`)

前のサイクルの後に verify が失敗したか、review で MUST 指摘が出た。次を読み、原因を直すための修正タスクだけを作る。

- `claude/tasks/<task-name>/logs/cycle<cycle>-input.md`(種別、verify の失敗ログまたは MUST 指摘、これまでの commit とサイクル)
- `claude/tasks/<task-name>/plan.json` の `.base` を base として `git log` / `git diff <base>..HEAD`
- `spec.md` と `explore.md`

ルール:

- 原因を直す最小限のタスクだけを返す。完了済みのタスクを計画し直さない
- `id` は 1 から振り直す
- テストを削除・緩和して通すタスクは作らない
- 直す必要が無いと判断した場合でも、空にせず原因の確認・修正タスクを作る(空のタスク一覧はハーネスが停止と扱う)

## タスクの条件(共通)

- 依存順に自然につながる順序にする
- 1タスク = 1コミットとして見やすい粒度にする(差分の目安は約100行。厳密な制限ではない)
- 各タスクに関連するテストを含める(テストだけ後回しにしない)
- ビルド・検証は全タスクの後に verify.sh でまとめて行われる。各タスクの終了時点でビルドやテストを壊さない状態にする

## 各タスクの項目

`id`(1から連番)、`title`、`purpose`(目的)、`files`(対象ファイル)、`test`(テスト内容)、`commit_message`(コミットメッセージ。サイクルをまたいで重複しない1行にする)。

## 出力

指定された JSON Schema に従う構造化出力で返す。ファイルは書かない。
