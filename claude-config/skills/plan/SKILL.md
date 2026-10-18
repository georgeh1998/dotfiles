---
name: plan
description: spec.md と explore.md から実装タスクの一覧を作り、構造化出力で返す。修正モードでは verify の失敗ログや review の MUST 指摘から修正タスクを作る。bin/harness の plan フェーズから呼ばれる。
disable-model-invocation: true
---

# plan

引数: `<task-name> [fix <cycle>]`

`claude/tasks/<task-name>/` の `spec.md` と `explore.md` を読み、実装タスクの一覧を作る。コードは変更しない。

修正モード(`fix <cycle>`)では、前のサイクルの後に verify が失敗したか、review で MUST 指摘が出ている。`logs/cycle<cycle>-input.md` と、`plan.json` の `.base` からの差分を見て、原因を直すタスクだけを作る。

## 守ること

- 1 タスク = 1 commit になる。レビューしやすい粒度で、依存順に並べる
- 各タスクの終了時点でビルドやテストを壊さない
- テストを削除・緩和して通すタスクは作らない
- 修正モードで空の一覧を返すと harness は停止する。直すべきものがあるなら必ずタスクにする
- `id` は 1 からの連番。`commit_message` はサイクルをまたいで重複させない

## commit しない変更(local)

動作確認のために一時的にコードを bypass する必要がある場合(ログインを飛ばす、値をハードコードするなど)は、それを独立したタスクにして `local: true` を付ける。そのタスクは commit されず、`local.patch` に記録されて作業ツリーにだけ残る。

- 本物の修正と同じ箇所を触らないようにする(重なると commit する変更と分けられず、harness が止まる)
- 要件そのものを骨抜きにする bypass は作らない
- `claude/tasks/<task-name>/local.patch` がすでにあれば、ユーザーが入れた commit しない変更。その箇所は触らない

指定された JSON Schema の構造化出力で返す。ファイルは書かない。
