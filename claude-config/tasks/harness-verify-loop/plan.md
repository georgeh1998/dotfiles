# harness-verify-loop 実装計画

## 設計判断のサマリ

### ループ回数の数え方
- **verify ループ（MAX_VERIFY=3）**: `verify_attempts` は「今の verify ループで verify() を実行した回数」。1 サイクル（X）につき verify は 1 回。失敗して `verify_attempts < 3` なら修正サイクルへ、3 回目も失敗したら停止。常に失敗なら「X 3 回、verify 3 回」で停止。review MUST から新サイクルを始めるとき `verify_attempts=0` に戻す。
- **review ループ（MAX_REVIEW_LOOPS=2）**: `review_loops` は「MUST を理由に X をやり直した回数」。`review_loops < 2` ならやり直し（+1）、`review_loops == 2` で 3 回目の review にも MUST があれば停止。常に MUST なら「review 3 回、cycles 3、review_loops=2」で停止。

### (1) 修正 plan の入力
- 修正サイクル N の直前に bash が `logs/cycle<N>-input.md` を書き出す（`write_fix_input`、冪等）。
  - `種別: verify-fail | review-must`
  - verify-fail: `tail -n 200 <log> | tail -c 20000`
  - review-must: `level=="must"` のみ jq で箇条書き（`- [aspect] file:line` / `問題:` / `修正案:`）、`head -c 20000`
  - `git log --oneline --reverse <base>..HEAD`
  - これまでのサイクル履歴（n、trigger、タスク title）
- harness-plan は 1 つのまま引数で分岐（`/harness-plan <task>` / `/harness-plan <task> fix <N>`）。修正モードは修正タスクのみ（id は 1 から）。空なら停止。
- `base` は初回 plan で 1 回だけ設定。

### (2) plan.json の構造
```json
{
  "base": "<sha>",
  "phase": "implement|plan|verify|review|walkthrough|done|stopped",
  "cycle": 1,
  "verify_attempts": 0,
  "review_loops": 0,
  "verify_skipped": false,
  "next_trigger": null,
  "stop_reason": null,
  "stop_log": null,
  "cycles": [
    { "n": 1, "trigger": "initial|verify-fail|review-must", "input_file": null,
      "tasks": [ { "id": 1, "title": "", "purpose": "", "files": [], "test": "", "commit_message": "",
                   "status": "pending|done|nochange", "sha": null } ],
      "verify": null,
      "review": null }
  ]
}
```
- `cycles[i].verify`: `{"ok":bool,"attempt":k,"log":"logs/cycleN-verify.log"}` または `{"skipped":true}`
- `cycles[i].review`: `{"must":n,"should":n,"nit":n,"file":"review-cycleN.md","json":"reviews/cycleN.json"}`
- 旧形式（`.tasks` のみ）は die。
- 書き込みは tmp→mv。最後の要素は `(.cycles|length-1) as $c | .cycles[$c]...` で更新（負インデックス代入は避ける）。

**再開**（各フェーズの最後に次の phase を書き込み、再開時は phase で分岐）

| 落ちた位置 | 再開時 |
|---|---|
| explore 中 | explore.md が無いので再実行 |
| 初回 plan 中 | plan.json が無いので再実行 |
| 修正 plan 中（phase=plan） | `next_trigger` と `cycle+1` から input を特定して再実行 |
| implement 中 | 現サイクルの最初の pending から。作業ツリーは引継ぎ |
| commit 直後〜status 更新前 | `recover_committed_task`: HEAD subject == commit_message かつ sha 未記録なら done |
| verify 中 | attempts は結果後に加算するので再実行 |
| review 中 | `reviews/cycle<N>-<aspect>.json` がある観点は skip |
| walkthrough 中 | 再実行 |
| stopped | 停止理由・ログ・手動再開手順を表示して exit 1 |
| done | 完了済みと表示して exit 0 |

### (3) review 履歴
- 生ログ `logs/cycle<N>-review-<aspect>.json`、観点別 `reviews/cycle<N>-<aspect>.json`、結合 `reviews/cycle<N>.json`、人用 `review-cycle<N>.md` + 最新コピー `review.md`。

### (4) model と予算
| フェーズ | model | budget | 権限 |
|---|---|---|---|
| explore | sonnet | 2 | readonly |
| plan（初回・修正） | opus | 3 | readonly + schema |
| implement（タスクごと） | sonnet | 5 | `--dangerously-skip-permissions` |
| review（5 観点並列） | opus | 2/観点 | readonly + schema |
| walkthrough | sonnet | 2 | readonly |
| verify.sh 内 claude | sonnet | 1（verify.sh 側規約） | - |

最大 9 サイクル。上限合算の最悪値は約 $175（実コストはかなり小さい）。

