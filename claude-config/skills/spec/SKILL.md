---
name: spec
description: ユーザーとの対話で要件を決め、spec.md を生成する。ユーザーが `/spec` と入力したときに起動する。
disable-model-invocation: true
---

# spec

ユーザーと対話して要件を決め、`claude/tasks/<task-name>/spec.md` を作る。不明な点がなくなるまで、ユーザーに徹底的に質問する(推測で埋めない。必要ならコードを調べて確かめる)。
spec.md には、目的と背景・要件・完了条件・スコープ外を必ず入れる。
