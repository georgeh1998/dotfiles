---
name: plan-steps
description: spec.md から実装ステップの一覧を作り、steps.json に書き出す。bin/harness.sh から呼ばれる。
disable-model-invocation: true
model: opus
---

# plan-steps

引数: `<task-name>`

`.agents/<task-name>/spec.md` を読み、必要ならコードを調べて、実装ステップの一覧を `.agents/<task-name>/steps.json` に書く。コードは変更しない。

形式(JSON 配列のみ。他の文章は書かない):

```json
[
  {
    "step_number": 1,
    "commit_message": "コミットメッセージ",
    "summary": "内容を一文で",
    "detail": "内容を詳しく",
    "done": false
  }
]
```

- 1 ステップ = 1 commit。レビューしやすい粒度で、依存順に並べる
- 各ステップの終了時点でビルドやテストを壊さない
- `step_number` は 1 からの連番、`done` はすべて `false`