### (5) verify.sh 雛形
- harness-spec に「共通ヘッダ + 典型例 4 種」（CLI / Web / Android unit / Android + AI 判定）。
- 規約: `source && verify` 形式で関数内 `set -e` は効かない → 各行 `|| return 1`。成果物は `$HARNESS_ARTIFACTS_DIR`。AI 判定は `"${HARNESS_CLAUDE:-claude}" -p --model sonnet --max-budget-usd 1 --json-schema ...`。

### (6) テスト用差し替え
- `CLAUDE_BIN="${HARNESS_CLAUDE:-claude}"`、`claude/harness/tests/fake-claude` と `run-tests.sh` を追加。

### その他
- 差分なし implement は `status:"nochange"` で警告して続行。
- verify.sh source 時に `HARNESS_TASK` / `HARNESS_TASK_DIR` / `HARNESS_ARTIFACTS_DIR` を export。
- 各フェーズはサブシェルで実行。
- `claude/claude/`（誤配置）は範囲外。ユーザー確認後に手動で。

---

## タスク

### 1. claude コマンドの差し替えフック
- 変更: `bin/harness`
- `CLAUDE_BIN="${HARNESS_CLAUDE:-claude}"` 追加。`check_deps` は `for cmd in "$CLAUDE_BIN" jq git`、メッセージ「`$cmd コマンドが見つからない (HARNESS_CLAUDE で差し替え可)`」。`run_claude` を `"$CLAUDE_BIN" -p` に。
- 確認: `/bin/bash -n bin/harness`、`HARNESS_CLAUDE=/nonexistent bin/harness x` がエラー。

### 2. plan.json 新形式・状態ヘルパー・plan フェーズ
- 変更: `bin/harness`、`claude/skills/harness-plan/SKILL.md`
- bin/harness:
  - `MAX_VERIFY=3`、`MAX_REVIEW_LOOPS=2`、`FIX_LOG_LINES=200`、`FIX_INPUT_BYTES=20000`。`PHASES` 削除。
  - `plan_get <filter> [args]`、`plan_update <filter> [args]`（tmp→mv、失敗で die）、`set_phase`、`cur_cycle`、`check_plan_format`（`has("cycles")`）。
  - `cmd_plan` → `plan_initial`（label `cycle1-plan`）:
    ```
    jq --arg base "$base" '.structured_output.tasks as $t | {base:$base, phase:"implement", cycle:1, verify_attempts:0, review_loops:0, verify_skipped:false, next_trigger:null, stop_reason:null, stop_log:null, cycles:[{n:1, trigger:"initial", input_file:null, tasks:($t|map(.+{status:"pending",sha:null})), verify:null, review:null}]}'
    ```
  - `phase_plan`（修正）: `n=cycle+1`、`trigger=.next_trigger`、input 無ければ die。`/harness-plan $TASK fix $n`、label `cycle$n-plan`。tasks 空なら `stop_with`。それ以外:
    ```
    plan_update '.cycles += [{n:$n, trigger:$t, input_file:$f, tasks:($tasks|map(.+{status:"pending",sha:null})), verify:null, review:null}] | .cycle=$n | .next_trigger=null | .phase="implement"' ...
    ```
  - `run_all` → `drive`（explore / plan_initial の後、`while :; case phase in ...`）。`run_phase` は `("$1")` で、失敗時「`<phase>` で中断。直してから `harness $TASK` で再開」。
- harness-plan/SKILL.md: 引数 `<task-name> [fix <cycle>]`。修正モード節（入力: `logs/cycle<cycle>-input.md`、`git log/diff base..HEAD`、spec、explore。最小限の修正タスクのみ、id 1 から、テスト削除・緩和禁止）。共通規約「各タスク終了時点で壊さない」。
- 確認: `/bin/bash -n`、jq 式の単体実行。

### 3. implement フェーズと旧仕組みの削除
- 変更: `bin/harness`、`claude/skills/harness-implement/SKILL.md`、`claude/skills/harness-fix/`（削除）
- 削除: `check_config`、`CONFIG`、`MAX_FIX`、`run_checks`、`report_stop`、`cmd_run`、fix ループ、final checks、旧 `next_task`/`task_field`/`set_status`。
- 新ヘルパー（最後のサイクル対象）: `next_task`、`task_field <id> <field>`（`--argjson id` / `--arg f`、`.[$f]`）、`mark_task <id> <status> <sha>`、`recover_committed_task <id>`。
- `commit_task <id>`: 変更なしなら警告 + `nochange`、ありなら commit + `done <short sha>`。
- `phase_implement`: 汚れ警告、ループ（next_task 空 → `set_phase verify`）、recover、`/harness-implement $TASK $n $id`（label `cycle$n-task$id-implement`）、commit。
- harness-implement/SKILL.md: 引数 `<task-name> <cycle> <task-id>`、cycle ≥2 なら input を読む、ビルド・検証は全タスク後に verify.sh でまとめて行われる旨。
- 確認: `/bin/bash -n`、`harness-fix|run_checks|CONFIG|build\(\)` が残らない。

