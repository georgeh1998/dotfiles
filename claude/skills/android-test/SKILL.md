---
name: android-test
description: journey XMLを実行してAndroidアプリを検証する。各actionごとにスクショを保存し、結果をJSONレポートに記録する。
---

# android-test

`/android-test <task-name> [--journey=<path>]`

## フロー

1. journey XMLを読み込む（`--journey` 指定があればそのパス、なければ `claude/journeys/` 配下を検索）
2. `android run` でアプリを起動
3. `<action>` を順番に実行する

### 各actionの実行

1. `android layout` でUI要素を取得して操作または確認
2. `android screen capture -o claude/tasks/<task-name>/screenshots/<N>_<summary>.png` でスクショ保存
3. スクショを視覚的に確認する

`android layout` が失敗する場合は `android screen capture --annotate` → `android screen resolve` にフォールバック。

操作後にコンテンツが変化しない場合は `android layout --diff` で数秒待って確認し、変化がなければFAIL。

### 要素が見つからない場合

- 類似要素あり → journeyの記述ミスの可能性。コメントに記載してFAIL
- 類似要素なし → 実装のバグ。コメントに記載してFAIL

### スクショ命名

`01_launch.png`、`02_tap-login-button.png` のように2桁ゼロ埋め+ケバブケース。

## レポート

全action完了後、`claude/tasks/<task-name>/test-report.json` に保存：

```json
{
  "journey": "ジャーニー名",
  "timestamp": "2026-05-22T10:00:00",
  "result": "PASSED",
  "results": [
    {
      "action": "ログインボタンをタップする",
      "status": "PASSED",
      "screenshot": "screenshots/02_tap-login-button.png",
      "commands": ["adb shell input tap 540 960"]
    },
    {
      "action": "ホーム画面が表示されていることを確認する",
      "status": "FAILED",
      "screenshot": "screenshots/03_verify-home-screen.png",
      "commands": [],
      "comment": "ホーム画面の要素が見つからない。設定画面が表示されている。"
    }
  ]
}
```

アプリクラッシュ/フリーズは即座にFAIL。

## 操作の注意点

- テキスト入力前に対象フィールドが `focused` 状態であることを確認する
- スクロールは `adb shell input swipe` の5番目の引数でゆっくり実行する
- `android layout` の `center` 座標を使って `adb shell input tap` を実行する
