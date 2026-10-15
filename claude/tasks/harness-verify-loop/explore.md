# 調査: harness-verify-loop

## 注意
- 同じ spec のコピーが `claude/claude/tasks/harness-verify-loop/spec.md` にある(未追跡・誤配置と思われる)。
- `claude -p` の実行検証はしていない。静的読解と `claude --help` に基づく。

## 1. 関連ファイル

| ファイル | 役割 | 変更 |
|---|---|---|
| `bin/harness` (311行) | 本体 bash スクリプト | 大改修 |
| `claude/harness/README.md` | 使い方・モデル/予算表・再開手順 | 全面更新 |
| `claude/harness/plan-schema.json` | plan 用 JSON Schema。`tasks[]` は id/title/purpose/files/test/commit_message (all required) | 再利用 |
| `claude/skills/harness-explore/SKILL.md` | 調査 Markdown を最終回答で返す | ほぼ不変 |
| `claude/skills/harness-plan/SKILL.md` | spec+explore から structured output で tasks | 修正モード追加 |
| `claude/skills/harness-implement/SKILL.md` | task 1件だけ実装(commit しない) | 小修正 |
| `claude/skills/harness-fix/SKILL.md` | build/verify 失敗修正 | 削除 |
| `claude/skills/harness-review/SKILL.md` | 観点1つの Markdown レビュー | 構造化に改修 |
| `claude/skills/harness-spec/SKILL.md` | 対話で spec.md と verify.sh 生成 | 新規 |
| `claude/skills/harness-walkthrough/SKILL.md` | commit 順の解説書 | 新規 |
| `claude/skills/spec-writer/SKILL.md` | spec.md 形式(# task / やりたいこと / 機能要件 / 調べてほしいこと / スコープ外) | 変更しない。雛形として参照 |

存在しないもの:
- `.harness/config.sh`(対象プロジェクト側前提)
- README が述べる `claude/harness/tests/run-tests.sh`、`fake-claude`、`HARNESS_CLAUDE` フック、`/harness` スキル — いずれも未実装。README と乖離。

その他:
- `commit_task` の `git add -A -- . ':(exclude)claude/tasks'` により verify.sh / artifacts は commit 対象外(意図どおり)。

## 2. bin/harness 現行フロー

固定値(15-20行): `MAX_FIX=3`、`PHASES`(未使用)、`REVIEW_ASPECTS="correctness security maintainability tests spec"`、`READONLY_TOOLS="Read,Grep,Glob,Bash"`、`READONLY_ALLOWED`(git log/diff/show/ls)。

関数:
- `info`/`die`/`usage`(22-31)
- `resolve_home`(35-44): `readlink`(`-f` なし)で symlink を辿り `HARNESS_HOME=<bin>/../claude/harness`
- `check_deps`(48-53): claude/jq/git
- `check_config`(56-69): CONFIG を source し build/verify を `declare -F` 確認 → 廃止
- `run_claude`(75-95): `label model budget prompt_file -- extra...`。`(cd $ROOT && claude -p --output-format json --no-session-persistence --model --max-budget-usd "$@" <prompt)`。stdout→`logs/<label>.json`、stderr→`logs/<label>.err`。終了コード + `jq -e '.is_error == false'` で判定。プロンプトは `/skill args` 1行を stdin。
- `cmd_explore`(99-112): sonnet/$2/readonly、`.result` → explore.md(tmp→mv)
- `cmd_plan`(116-134): opus/$3/readonly/`--json-schema`。`.structured_output.tasks` 長さ確認 → `{base, tasks: map(.+{status:"pending"})}` を plan.json
- `next_task`/`task_field`/`set_status`(138-150): jq 読み書き。`task_field` は `.$2` を直埋め
- `run_checks`(153-167): build → verify を `(cd ROOT && source CONFIG && step)`。ログ `logs/task<id>-<step>.log`。`FAILED_STEP`/`FAILED_LOG` を設定
- `commit_task`(169-179): add (claude/tasks 除外)、変更なしなら die、commit_message で commit
- `report_stop`(181-189): 停止メッセージ + exit 1
- `cmd_run`(191-230): pending task ごとに `/harness-implement TASK id`(sonnet/$5/`--dangerously-skip-permissions`) → `until run_checks` で失敗時 `failure.txt`(tail 200) と `/harness-fix`(sonnet/$3) 最大3回 → commit → done。最後に final checks
- `review_one`/`cmd_review`(234-268): 5観点を `&` 並列(opus/$2/readonly)。`.result` → `review-<aspect>.md`
- `run_phase`(272-278): `(cmd_$phase)` サブシェル実行
- `run_all`(280-287): EXPLORE/PLAN 有無で skip → run → review
- `main`(291-308): 引数1つ、`^[A-Za-z0-9._-]+$` 検証、ROOT/CONFIG/TASK_DIR/LOG_DIR/SPEC/EXPLORE/PLAN 設定

状態: plan.json `{base, tasks:[{..., status: pending|done}]}`。再開は成果物の有無と status のみ。弱点: commit 後 set_status 前に落ちると再実装。review は常に全観点再実行。

## 3. スキル入出力

全て `disable-model-invocation: true`、bin/harness からのみ呼ばれる。

| スキル | 引数 | 入力 | 出力 | 呼び出し |
|---|---|---|---|---|
| explore | task | spec | Markdown | sonnet/$2/readonly |
| plan | task | spec, explore | structured_output | opus/$3/readonly/schema |
| implement | task id | spec, explore, plan.json | 作業ツリー変更 | sonnet/$5/skip-perms |
| fix | task id | failure.txt, plan.json | 作業ツリー変更 | sonnet/$3/skip-perms |
| review | task aspect base | spec, plan.json, diff base..HEAD | Markdown(Approve/Warning/Block, CRITICAL〜LOW) | opus/$2/readonly ×5 |

## 4. 必要な変更

新規:
- `claude/skills/harness-spec/SKILL.md`(対話用なので `disable-model-invocation` なし)
- `claude/skills/harness-walkthrough/SKILL.md`(Markdown を最終回答で返し bash が書く)
- `claude/harness/review-schema.json`

修正:
- `bin/harness`: check_config/CONFIG/build/MAX_FIX/fix ループ/per-task checks/final checks を削除。`VERIFY`、`run_verify`(`cd $ROOT && source $VERIFY && verify`、ログ `logs/cycle<N>-verify<M>.log`)、`cmd_cycle`、verify/review ループ、`cmd_walkthrough`、plan.json 状態管理、停止メッセージを追加。review は `.structured_output` を観点別保存し jq で結合・must カウント。
- `harness-plan`: 修正モード
- `harness-implement`: 「ビルド・テストはハーネスが実行」の記述修正
- `harness-review`: structured output + MUST 基準
- README: 全面更新、実在しない記述の整理

削除: `claude/skills/harness-fix/`、`claude/claude/`

## 5. 調べてほしいことへの回答

### (1) 修正 plan の入力と分割
- 入力はファイル(`logs/cycle<N>-input.md`)に書き出し、`/harness-plan <task> fix <N>` で読ませる。
- 内容: 種別(verify-fail / review-must)、verify ログは `tail -n 200` + `head -c 20000`、MUST 指摘は jq で `file:line / problem / suggestion` 箇条書き(should/nit は渡さない)、`git log --oneline base..HEAD`。
- スキルは分けず harness-plan 1つで引数分岐(スキーマ・粒度規約を共通化)。修正時は修正タスクのみ返す。
- base は初回のみ設定、以後更新しない。

### (2) plan.json 構造と再開
```json
{
  "base": "<sha>",
  "phase": "plan|implement|verify|review|walkthrough|done|stopped",
  "cycle": 1,
  "verify_attempts": 0,
  "review_loops": 0,
  "verify_skipped": false,
  "stop_reason": null,
  "cycles": [
    {"n": 1, "trigger": "initial|verify-fail|review-must", "input_file": null,
     "tasks": [{"id":1, "title":"...", "purpose":"...", "files":[], "test":"...",
                "commit_message":"...", "status":"pending|done", "sha":null}]}
  ]
}
```
- top-level tasks 廃止。`.cycles[-1]` は jq 1.5+。
- commit 後に sha 記録 → 二重実装回避。
- 更新は tmp→mv。

| 落ちた時 | 再開 |
|---|---|
| plan 中 | 新サイクル未記録なら plan 再実行(入力ファイルは冪等再生成) |
| implement 中 | 先頭 pending から再実行(作業ツリー引継ぎ) |
| commit 前後 | sha 記録で回避 |
| verify 中 | 結果取得後に attempts 加算(推奨) |
| review 中 | 観点別ファイルが揃っていれば skip、欠けた観点のみ再実行 |
| walkthrough 中 | 再実行 |
| stopped | 停止理由を表示して終了。手で plan.json を編集して再開 |

- `phase` は各ステップ前に書き込み、再開時は phase で switch。

### (3) review 履歴
- 連番保存: `logs/cycle<N>-review-<aspect>.json`、`reviews/cycle<N>-<aspect>.json`、`review-cycle<N>.md` + 最新を `review.md` にコピー(または追記)。

### (4) model と予算
- explore sonnet/$2、plan opus/$3(修正も opus 推奨)、implement sonnet/$5×N、review opus/$2×5、walkthrough sonnet/$2(readonly)。
- verify 内 `claude -p` は verify.sh 側で `--max-budget-usd` を指定する規約(例 $1)。
- 最悪ケース上限合算 約 $150〜200(実コストはかなり小さい)。README に記載。

### (5) verify.sh 雛形
- スキル内にひな形集として記述し、対話でコマンド確定後に生成。
- 例: Android(`./gradlew assembleDebug testDebugUnitTest`、install→screenshot→claude 判定)、Web(`npm test && npm run build`、playwright)、CLI(`bash -n`、サンプル入力 diff)。
- AI 判定: `claude -p --model sonnet --max-budget-usd 1 --json-schema '{pass,reason}'`、false なら return 1、理由を stdout へ。
- 注意: `source X && verify` 形式では関数内 `set -e` が無効化される。`&&` 連結 / `|| return 1` を雛形に明記。

## 6. リスク
- bash 3.2: 連想配列・mapfile・`readlink -f`・`${var,,}`・nameref・`wait -n` 不可。`set -u` は使わない。`local x=$(cmd)` は終了コードを隠すので分けて書く。`/bin/bash -n` で検証。
- jq: `jq -s` で結合。`task_field` の直埋めは `--arg`/`--argjson` へ。
- 構造化出力が取れない review は「must 0件」とせず失敗扱い。
- verify なし時は review が唯一のゲート → MUST 基準を具体化。
- 全 task 実装後に verify するので途中の破損に気づきにくい → plan の「各タスク単体でビルドが通る」条件は残す。
- 修正 plan が空 tasks → 停止。
- 停止→手修正→再開時の未コミット変更が次の commit に混ざる → README に明記。

## 推奨実装順
1. review-schema.json + harness-review 構造化
2. plan.json 新構造と状態管理関数
3. verify.sh 読み込みと verify ループ(config/build/fix 削除)
4. サイクル化(plan 修正モード、implement のみの run)
5. review ループと review.md 生成(連番)
6. harness-walkthrough + cmd_walkthrough
7. harness-spec
8. harness-fix 削除、README 更新、`claude/claude/` 削除
- 検証: `/bin/bash -n bin/harness` と fake-claude スタブでのループ回数テスト(実 claude は課金)。