### 4. verify フェーズと停止処理
- 変更: `bin/harness`
- main で `VERIFY`、`ARTIFACTS`。`check_verify_file`（あれば source して `declare -F verify`）。
- `run_verify <log>`:
  ```
  mkdir -p "$ARTIFACTS"
  ( cd "$ROOT" && export HARNESS_TASK="$TASK" HARNESS_TASK_DIR="$TASK_DIR" HARNESS_ARTIFACTS_DIR="$ARTIFACTS" && source "$VERIFY" && verify ) >"$log" 2>&1
  ```
- `write_fix_input <n> <trigger> <src>`（tmp→mv）。
- `stop_with <reason> <log>`: `stop_reason/stop_log` を設定し phase=walkthrough。
- `phase_verify`: verify.sh 無し → skip 記録、phase=review。あれば `a=attempts+1`、`logs/cycle$n-verify.log`、結果記録。ok → review、失敗かつ `a>=MAX_VERIFY` → `stop_with "verify ループ $a/$MAX_VERIFY 回目 (cycle $n) で verify が失敗"`、他 → `write_fix_input`、`next_trigger=verify-fail`、phase=plan。
- `report_stopped`: 理由、ログ、walkthrough パス、手動再開手順を表示し exit 1。
- 確認: `/bin/bash -n`、タスク 9 のテスト。

### 5. review の構造化と review ループ
- 変更: `claude/harness/review-schema.json`（新規）、`claude/skills/harness-review/SKILL.md`、`bin/harness`
- review-schema.json:
  ```json
  {"type":"object","properties":{"summary":{"type":"string"},"findings":{"type":"array","items":{"type":"object","properties":{"level":{"type":"string","enum":["must","should","nit"]},"file":{"type":"string"},"line":{"type":"integer"},"problem":{"type":"string"},"suggestion":{"type":"string"}},"required":["level","file","line","problem","suggestion"]}}},"required":["summary","findings"]}
  ```
- SKILL.md: 構造化出力、MUST 基準（spec 要件・完了条件未達、バグ、セキュリティ、verify で検出できない明らかな破綻＝未実装スタブ・テスト削除/緩和・無関係な破壊的変更）。好み・改善は should、表記は nit、迷ったら should。再実行時も base..HEAD 全体。
- bin/harness:
  - `review_one <aspect> <base> <n>`: label `cycle$n-review-$aspect`、schema 付き。`.structured_output.findings | type=="array"` でなければ return 1。`reviews/cycle$n-$aspect.json` に保存。
  - `render_review_md <json> <n>`:
    ```
    jq -r --arg n "$n" '"# Review (cycle \($n))\n", (["must","should","nit"][] as $l | [.findings[]|select(.level==$l)] as $f | "## \($l|ascii_upcase) (\($f|length))\n", ($f[] | "- [\(.aspect)] \(.file):\(.line) — \(.problem)\n  - 修正案: \(.suggestion)"), "")'
    ```
    + 観点ごとの summary。
  - `phase_review`: 欠けた観点のみ並列実行、失敗で die。REVIEW_ASPECTS 明示ループで `jq -s` 結合 → `reviews/cycle$n.json`。`review-cycle$n.md` 生成、`review.md` へ cp。件数記録。must 0 → walkthrough。`review_loops >= MAX` → `stop_with "review ループ: ${MAX}/${MAX} 回やり直した後も MUST 指摘が $must 件 (cycle $n)"`。他 → write_fix_input、`review_loops+=1`、`verify_attempts=0`、`next_trigger=review-must`、phase=plan。
  - 旧 `cmd_review` / `review-<aspect>.md` 削除。
- 確認: `jq .` でスキーマ、`/bin/bash -n`、jq 単体実行、タスク 9。

### 6. walkthrough フェーズ
- 変更: `claude/skills/harness-walkthrough/SKILL.md`（新規）、`bin/harness`
- SKILL.md（`disable-model-invocation: true`、引数 `<task-name>`）: 入力 plan.json、最新 reviews/cycle<N>.json、`git log --reverse base..HEAD` / `git show`、verify ログ末尾。出力 Markdown（概要 / 結果 / commit ごとの何を・なぜ・どう確認したか（cycle と trigger 併記）/ 最終 verify 結果（skip なら明記）/ 残った SHOULD・NIT）。
- `phase_walkthrough`: sonnet/2/readonly、`.result` → walkthrough.md。stop_reason null なら done、そうでなければ stopped。die 前に stop_reason を表示。
- `report_done`: サイクル数、verify 結果、MUST 0、SHOULD/NIT 件数、パス表示。
- 確認: `/bin/bash -n`、タスク 9。

