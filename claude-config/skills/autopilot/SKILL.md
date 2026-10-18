---
name: autopilot
description: spec.mdを起点に、エージェントを活用してコードベース調査→実装計画→(実装→レビュー)×Nを一気通貫で実行する。
disable-model-invocation: true
---

# Autopilot

## 起動方法

```
/autopilot <task-name>
```

## 使用エージェント

| エージェント | 用途 |
|------------|------|
| code-explorer | Explore フェーズでのコードベース調査 |
| planner | Plan フェーズでの実装計画作成 |
| code-reviewer | レビューフェーズでのコードレビュー |

## フロー

### 1. Explore

1. code-explorer エージェントの定義を読み込む
2. Agent ツールでサブエージェントを起動:
   - prompt: code-explorer.md の内容 + spec.md の内容
   - 「spec.md の要件に基づいてコードベースを調査せよ」と指示
3. エージェントの調査結果を `claude/tasks/$ARGUMENT/explore.md` に書き出す

### 2. Plan

1. planner エージェントの定義を読み込む
2. Agent ツールでサブエージェントを起動:
   - prompt: planner.md の内容 + spec.md の内容 + explore.md の内容
   - 「spec.md の要件と explore.md の調査結果に基づいて実装計画を作成せよ」と指示
3. エージェントの計画結果を `claude/tasks/$ARGUMENT/plan.md` に書き出す

### 3. Implement Loop

以下をすべてのタスクが完了するまで繰り返す:

1. **実装** — `claude/tasks/$ARGUMENT/plan.md` のタスクを順番に最後まで実行する。計画に書かれていない変更は加えない

### 4. Review

1. code-reviewer エージェントの定義を読み込む
2. Agent ツールでサブエージェントを起動:
   - prompt: code-reviewer.md の内容 + 「差分をレビューせよ」
   - spec.md の要件充足も確認するよう指示
3. レビュー結果が **Block**（CRITICAL あり）の場合 → 修正して Implement Loop に戻る
4. レビュー結果が **Approve** または **Warning** の場合 → 完了

## ルール

- 全フェーズをユーザー確認なしで連続実行する
- エージェントは Agent ツールで起動し、メインコンテキストを汚さない
- エラー時は停止して状況を報告
