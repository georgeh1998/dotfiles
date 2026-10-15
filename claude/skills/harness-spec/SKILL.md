---
name: harness-spec
description: ユーザーとの対話で要件とゴール基準(完了条件)を決め、harness 用の spec.md と verify.sh(任意)を生成する。ユーザーが `/harness-spec` と入力したときに起動する。
---

# harness-spec

`/harness-spec` に応答して、`bin/harness` が非対話で回し切るための次の 2 ファイルを作る。

- `claude/tasks/<task-name>/spec.md`: 要件と完了条件
- `claude/tasks/<task-name>/verify.sh`: ゴールの判定方法(`verify()` 関数)。検証が不要なら作らない

## ワークフロー

### 1. やりたいことをヒアリングする

会話しながら要件を引き出す。聞いた内容は都度要約して確認する。

1. **全体像を把握する**: 何を解決したいか、誰が使うか
2. **機能を列挙する**: 必要な機能をリストアップして確認する
3. **詳細を掘り下げる**: 各機能の具体的な動作・エッジケース
4. **スコープを決める**: 今回やらないことを明確にする
5. **ゴール基準を決める**: 「今回のループで何ができたら完了か」を決める
   - 例: `./gradlew assembleDebug testDebugUnitTest` が通るだけ / build → install → スクショ → 画面の確認 / `npm test` と `npm run build`
   - 自動で判定できるコマンドに落とす。リポジトリのビルド・テスト方法を実際に調べて候補を出す
   - 小さなタスクなど検証が不要なら、そう決めて verify.sh を作らない(review だけが品質ゲートになることをユーザーに伝える)

### 2. spec.md を生成する

`claude/tasks/<task-name>/spec.md` に保存する。

```markdown
# <task-name>

## やりたいこと
[1〜2文で目的と背景]

## 機能要件
- 機能1
- 機能2

## 完了条件
- [verify.sh で判定すること。例: `./gradlew assembleDebug testDebugUnitTest` が通る]
- [verify なしの場合は「verify なし(review のみ)」と明記する]

## 調べてほしいこと
- 調査ポイント1

## スコープ外
- 今回やらないこと
```

### 3. verify.sh を生成する(ゴール基準を決めた場合のみ)

下の「verify.sh の規約」と「雛形」に従い、対話で確定したコマンドを当てはめて `claude/tasks/<task-name>/verify.sh` を書く。

### 4. 確認して確定する

1. `bash -n claude/tasks/<task-name>/verify.sh` で構文を確認する
2. 可能なら一度実行する: `(cd <repo-root> && source claude/tasks/<task-name>/verify.sh && verify); echo "exit=$?"`
3. 未実装の現状で想定どおり失敗する(または既存部分だけなら成功する)ことと、失敗ログから原因が読み取れることをユーザーと確認する
4. spec.md と verify.sh を提示し、修正があれば対応して確定する
5. 最後に `harness <task-name>` で実行できることを伝える

## verify.sh の規約

- `verify()` 関数を定義する。成否は終了コードだけで判定される(0 = 成功)
- harness はリポジトリルートを cwd として、サブシェルで `source verify.sh && verify` を実行する
- `source ... && verify` の形で呼ばれるため、関数内で `set -e` を書いても効かない。**各コマンドの末尾に `|| return 1` を付ける**
- 失敗時は原因が分かるログを stdout/stderr に出す。そのまま次の修正サイクルの入力になる(末尾 200 行 / 20KB まで)
- 成果物(スクショ等)は `$HARNESS_ARTIFACTS_DIR`(`claude/tasks/<task>/artifacts/`)に置く
- 使える環境変数: `HARNESS_TASK`、`HARNESS_TASK_DIR`、`HARNESS_ARTIFACTS_DIR`
- 中で `claude -p` を呼んで AI に判定させてもよい。その場合は `--max-budget-usd 1` 程度の上限を付け、最終的に終了コードで返す。判定理由は stdout に出す
- 1 回の harness 実行で verify は最大 9 回(verify ループ 3 回 × review ループ 3 回)走りうる。重い処理は必要最小限にする

## 雛形

### 共通ヘッダ

```bash
# verify.sh: <task-name> の完了条件を判定する
# harness がリポジトリルートを cwd に `source verify.sh && verify` で呼ぶ。0 = 成功
# set -e は効かないので、各コマンドを `|| return 1` で終えること

verify() {
  echo "== verify: $HARNESS_TASK"
  # ここにコマンドを書く
}
```

### CLI / bash

```bash
verify() {
  bash -n bin/mytool || return 1
  local out
  out="$(bin/mytool --sample 2>&1)" || { echo "$out"; return 1; }
  diff <(echo "$out") tests/expected.txt || return 1
}
```

### Web

```bash
verify() {
  npm test || return 1
  npm run build || return 1
}
```

### Android(ビルドとユニットテスト)

```bash
verify() {
  ./gradlew assembleDebug testDebugUnitTest || return 1
}
```

### Android(install → スクショ → AI 判定)

```bash
verify() {
  local shot="$HARNESS_ARTIFACTS_DIR/screen.png" res
  ./gradlew assembleDebug testDebugUnitTest || return 1
  ./gradlew installDebug || return 1
  adb shell am start -W -n com.example.app/.MainActivity || return 1
  sleep 2
  adb exec-out screencap -p >"$shot" || return 1
  res="$("${HARNESS_CLAUDE:-claude}" -p --model sonnet --max-budget-usd 1 \
    --output-format json --tools Read --allowedTools Read \
    --json-schema '{"type":"object","properties":{"pass":{"type":"boolean"},"reason":{"type":"string"}},"required":["pass","reason"]}' \
    <<<"$shot を Read で開き、<期待する画面の条件> を満たすか判定せよ")" || return 1
  echo "$res" | jq -r '.structured_output.reason'
  echo "$res" | jq -e '.structured_output.pass == true' >/dev/null || return 1
}
```
