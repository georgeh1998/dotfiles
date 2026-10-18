---
name: explore
description: spec.md の要件を実装するために必要な情報をコードベースから調べ、調査結果を Markdown で出力する。bin/harness の explore フェーズから呼ばれる。
disable-model-invocation: true
---

# explore

引数: `<task-name>`

`claude/tasks/<task-name>/spec.md` を読み、実装に必要な情報をリポジトリから調べる。何をどこまで調べるかは任せる。目安は、関連するコードと実行の流れ、従うべき既存のパターン、変更が必要になりそうなファイル、ビルドとテストの方法。

コードは変更しない。調査結果の Markdown だけを最終回答として返す(ファイルは書かない)。
