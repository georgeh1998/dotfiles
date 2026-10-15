# harness

`claude -p` をフェーズごとに別プロセスで起動する開発ハーネス(`dotfiles/bin/harness`)。
検証の成否判定・ループ制御・コミットは bash が行い、claude には調査・計画・実装・レビュー・解説だけをさせる。

## 使い方

```
/harness-spec      # 対話で claude/tasks/<task>/spec.md と verify.sh(任意)を作る
harness <task>     # 非対話で最後まで回す
```

## フロー

```
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
  最後に walkthrough.md (commit 順の解説書) を生成。上限で停止した場合も生成する
```

ループ回数の数え方:

- **verify ループ**: `verify_attempts` は今の verify ループで `verify()` を実行した回数。1 サイクル(X)につき verify は 1 回。3 回目も失敗したら停止する(X は初回 + 修正 2 回)。review の MUST から新しいサイクルに入るときに 0 に戻る
- **review ループ**: `review_loops` は MUST を理由に X をやり直した回数。2 回やり直した後の review(3 回目)にも MUST があれば停止する
- サイクル数は最大 9(verify ループ 3 × review 3 回)

## verify.sh の規約

`claude/tasks/<task>/verify.sh` に `verify()` を定義する(`/harness-spec` が雛形から作る)。

- 成否は終了コードだけで判定する(0 = 成功)
- リポジトリルートを cwd に、サブシェルで `source verify.sh && verify` を実行する。この形だと関数内の `set -e` は効かないので、各コマンドを `|| return 1` で終える
- 失敗時は原因が分かるログを stdout/stderr に出す。末尾 200 行 / 20KB が次の plan の入力になる
- 成果物(スクショ等)は `$HARNESS_ARTIFACTS_DIR`(`claude/tasks/<task>/artifacts/`)に置く。`HARNESS_TASK` / `HARNESS_TASK_DIR` も使える
- 中で `claude -p` を呼んで AI に判定させてもよい。`--max-budget-usd 1` 程度の上限を付け、最終的に終了コードで返す
- verify.sh が無い場合は verify を skip し、review だけで判定する(`plan.json` の `verify_skipped` と walkthrough.md に残る)

## フェーズとモデル

| フェーズ | スキル | モデル | 予算(USD) | 権限 |
|---|---|---|---|---|
| explore | harness-explore | sonnet | 2 | 読み取り専用ツール |
| plan(初回・修正) | harness-plan | opus | 3 | 読み取り専用ツール + `--json-schema` |
| implement(1 タスクごと) | harness-implement | sonnet | 5 | `--dangerously-skip-permissions` |
| review(5 観点を並列) | harness-review | opus | 2 / 観点 | 読み取り専用ツール + `--json-schema` |
| walkthrough | harness-walkthrough | sonnet | 2 | 読み取り専用ツール |
| verify.sh 内の claude(任意) | - | sonnet 推奨 | 1(verify.sh 側で指定) | verify.sh の作者が決める |

`--max-turns` は help に無いので使わず、`--max-budget-usd` で暴走を防ぐ。review は 5 本並列で起動するため、起動コストも 5 倍かかる。

コスト感(上限値の合計なので実際はかなり小さい): 初回 5 タスク・修正サイクル 2 タスクで 9 サイクル回り切った最悪ケースは、explore 2 + plan 27 + implement 105 + review 30 + walkthrough 2 + verify 内 claude 9 ≒ **$175**。通常(1〜2 サイクル)は explore 2 + plan 3〜6 + implement 25〜35 + review 10〜20 + walkthrough 2 程度が上限。

## review

- 各観点は JSON Schema(`review-schema.json`)による構造化出力で、指摘ごとに `level`(must / should / nit)、`file`、`line`、`problem`、`suggestion` を返す
- bash が `level == "must"` の件数で判定する。構造化出力が取れなかった観点は「MUST 0 件」とはみなさず、失敗として中断する
- MUST の基準は `harness-review` スキルに書いてある(spec 未達、バグ、セキュリティ問題、verify で検出できない明らかな破綻)
- 修正後に再実行される review も、base(最初の HEAD)から現在までの差分全体を見る

## 成果物

`<project>/claude/tasks/<task>/` に保存される。

