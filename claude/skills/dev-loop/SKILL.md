---
name: dev-loop
description: spec.mdを起点に、コードベース調査→実装計画→(実装→レビュー→ビルド→コミット)×N→全体レビュー→PR作成を一気通貫で実行する。
disable-model-invocation: true
---

# Dev Loop

`/dev-loop xxx` で起動。`$ARGUMENT` = `xxx`。
`$ARGUMENT` が空ならエラーで停止。

## ファイル

すべて `.claude/tasks/$ARGUMENT/` に配置:

| ファイル | 用途 |
|---------|------|
| spec.md | 仕様（事前作成。`build_command` を含む） |
| research.md | Explore 出力 |
| plan.md | Plan 出力 |
| implementation.md | Implement 進捗ログ |

## フロー

### Explore
- spec.md の存在確認（なければ停止）
- spec.md に基づきコードベース調査 → research.md 生成

### Plan
- spec.md + research.md → plan.md 生成

### Implement Loop
plan.md の各タスクについてループ:

1. **実装** — Read → Edit/Write
2. **セルフレビュー** — `git diff` で差分チェック、問題あれば自動修正
3. **ビルド** — `build_command` 実行（`skip` なら省略）、失敗時は修正→リトライ（最大3回、超えたら停止）
4. **コミット** — 変更ファイルのみ `git add`、1タスク=1コミット

### 全体レビュー
- `git diff main...HEAD` で全差分チェック
- spec.md の要件充足確認、問題あれば修正→ビルド→コミット

### Ship
- push → `gh pr create --draft`

## ルール

- 全フェーズをユーザー確認なしで連続実行する
- エラー時は停止して状況を報告
