---
name: explore
description: タスク仕様（claude/tasks/[task-name]/spec.md）に基づいてコードベースを調査し、調査結果をまとめる。ユーザーが `/explore [task-name]` と入力したときのみ起動する。
subagent: true
allowed_tools:
  - Read
  - WebSearch
  - WebFetch
---

# Explore スキル

`/explore [task-name]` コマンドに応答して、コードベースを調査し結果を記録するスキル。

## ワークフロー

### 1. spec.md を読む

`claude/tasks/[task-name]/spec.md` を読み、以下を把握する：
- **やりたいこと** — 達成したいゴール
- **調べてほしいこと** — 調査すべき具体的なポイント

spec.md が存在しない場合はユーザーに伝えて終了。

### 2. コードベースを調査する

spec.md の調査ポイントに沿って、Read ツールでファイルを読み込みながら調査する。

### 3. explore.md を生成する

`claude/tasks/explore.md` に調査結果を書き出す：

```markdown
# [task-name] 調査結果

## 概要
調査のまとめと主な発見。

## 調査結果

### [調査ポイント1]
- 発見した内容
- 関連ファイルと行番号
- コードのパターンや例

### [調査ポイント2]
...

## 実装への示唆
- 参考にすべき既存パターン
- 変更が必要なファイル
- 注意点・リスク

## 参考ファイル
- `path/to/file.ext` — 説明
```

### 4. 完了報告

調査完了後、主な発見を簡潔にユーザーへ伝える。
