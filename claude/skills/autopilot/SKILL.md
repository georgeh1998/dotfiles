---
name: autopilot
description: spec.mdを起点に、エージェントを活用してコードベース調査→実装計画→(実装→ビルド&テスト→レビュー)×N→PR作成を一気通貫で実行する。
disable-model-invocation: true
---

# Autopilot

`/autopilot xxx` で起動。`$ARGUMENT` = `xxx`。
`$ARGUMENT` が空ならエラーで停止。

## ファイル

すべて `claude/tasks/` に配置:

| ファイル | 用途 |
|---------|------|
| `claude/tasks/$ARGUMENT/spec.md` | 仕様（事前作成。`build_command` を含む） |
| `claude/tasks/$ARGUMENT/explore.md` | Explore 出力 |
| `claude/tasks/$ARGUMENT/plan.md` | Plan 出力 |

## 使用エージェント

| エージェント | ファイル | 用途 |
|------------|---------|------|
| code-explorer | `claude/agents/code-explorer.md` | Explore フェーズでのコードベース調査 |
| planner | `claude/agents/planner.md` | Plan フェーズでの実装計画作成 |
| build-error-resolver | `claude/agents/build-error-resolver.md` | ビルド失敗時のエラー解決 |
| code-reviewer | `claude/agents/code-reviewer.md` | レビューフェーズでのコードレビュー |

## フロー

### 1. Explore

1. `claude/tasks/$ARGUMENT/spec.md` の存在確認（なければ停止）
2. `claude/agents/code-explorer.md` を読み込む
3. Agent ツールでサブエージェントを起動:
   - prompt: code-explorer.md の内容 + spec.md の内容
   - 「spec.md の要件に基づいてコードベースを調査せよ」と指示
4. エージェントの調査結果を `claude/tasks/$ARGUMENT/explore.md` に書き出す

### 2. Plan

1. `claude/agents/planner.md` を読み込む
2. Agent ツールでサブエージェントを起動:
   - prompt: planner.md の内容 + spec.md の内容 + explore.md の内容
   - 「spec.md の要件と explore.md の調査結果に基づいて実装計画を作成せよ」と指示
3. エージェントの計画結果を `claude/tasks/$ARGUMENT/plan.md` に書き出す

### 3. Implement Loop

以下をすべてのタスクが完了するまで繰り返す:

1. **実装** — `/implement $ARGUMENT` スキルを呼び出す
2. **ビルド & テスト** — `build_command` を実行（`skip` なら省略）
3. **成功** → レビューフェーズへ
4. **失敗** → `claude/agents/build-error-resolver.md` を読み込み、Agent ツールでサブエージェントを起動してエラーを解決させる（最大3回、超えたら停止して報告）

### 4. Review

1. `claude/agents/code-reviewer.md` を読み込む
2. Agent ツールでサブエージェントを起動:
   - prompt: code-reviewer.md の内容 + 「`git diff main...HEAD` の差分をレビューせよ」
   - spec.md の要件充足も確認するよう指示
3. レビュー結果が **Block**（CRITICAL あり）の場合 → 修正して Implement Loop に戻る
4. レビュー結果が **Approve** または **Warning** の場合 → Ship へ進む

### 5. Ship

- push → `gh pr create --draft`

## ルール

- 全フェーズをユーザー確認なしで連続実行する
- エージェントは Agent ツールで起動し、メインコンテキストを汚さない
- エラー時は停止して状況を報告