| パス | 内容 |
|---|---|
| `spec.md` | 要件と完了条件(`/harness-spec`) |
| `verify.sh` | `verify()`(任意) |
| `explore.md` | 調査結果 |
| `plan.json` | 計画と状態(下記) |
| `logs/cycle<N>-input.md` | 修正サイクル N の plan に渡した入力(verify 失敗ログ / MUST 指摘、commit 一覧、サイクル履歴) |
| `logs/cycle<N>-verify.log` | verify の出力 |
| `logs/*.json` `*.err` `*.prompt` | claude の生 JSON・stderr・プロンプト |
| `reviews/cycle<N>-<aspect>.json` | 観点別の構造化レビュー |
| `reviews/cycle<N>.json` | 全観点を結合したもの |
| `review-cycle<N>.md` / `review.md` | 人が読む用のレビュー(サイクルごと / 最新のコピー) |
| `walkthrough.md` | commit 順の解説書 |
| `artifacts/` | verify.sh の成果物 |

`git add -A` は `claude/tasks` を除外するので、これらはコミットされない。

## plan.json

```json
{
  "base": "<最初の HEAD>",
  "phase": "plan|implement|verify|review|walkthrough|done|stopped",
  "cycle": 1,
  "verify_attempts": 0,
  "review_loops": 0,
  "verify_skipped": false,
  "next_trigger": null,
  "stop_reason": null,
  "stop_log": null,
  "cycles": [
    {
      "n": 1,
      "trigger": "initial|verify-fail|review-must",
      "input_file": null,
      "tasks": [{"id": 1, "title": "", "purpose": "", "files": [], "test": "",
                 "commit_message": "", "status": "pending|done|nochange", "sha": null}],
      "verify": {"ok": true, "attempt": 1, "log": "logs/cycle1-verify.log"},
      "review": {"must": 0, "should": 1, "nit": 0, "file": "review-cycle1.md", "json": "reviews/cycle1.json"}
    }
  ]
}
```

- 別の state ファイルは作らない。更新は常に tmp に書いてから mv する
- `cycles[].verify` は verify.sh が無い場合 `{"skipped": true}`
- 旧形式(最上位に `tasks` だけがあるもの)は読めない。消してから再実行する

## 再開

同じ `harness <task>` を再実行すると `plan.json` の `phase` から続ける。

| 落ちた位置 | 再開時 |
|---|---|
| explore 中 | explore.md が無いので explore からやり直す |
| 初回 plan 中 | plan.json が無いので初回 plan からやり直す |
| 修正 plan 中 | `logs/cycle<N>-input.md` を入力に plan をやり直す |
| implement 中 | 現サイクルの最初の pending タスクから。作業ツリーの変更は引き継ぐ |
| commit 直後〜status 更新前 | HEAD の subject がそのタスクの commit_message と一致し、sha が未記録なら done にして再実装しない |
| verify 中 | 回数は結果が出てから数えるので、同じ verify をやり直す |
| review 中 | `reviews/cycle<N>-<aspect>.json` がある観点は飛ばし、欠けた観点だけ実行する |
| walkthrough 中 | walkthrough をやり直す |
| 停止(stopped) | claude を呼ばず、停止理由・ログ・解説書の場所を表示して終了する |
| 完了(done) | 完了済みと表示して終了する |

停止時は「どのループで何回目に、何が原因で止まったか」とログの場所を表示する。手で直してから続けるには `plan.json` を編集する。

```bash
# verify ループで停止した場合
jq '.phase="verify" | .verify_attempts=0 | .stop_reason=null | .stop_log=null' plan.json > plan.json.tmp && mv plan.json.tmp plan.json
# review ループで停止した場合(そのサイクルの review 結果を消して再レビューさせる)
rm reviews/cycle<N>-*.json
jq '.phase="review" | .review_loops=0 | .stop_reason=null | .stop_log=null' plan.json > plan.json.tmp && mv plan.json.tmp plan.json
```

注意:

- 停止後に手で直した変更は未コミットのまま、次にコミットされるタスクに混ざる
- `git add -A` は `claude/tasks` 以外をすべて含む。実行前に作業ツリーをきれいにしておく
- implement で変更が無かったタスクは `nochange` として警告し、先へ進む(後の verify / review で検出する)
- 修正 plan が空のタスク一覧を返した場合は停止する

## テスト

```
claude/harness/tests/run-tests.sh      # KEEP=1 で一時ディレクトリを残す
```

`HARNESS_CLAUDE` 環境変数で claude コマンドを `tests/fake-claude` スタブに差し替え、課金なしでループ回数・skip・再開を確認する(タスクごとに verify が走らないこと、verify 上限 3 回、verify.sh なしの skip、review 上限 2 回、walkthrough.md の生成、implement 中の中断からの再開、停止後の再実行)。

## 未検証事項

- `--dangerously-skip-permissions` 使用時に settings.json の deny ルールが効くか
- `claude -p` 失敗時の終了コードと `.is_error` の関係(両方を見て判定している)
- `--max-budget-usd` を超えたときの挙動(review の構造化出力が欠けた場合は失敗として扱う)
- 本物の claude での通し実行(手動スモークテスト)
