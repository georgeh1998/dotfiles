---
name: harness-walkthrough
description: harness が作った commit を古い順に「何を・なぜ・どう確認したか」で解説する walkthrough.md の本文を出力する。bin/harness の walkthrough フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-walkthrough

引数: `<task-name>`

harness の実行結果を、人が後から読んで追える解説書にまとめる。コードは変更しない。

## 読むもの

- `claude/tasks/<task-name>/spec.md`
- `claude/tasks/<task-name>/plan.json`
  - `.base`、`.cycles[]`(`n`、`trigger`、`tasks[]` の `title`/`purpose`/`test`/`status`/`sha`、`verify`、`review`)
  - `.verify_skipped`、`.stop_reason`、`.stop_log`
- `git log --reverse <base>..HEAD` と、各 commit の `git show <sha>`
- 最新サイクルの verify ログ(`plan.json` の `.cycles[-1].verify.log`、`claude/tasks/<task-name>/` からの相対パス)の末尾
- 最新サイクルの `claude/tasks/<task-name>/reviews/cycle<N>.json`(あれば)
- 修正サイクルの入力 `logs/cycle<N>-input.md`(あれば)

## 出力

Markdown のみを最終回答として返す(前置きは不要。ファイルは書かない)。次の見出しを含める。

1. `# <task-name> walkthrough`
2. `## 概要`: 何を実現したか(2〜4文)
3. `## 結果`: 完了か停止か。停止した場合は `stop_reason`(どのループで何回目に何が原因で止まったか)とログの場所。サイクル数と各サイクルの trigger
4. `## commit ごとの解説`: base..HEAD の commit を古い順に。各 commit について
   - 見出しは `### <short sha> <subject>`(cycle 番号と trigger を併記)
   - 何を: 変更内容の要点
   - なぜ: 対応するタスクの purpose、修正サイクルなら直した verify 失敗や MUST 指摘
   - どう確認したか: タスクの test、その後の verify / review の結果
5. `## 最終的な verify の結果`: 成功 / 失敗とログの要点。verify.sh が無かった場合は「verify なし(verify.sh が無いため skip。review のみで判定)」と明記する
6. `## 残った指摘`: 最新 review の SHOULD / NIT(停止した場合は MUST も)を箇条書き。無ければ「なし」
