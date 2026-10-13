---
name: harness-plan
description: spec.md と explore.md から実装タスクの一覧を作り、構造化出力で返す。bin/harness の plan フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-plan

引数: `<task-name>`

`claude/tasks/<task-name>/spec.md` と `explore.md` を読み、実装タスクの一覧を作る。コードは変更しない。

## タスクの条件

- 依存順に自然につながる順序にする
- 1タスク = 1コミットとして見やすい粒度にする(差分の目安は約100行。厳密な制限ではない)
- 各タスクに関連するテストを含める(テストだけ後回しにしない)
- 各タスクは単体でビルド・テストが通る状態で終わる

## 各タスクの項目

`id`(1から連番)、`title`、`purpose`(目的)、`files`(対象ファイル)、`test`(テスト内容)、`commit_message`(コミットメッセージ)。

## 出力

指定された JSON Schema に従う構造化出力で返す。ファイルは書かない。
