---
name: harness-review
description: 指定した1つの観点から、実装の差分をレビューして結果を Markdown で出力する。bin/harness の review フェーズから並列に呼ばれる。
disable-model-invocation: true
---

# harness-review

引数: `<task-name> <aspect> <base>`

`claude/tasks/<task-name>/spec.md` と `plan.json` を読み、`git diff <base>..HEAD` の差分を `<aspect>` の観点だけに絞ってレビューする。コードは変更しない。

## 観点

| aspect | 見るもの |
|---|---|
| correctness | ロジックの誤り、エッジケース、エラー処理の漏れ |
| security | 秘密情報の扱い、入力検証、危険なコマンド実行、権限 |
| maintainability | 可読性、重複、命名、既存コードの流儀との一致 |
| tests | テストの有無と質、重要な経路・失敗系の網羅 |
| spec | spec.md の要件・完了条件をすべて満たしているか |

## 出力

Markdown のみを最終回答として返す(ファイルは書かない)。

- 冒頭に判定: Approve / Warning / Block
- 指摘は重要度(CRITICAL / HIGH / MEDIUM / LOW)、ファイル:行、問題、修正案の順
- 指摘が無ければ「指摘なし」と書く
