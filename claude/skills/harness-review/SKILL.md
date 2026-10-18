---
name: harness-review
description: 指定した 1 つの観点から実装の差分をレビューし、指摘を構造化出力(must / should / nit)で返す。bin/harness の review フェーズから並列に呼ばれる。
disable-model-invocation: true
---

# harness-review

引数: `<task-name> <aspect> <base>`

`claude/tasks/<task-name>/spec.md` を読み、`git diff <base>..HEAD` の差分全体を `<aspect>` の観点でレビューする。コードは変更しない。

`claude/tasks/<task-name>/local.patch` があれば、それは commit されない一時的な変更(動作確認用の bypass など)。レビューの対象ではないが、spec 観点では、その bypass が要件や完了条件を骨抜きにしていないか(bypass のおかげで通っているだけではないか)を確認する。

| aspect | 観点 |
|---|---|
| correctness | ロジックの誤り、エッジケース、エラー処理 |
| security | 秘密情報、入力検証、危険なコマンド実行、権限 |
| maintainability | 可読性、重複、命名、既存コードとの一貫性 |
| tests | テストの有無と質 |
| spec | spec.md の要件と完了条件を満たしているか |

## level

harness は must の件数だけを見て、1 件でもあれば修正をやり直す。

- **must**: 直さないと完了と言えないもの(要件の未達、バグ、セキュリティ問題、スタブや TODO のまま、テストの削除や緩和)
- **should**: 直したほうがよいが、要件は満たしているもの
- **nit**: 細部

迷ったら should にする。

指定された JSON Schema の構造化出力で返す。`line` が特定できなければ 0、指摘が無ければ `findings` は空配列にする。
