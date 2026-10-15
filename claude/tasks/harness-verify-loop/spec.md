# harness-verify-loop

## やりたいこと
`bin/harness` はタスクごとに build/verify を回しており、安全だが時間とコストの無駄が大きい。さらに検証の定義を事前に手で用意する必要があり、最後に review.md が残るだけで「問題あり」の状態で終わることもある。
そこで、spec 作成の時点でゴールの判定方法(`verify.sh`)を決めておき、harness は「実装 → まとめて検証 → レビュー → MUST な指摘が無くなるまで修正」を上限付きで自走するようにする。

## 全体フロー

```
/harness-spec (対話)
  └─ claude/tasks/<task>/spec.md + verify.sh(任意) を生成

harness <task>
  explore (初回のみ)
  X = plan → implement × N   (タスクごとに commit。build/verify はしない)

  [verify ループ]  最大 3 回  (verify.sh が無ければ skip して review へ)
    X → verify()
      失敗 → 失敗ログを入力に X
      成功 → review へ
  [review ループ]  最大 2 回
    review → MUST な指摘あり → 指摘を入力に X → verify ループ → review
           → MUST なし → 完了
  最後に walkthrough.md (commit 順の解説書) を生成
```

## 機能要件

### 1. harness-spec スキル(新規: `claude/skills/harness-spec/SKILL.md`)
- `/harness-spec` で起動し、spec-writer と同様の対話で要件を詰める
- 対話の中で「今回のループで何ができたら完了か」(ゴール基準)をユーザーと決める
  - 例: `./gradlew assembleDebug testDebugUnitTest` だけ / build → install → screenshot → 確認 など
- 次の 2 ファイルを生成する
  - `claude/tasks/<task>/spec.md`: 既存の spec-writer の形式に「完了条件」セクションを追加
  - `claude/tasks/<task>/verify.sh`: `verify()` 関数を定義する bash スクリプト(任意)
- 小さなタスクなど検証が不要な場合は、対話の中でそう決めて verify.sh を作らない。その場合は spec.md の完了条件に「verify なし(review のみ)」と明記する
- verify.sh を生成した場合は、可能ならその場で一度実行し、現状(未実装)で想定どおり失敗/成功することをユーザーと確認する

### 2. verify.sh の規約
- `verify()` を定義する。成否は終了コードだけで判定する(0 = 成功)
- リポジトリルートを cwd として、サブシェルで source → `verify` 実行される
- 中で `claude -p` を呼んで AI に判定させてもよい(スクショを見て判定など)。その場合も最終的に終了コードで返す
- 失敗時は原因が分かるログを stdout/stderr に出す(次の X の入力になる)
- 成果物(スクショ等)は `claude/tasks/<task>/artifacts/` に置く慣習とする

### 3. bin/harness の変更
- `.harness/config.sh` と `build()` を廃止し、`claude/tasks/<task>/verify.sh` の `verify()` だけを使う
- verify.sh が無い場合は verify ループを skip し、X の後そのまま review へ進む(エラーにしない)。skip したことはログと walkthrough.md に残す
- run フェーズからタスクごとの build/verify と `harness-fix` 呼び出しを削除する。各タスクは実装 → commit のみ
- X(plan → implement × N)を「サイクル」として繰り返せるようにする
  - 初回の plan: spec.md + explore.md から計画
  - 2 回目以降の plan: spec.md + explore.md + 「前回の verify 失敗ログ」または「review の MUST 指摘」+ これまでの commit 一覧を入力に、修正タスクを計画
- verify ループ: 上限 3 回。超えたら状態を残して停止
- review ループ: 上限 2 回(MUST 指摘による X のやり直し回数)。超えたら MUST 指摘を残して停止
- review が修正後に再実行される場合は、base(最初の HEAD)から現在までの差分全体を見直す
- 状態(サイクル番号、verify/review ループの回数、現在のフェーズ、各サイクルのタスク一覧と status)は plan.json に追記して管理する。別の state ファイルは作らない
- 再開: 同じコマンドを再実行すると、plan.json の状態から途中のサイクル・フェーズの続きを実行する
- 停止時は「どのループで何回目に、何が原因で止まったか」とログの場所を表示する
- macOS 標準の bash 3.2 で動くこと(既存の制約を維持)

### 4. review の構造化
- `harness-review` の出力を JSON Schema による構造化出力にする
  - 各指摘に `level`(must / should / nit)、`file`、`line`、`problem`、`suggestion`
- MUST の判定は bash が `level == "must"` の件数で行う
- 人が読む用の review.md も観点をまとめて 1 ファイルで残す(サイクルごとに上書きか追記かは計画時に決める)
- 「MUST とは何か」の基準をスキルに明記する(spec の要件未達、バグ、セキュリティ問題、verify では検出できない明らかな破綻 など)

### 5. walkthrough.md(解説書)
- 完了時(および上限で停止した時)に `claude/tasks/<task>/walkthrough.md` を生成する
- base..HEAD の commit を古い順に並べ、各 commit について「何を・なぜ・どう確認したか」を説明する
- 最終的な verify の結果、残った SHOULD/NIT の指摘、停止した場合はその理由も含める
- 生成は claude(sonnet 程度)に任せ、新規スキル `harness-walkthrough` を用意する

### 6. 不要になるものの整理
- `claude/skills/harness-fix` を削除(または X に統合)
- `claude/harness/README.md` を新フローに合わせて更新

## 完了条件
- `bash -n bin/harness` が通る
- 適当なサンプルリポジトリで `/harness-spec` → `harness <task>` を通し、
  - タスクごとに build/verify が走らないこと
  - verify 失敗時に X がやり直され、上限 3 回で停止すること
  - verify.sh が無い場合に verify が skip され、review まで進むこと
  - review に MUST が出たら X がやり直され、上限 2 回で停止すること
  - 完了時に walkthrough.md が生成されること
  を確認できる

## 調べてほしいこと
- 2 回目以降の plan に渡す入力の形(失敗ログの量の上限、MUST 指摘の渡し方)と、harness-plan スキルを初回/修正で分けるべきか
- 状態を追記した plan.json の具体的な構造(サイクルごとのタスクの持ち方)と、各フェーズの途中で落ちた場合の再開時の挙動
- サイクルごとの review の履歴の残し方(上書き・連番)
- 各フェーズの model と `--max-budget-usd` の配分(verify 内で claude を呼ぶ場合も含めた総コスト感)
- verify.sh の雛形をどこまで harness-spec が用意するか(Android / Web / CLI などの典型例)

## スコープ外
- 既存の `spec-writer` スキルの変更(harness 用は harness-spec に分ける)
- `.harness/config.sh` との後方互換
- 複数タスクの並列実行や worktree 連携
- verify の途中経過を対話的に確認する仕組み(harness は非対話で回し切る)
