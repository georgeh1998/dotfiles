---
name: generate-android-journey
description: ユーザーと対話しながらAndroidアプリのjourney XMLを作成する。既存アプリなら実機でUIを探索しながら、新規開発ならコードから推論して作成する。
---

# generate-android-journey

ユーザーと対話しながら journey XML を作成する。

## フロー

### 1. 確認

- 対象アプリ（パッケージ名またはAPKパス）
- テストしたいシナリオ
- 新規開発 or 既存アプリ

### 2. 情報収集

**既存アプリの場合**
1. `android run` でアプリを起動
2. `android screen capture` でスクショ確認
3. `android layout` でUI要素を取得
4. 実際に操作しながらフローを確認し、ユーザーと合意する

**新規開発の場合**
1. `spec.md`、レイアウトXML、Composeコードが存在すれば読む
2. UI要素名・画面遷移をコードから推論する

### 3. journey XML の作成

```xml
<journey name="シナリオ名">
  <description>説明</description>
  <actions>
    <action>メールアドレス入力フィールドにtest@example.comを入力する</action>
    <action>ログインボタンをタップする</action>
    <action>ホーム画面が表示されていることを確認する</action>
  </actions>
</journey>
```

action の書き方：
- 操作系：具体的な要素名と操作（「〇〇ボタンをタップする」）
- 確認系：「〜が表示されていることを確認する」

### 4. 保存

`claude/journeys/<scenario-name>.xml` に保存する。ファイル名はシナリオ名をケバブケースで。

### 5. 動作確認（既存アプリのみ）

作成したjourneyを1回流して全actionがPASSすることを確認する。FAILがあればjourneyを修正する。新規開発の場合はスキップ。

## 注意事項

- `android layout` が失敗する場合は `android screen capture --annotate` にフォールバック
- action は迷わないよう具体的に書く
