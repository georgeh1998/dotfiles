---
name: spec
description: ユーザーとの対話で要件を決め、spec.md を生成する。ユーザーが `/spec` と入力したときに起動する。
disable-model-invocation: true
model: sonnet
---

# spec

ユーザーと一緒に仕様を定義し、`.agents/<task-name>/spec.md` を作る。不明な点がなくなるまで、ユーザーに徹底的に質問する(推測で埋めない。必要ならコードを調べて確かめる)。
spec.md には、目的と背景・要件・完了条件・スコープ外を必ず入れる。書き終えたら、内容に矛盾がないか見直して直す。