### 7. ヘッダコメント・usage・文言整理
- 変更: `bin/harness`
- 冒頭コメントを新フロー・再開・verify.sh 規約に。`/spec-writer` → `/harness-spec`。bash 3.2 非互換構文の点検。
- 確認: `/bin/bash -n`、`local [a-z_]+=\$\(`・`declare -A`・`mapfile`・`wait -n` が 0 件。

### 8. harness-spec スキル（新規）
- 変更: `claude/skills/harness-spec/SKILL.md`（`disable-model-invocation` なし）
- spec-writer のヒアリング 4 段階 +「ゴール基準を決める」（verify.sh を作る / verify なし）。spec.md 雛形に `## 完了条件`。verify.sh 規約。雛形集（共通ヘッダ、CLI、Web、Android unit、Android + screencap + AI 判定。AI 判定は `--output-format json --json-schema '{pass,reason}'` → `jq -r` で reason 出力、`jq -e '.structured_output.pass'`）。生成後 `bash -n` と `(source verify.sh && verify); echo $?` をユーザーと確認。
- 確認: 雛形を scratchpad で `/bin/bash -n`。

### 9. fake-claude とループ回数テスト
- 変更: `claude/harness/tests/fake-claude`、`claude/harness/tests/run-tests.sh`（実行権限）
- fake-claude: stdin 1 行目を分解し `$FAKE_STATE_DIR/calls.log` に追記。`jq -n` で `{is_error,result,structured_output}`。explore → MD、plan → fix なら 1 タスク・他は `${FAKE_PLAN_TASKS:-2}`（一意な title/commit_message）、implement → `FAKE_FAIL_ONCE==impl-c-id` で初回失敗、他は `fake-impl.txt` に追記、review → correctness のみ `FAKE_REVIEW_MUST=always|once` で must 1 件、walkthrough → MD。
- run-tests.sh: `setup_repo <scenario>`（mktemp、git init、ローカル user 設定、spec.md、verify.sh（`verify.calls` 追記、always-fail / fail-once / pass））、`run_harness`（`HARNESS_CLAUDE=fake /bin/bash bin/harness demo`）、`assert_eq`/`assert_file`、`KEEP=1`。
- シナリオ:
  1. pass: exit 0、done、verify.calls 1 行、build ログ無し、harness-fix 呼び出し無し、walkthrough あり
  2. no-verify: exit 0、verify_skipped true、review 5 観点、walkthrough あり
  3. verify-always-fail: exit 1、stopped、attempts 3、cycles 3、verify.calls 3、review 0、stop_reason に「verify ループ」、walkthrough あり
  4. verify-fail-once: exit 0、cycles 2、cycles[1].trigger verify-fail、cycle2-input.md に FAIL
  5. review-must-always: exit 1、review_loops 2、cycles 3、review-cycle1..3.md、stop_reason に「review ループ」
  6. review-must-once: exit 0、cycles 2、trigger review-must、cycle2 verify 実行
  7. resume: `FAKE_FAIL_ONCE=impl-1-2` で 1 回目 exit 1、2 回目 exit 0、`harness-implement demo 1 1` が 1 回のみ
  8. stopped 再実行: シナリオ 3 後に再実行 exit 1、calls.log 増えない
- 確認: `/bin/bash -n` と全件 PASS。

### 10. README 全面更新
- 変更: `claude/harness/README.md`
- 使い方、フロー図、ループ回数定義、verify.sh 規約、モデル・予算表とコスト感、成果物一覧、plan.json 構造、再開表と手動再開手順、注意点、テスト節、未検証事項。config.sh / fix / `/harness` スキルの記述削除。
- 確認: `config.sh|harness-fix|/harness ` が残らない。

### 11. 検証手順
1. `/bin/bash -n bin/harness claude/harness/tests/run-tests.sh claude/harness/tests/fake-claude`（3.2 確認）
2. `claude/harness/tests/run-tests.sh` 全 PASS（完了条件との対応: 1→per-task verify なし、3/4→verify ループ、2→skip、5/6→review ループ、全→walkthrough、7/8→再開）
3. 実 claude スモークテスト（課金・手動）
4. 静的チェック: `harness-fix`・`check_config`・`run_checks` 残存なし、スキーマ `jq .`、新スキルの frontmatter

## リスクと軽減策
- jq 負インデックス代入 → `(.cycles|length-1) as $c`
- review 構造化出力欠落 → die、欠けた観点のみ再実行
- verify.sh の `set -e` 無効 → `|| return 1` 必須
- まとめ verify で途中破損に気づきにくい → 「各タスクで壊さない」規約
- 最大 9 サイクルのコスト → README に記載、各呼び出しに budget
- fake と実 claude の JSON 差 → スモークテストで確認
