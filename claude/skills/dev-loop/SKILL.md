---
name: dev-loop
description: spec.mdを起点に、コードベース調査→実装計画→(実装→ビルド&テスト→レビュー)×N→PR作成を一気通貫で実行する。
disable-model-invocation: true
hooks:
  Stop:
    - matcher: ""
      hooks:
        - type: command
          command: "osascript -e 'display dialog \"Dev Loop が完了しました\" with title \"Claude Code\" buttons {\"OK\"}'"
---

# Dev Loop

`/dev-loop xxx` で起動。`$ARGUMENT` = `xxx`。
`$ARGUMENT` が空ならエラーで停止。

## ファイル

すべて `claude/tasks/` に配置:

| ファイル | 用途 |
|---------|------|
| `claude/tasks/$ARGUMENT/spec.md` | 仕様（事前作成。`build_command` を含む） |
| `claude/tasks/$ARGUMENT/explore.md` | Explore 出力 |
| `claude/tasks/$ARGUMENT/plan.md` | Plan 出力 |

## フロー

### Explore
- `claude/tasks/$ARGUMENT/spec.md` の存在確認（なければ停止）
- `/explore $ARGUMENT` スキルを呼び出し → `claude/tasks/$ARGUMENT/explore.md` 生成

### Plan
- `/plan $ARGUMENT` スキルを呼び出し → `claude/tasks/$ARGUMENT/plan.md` 生成

### Implement Loop

以下をすべてのタスクが完了するまで繰り返す:

1. **実装** — `/implement` スキルを呼び出す
2. **ビルド & テスト** — `build_command` を実行（`skip` なら省略）
3. **成功** → レビューフェーズへ
4. **失敗** → エラー情報を元に 1 へ戻る（最大3回、超えたら停止して報告）

### レビュー
- `git diff main...HEAD` で全差分チェック
- `claude/tasks/$ARGUMENT/spec.md` の要件充足確認
- 問題あれば修正してビルド & テストを再実行

### Ship
- push → `gh pr create --draft`

## ルール

- 全フェーズをユーザー確認なしで連続実行する
- エラー時は停止して状況を報告
