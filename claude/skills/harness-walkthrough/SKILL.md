---
name: harness-walkthrough
description: harness が作った commit を古い順に「何を・なぜ・どう確認したか」で解説する walkthrough.md の本文を出力する。bin/harness の walkthrough フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-walkthrough

引数: `<task-name>`

harness の実行結果を、人が後から読んで追える解説書にまとめる。コードは変更しない。

材料は `claude/tasks/<task-name>/` にある。`spec.md`、`plan.json`(`.base`、`.cycles[]`、`.stop_reason`)、`logs/`(verify のログ、修正サイクルの入力)、`reviews/`、それと `git log --reverse <base>..HEAD` の各 commit。

## 含める内容

- 何を実現したか
- 結果: 完了か停止か。停止した場合はその理由。サイクルごとに何がきっかけでやり直したか
- commit ごとの解説を古い順に: 何を・なぜ・どう確認したか
- verify の結果。skip した場合(`cycles[].verify.skipped`)は「verify なし(review のみで判定)」と書く
- 最新の review で残った指摘
- `local.patch` があれば、commit せずに作業ツリーに残した変更の内容と理由(status が `local` のタスク)。外し方は `git apply -R claude/tasks/<task-name>/local.patch`

Markdown だけを最終回答として返す(ファイルは書かない)。
