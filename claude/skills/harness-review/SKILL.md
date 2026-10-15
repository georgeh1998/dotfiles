---
name: harness-review
description: 指定した1つの観点から実装の差分をレビューし、指摘を構造化出力(must / should / nit)で返す。bin/harness の review フェーズから並列に呼ばれる。
disable-model-invocation: true
---

# harness-review

引数: `<task-name> <aspect> <base>`

`claude/tasks/<task-name>/spec.md` と `plan.json` を読み、`git diff <base>..HEAD` の差分を `<aspect>` の観点だけに絞ってレビューする。コードは変更しない。

修正サイクルの後に再実行された場合も、直近の修正だけでなく `<base>..HEAD` の差分全体を見直す。

## 観点

| aspect | 見るもの |
|---|---|
| correctness | ロジックの誤り、エッジケース、エラー処理の漏れ |
| security | 秘密情報の扱い、入力検証、危険なコマンド実行、権限 |
| maintainability | 可読性、重複、命名、既存コードの流儀との一致 |
| tests | テストの有無と質、重要な経路・失敗系の網羅 |
| spec | spec.md の要件・完了条件をすべて満たしているか |

## level の基準

ハーネスは `must` の件数だけで修正のやり直しを判断する。must を乱発するとループが上限まで回り、見逃すと問題が残ったまま完了する。

- **must**: 直さないと完了とは言えないもの
  - spec.md の要件・完了条件を満たしていない
  - バグ(誤った結果、クラッシュ、データ損失、無限ループなど)
  - セキュリティ問題(秘密情報の漏えい、インジェクション、過大な権限)
  - verify では検出できない明らかな破綻(未実装のスタブ・TODO のまま、テストの削除や緩和、要件と無関係な破壊的変更)
- **should**: 直したほうがよいが、無くても要件は満たすもの(設計・可読性の改善、テストの追加、好みの分かれる書き方)
- **nit**: 表記揺れ、コメント、命名の細部など

迷ったら should にする。

## 出力

指定された JSON Schema に従う構造化出力で返す。ファイルは書かない。

- `summary`: この観点での総評(1〜3文)
- `findings`: 指摘ごとに `level`、`file`(リポジトリルートからの相対パス)、`line`(特定できなければ 0)、`problem`、`suggestion`
- 指摘が無ければ `findings` は空配列
