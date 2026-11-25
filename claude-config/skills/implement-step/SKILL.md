---
name: implement-step
description: steps.json の指定ステップ 1 つだけを実装する。bin/harness.sh から呼ばれる。
disable-model-invocation: true
model: sonnet
---

# implement-step

引数: `<task-name> <step_number>`

`.agents/<task-name>/spec.md` と `steps.json` を読み、`step_number` が一致するステップだけを実装する。

- 対象ステップ以外の変更はしない
- `git commit` はしない(harness がする)
- `steps.json` は変更しない
- テストを削除・緩和して通さない
