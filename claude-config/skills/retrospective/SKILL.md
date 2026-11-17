---
name: retrospective
description: セッションでうまくいかなかったことを md にまとめ、孤児ブランチ `retrospective` に commit する。人間は読まない。
disable-model-invocation: true
---

# retrospective

今回のセッションでうまくいかなかったことがあれば md にまとめる(人間は読まない。なければ何もしない)。
孤児ブランチ `retrospective`(ファイルを何も持たない)がなければ作成し、`<YYYY-MM-DD>-<要約>.md` を追加して commit する。
元のブランチの作業ツリーやインデックスは変えない(`git hash-object` / `git commit-tree` / `git update-ref` などで直接書く)。
