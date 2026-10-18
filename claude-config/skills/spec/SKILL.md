---
name: spec
description: ユーザーとの対話で要件と完了の基準を決め、harness 用の spec.md と verify.sh(必要な場合のみ)を生成する。ユーザーが `/spec` と入力したときに起動する。
---

# spec

ユーザーと対話して、`bin/harness` が非対話で最後まで回せる入力を作る。

- `claude/tasks/<task-name>/spec.md`(必須)
- `claude/tasks/<task-name>/verify.sh`(厳格なゴールが必要なときだけ)

## 進め方

1. やりたいことを聞き、要約して確認する。目的・要件・スコープ外を決める
2. 必要ならコードや実際の挙動を調べる。推測で埋めずに確かめる
3. ゴールの厳しさを決める(下記)
4. spec.md(と verify.sh)を書いて見せ、直して確定する
5. 実行方法を伝える: `harness <task-name>`。verify.sh を作った場合は `harness --verify <task-name>`

## ゴールの決め方

ほとんどのタスクに厳格なゴールは要らない。その場合は verify.sh を作らず、review を品質ゲートにする。迷ったら作らない。

厳格なゴールを作るのは、完成したかどうかを外から機械的に確かめられて、それを AI の自己申告に任せたくないとき(例: ある画面で特定の操作ができるようになる、バグの再現手順が通るようになる)。そのときは次の順で決める。

1. **入口を決める**: 結果を外から観測できる場所。画面なら adb、CLI ならコマンドの実行、HTTP なら curl、ライブラリなら公開 API を呼ぶスクリプト、設定ならツールの実際の挙動
2. **今の状態で実際に叩き、狙った理由で失敗すること(red)をユーザーと確認する**。環境の問題で落ちているだけの verify は意味がない
3. その手順を verify.sh にする。既存のビルドやテストを回帰ガードとして足してもよい

目的の画面にたどり着くためにコードの bypass(ログインを飛ばすなど)が要るなら、harness の実行前に作業ツリーに入れておく。実行前の未コミットの変更は `local.patch` に保存され、作業ツリーに残ったまま commit されない。

implement が書くテストはゴールにしない(自分で書いたテストを自分で通すだけになる)。

## spec.md

形式は自由。ただし次の内容は必ず入れる。

- やりたいこと(目的と背景)
- 要件
- 完了条件(verify.sh がある場合はその内容。無い場合は「verify なし(review のみ)」)
- スコープ外

## verify.sh の規約

harness はリポジトリルートを cwd にして、サブシェルで `source verify.sh && verify` を実行し、終了コードで判定する(0 = 成功)。

- `verify()` 関数を定義する
- この呼ばれ方だと `set -e` は効かない。各コマンドを `|| return 1` で終える
- 失敗したときは原因が分かるログを出す。末尾 200 行が次の修正の入力になる
- 成果物(スクショ等)は `$HARNESS_ARTIFACTS_DIR` に置く。`$HARNESS_TASK` と `$HARNESS_TASK_DIR` も使える
- 1 回の実行で何度も走る(最大 9 回)。毎回同じ状態から始まるようにし、重い処理は最小限にする
- 判定に AI が必要なら `claude -p --max-budget-usd 1` を呼んでもよい。ただし終了コードで返す

書いたら `bash -n` で構文を確認し、可能なら一度実行して red になることを見せる。

```bash
(cd <repo-root> && source claude/tasks/<task-name>/verify.sh && verify); echo "exit=$?"
```

### 例(Android の画面に特定の表示が出ること)

```bash
verify() {
  ./gradlew installDebug || return 1
  adb shell pm clear com.example.app
  adb shell am start -W -d "example://target" || return 1
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null || return 1
  adb pull /sdcard/ui.xml "$HARNESS_ARTIFACTS_DIR/ui.xml" >/dev/null || return 1
  grep -q 'text="期待する表示"' "$HARNESS_ARTIFACTS_DIR/ui.xml" ||
    { echo "期待する表示が画面に無い"; return 1; }
}
```
