---
name: harness-explore
description: spec.md の要件を実装するために必要な情報をコードベースから調べ、調査結果を Markdown で出力する。bin/harness の explore フェーズから呼ばれる。
disable-model-invocation: true
---

# harness-explore

引数: `<task-name>`

`claude/tasks/<task-name>/spec.md` を読み、その要件を実装するために必要な情報を現在のリポジトリから調べる。コードは変更しない。

## 調べること

- 関連するエントリーポイントと実行フロー
- 従うべき既存のパターン・命名規約・再利用できるユーティリティ
- 変更が必要になりそうなファイルと依存関係
- ビルド・テストの方法

## 出力

調査結果の Markdown のみを最終回答として返す(前置きや挨拶は不要。ファイルは書かない)。「主要ファイル」「既存パターン」「新規開発への推奨事項」の見出しを含める。
