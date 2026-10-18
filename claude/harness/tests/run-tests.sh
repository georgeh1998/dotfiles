#!/bin/bash
# run-tests.sh: bin/harness のループ回数・skip・再開を fake-claude で確認する(課金なし)
#
# 使い方: claude/harness/tests/run-tests.sh   (KEEP=1 で一時ディレクトリを残す)
# macOS 標準の /bin/bash (3.2) で harness を実行する

set -o pipefail

TESTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$(cd "$TESTS/../../.." && pwd)/bin/harness"
FAKE="$TESTS/fake-claude"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/harness-test.XXXXXX")" || exit 1
PASSES=0
FAILS=0

cleanup() {
  if [[ -n "${KEEP:-}" ]]; then
    echo "一時ディレクトリ: $WORK"
  else
    rm -rf "$WORK"
  fi
}
trap cleanup EXIT

ok() { PASSES=$((PASSES + 1)); }
ng() {
  FAILS=$((FAILS + 1))
  echo "  FAIL: $*"
}

# assert_eq <説明> <期待値> <実際の値>
assert_eq() {
  if [[ "$2" == "$3" ]]; then ok; else ng "$1 (expected: $2, actual: $3)"; fi
}

assert_file() {
  if [[ -f "$2" ]]; then ok; else ng "$1 ($2 が無い)"; fi
}

assert_contains() {
  if grep -q -- "$2" "$3" 2>/dev/null; then ok; else ng "$1 ($3 に '$2' が無い)"; fi
}

# setup_repo <name> <verify: none|pass|fail|fail-once>
setup_repo() {
  local name=$1 mode=$2 body
  REPO="$WORK/$name/repo"
  STATE="$WORK/$name/state"
  TD="$REPO/claude/tasks/demo"
  mkdir -p "$REPO" "$STATE"
  : >"$STATE/calls.log"
  git -C "$REPO" init -q
  git -C "$REPO" config user.name harness-test
  git -C "$REPO" config user.email harness-test@example.invalid
  git -C "$REPO" config commit.gpgsign false
  echo init >"$REPO/README"
  git -C "$REPO" add README
  git -C "$REPO" commit -q -m init
  mkdir -p "$TD"
  echo "# demo" >"$TD/spec.md"
  case "$mode" in
    none) return ;;
    pass) body='echo "verify ok"' ;;
    fail) body='echo "FAIL: always"; return 1' ;;
    fail-once)
      body="if [ -f '$STATE/verify-failed' ]; then echo ok; else touch '$STATE/verify-failed'; echo 'FAIL: once'; return 1; fi"
      ;;
  esac
  cat >"$TD/verify.sh" <<EOF
verify() {
  echo call >>"$STATE/verify.calls"
  $body
}
EOF
}

# run_harness [VAR=value...] [-- harness のオプション...]: 終了コードを RC に入れる
run_harness() {
  local envs=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    envs+=("$1")
    shift
  done
  [[ "$1" == "--" ]] && shift
  (cd "$REPO" && env ${envs[@]+"${envs[@]}"} FAKE_STATE_DIR="$STATE" HARNESS_CLAUDE="$FAKE" \
    /bin/bash "$HARNESS" "$@" demo) \
    >>"$WORK/$(basename "$(dirname "$REPO")").out" 2>&1
  RC=$?
}

pj() { jq -r "$1" "$TD/plan.json"; }
count() { grep -c -- "$1" "$2" 2>/dev/null || true; }
lines() { if [[ -f "$1" ]]; then wc -l <"$1" | tr -d ' '; else echo 0; fi; }

scenario() {
  echo "== $1"
}

# 1. verify 成功・MUST なし: タスクごとに build/verify が走らない
scenario "pass"
setup_repo pass pass
run_harness -- --verify
assert_eq "exit code" 0 "$RC"
assert_eq "phase" done "$(pj .phase)"
assert_eq "verify は全タスク後に 1 回だけ" 1 "$(lines "$STATE/verify.calls")"
assert_eq "build ログが無い" 0 "$(ls "$TD/logs" | grep -c build)"
assert_eq "harness-fix を呼ばない" 0 "$(count harness-fix "$STATE/calls.log")"
assert_eq "タスクごとに commit" 2 "$(git -C "$REPO" rev-list --count "$(pj .base)"..HEAD)"
assert_eq "task の sha が記録される" 2 "$(pj '[.cycles[0].tasks[] | select(.sha != null)] | length')"
assert_file "review.md" "$TD/review.md"
assert_file "walkthrough.md" "$TD/walkthrough.md"

# 2. 既定では verify.sh があっても verify を skip して review まで進む
scenario "verify off (既定)"
setup_repo no-verify pass
run_harness
assert_eq "exit code" 0 "$RC"
assert_eq "cycle の verify" true "$(pj '.cycles[0].verify.skipped')"
assert_eq "verify を実行しない" 0 "$(lines "$STATE/verify.calls")"
assert_eq "review は 5 観点" 5 "$(count '^/harness-review' "$STATE/calls.log")"
assert_file "walkthrough.md" "$TD/walkthrough.md"

# 3. verify が常に失敗: X をやり直し、3 回で停止
scenario "verify-always-fail"
setup_repo verify-fail fail
run_harness -- --verify
assert_eq "exit code" 1 "$RC"
assert_eq "phase" stopped "$(pj .phase)"
assert_eq "verify_attempts" 3 "$(pj .verify_attempts)"
assert_eq "cycles" 3 "$(pj '.cycles | length')"
assert_eq "verify の実行回数" 3 "$(lines "$STATE/verify.calls")"
assert_eq "review しない" 0 "$(count '^/harness-review' "$STATE/calls.log")"
assert_eq "修正 plan は 2 回" 2 "$(count '^/harness-plan demo fix' "$STATE/calls.log")"
assert_contains "stop_reason" "verify ループ 3/3" "$TD/plan.json"
assert_file "walkthrough.md" "$TD/walkthrough.md"

# 8. 停止後に再実行しても claude を呼ばずに停止を表示する
scenario "stopped の再実行"
before="$(lines "$STATE/calls.log")"
run_harness -- --verify
assert_eq "exit code" 1 "$RC"
assert_eq "claude を呼ばない" "$before" "$(lines "$STATE/calls.log")"

# 4. verify が 1 回だけ失敗: 失敗ログを入力に X をやり直して完了
scenario "verify-fail-once"
setup_repo verify-fail-once fail-once
run_harness -- --verify
assert_eq "exit code" 0 "$RC"
assert_eq "cycles" 2 "$(pj '.cycles | length')"
assert_eq "trigger" verify-fail "$(pj '.cycles[1].trigger')"
assert_contains "修正入力に失敗ログ" "FAIL: once" "$TD/logs/cycle2-input.md"
assert_eq "verify の実行回数" 2 "$(lines "$STATE/verify.calls")"

# 5. review が常に MUST: X をやり直し、2 回で停止
scenario "review-must-always"
setup_repo review-must pass
run_harness FAKE_REVIEW_MUST=always -- --verify
assert_eq "exit code" 1 "$RC"
assert_eq "phase" stopped "$(pj .phase)"
assert_eq "review_loops" 2 "$(pj .review_loops)"
assert_eq "cycles" 3 "$(pj '.cycles | length')"
assert_eq "review の実行回数" 15 "$(count '^/harness-review' "$STATE/calls.log")"
assert_file "review-cycle1.md" "$TD/review-cycle1.md"
assert_file "review-cycle3.md" "$TD/review-cycle3.md"
assert_contains "stop_reason" "review ループ: 2/2" "$TD/plan.json"
assert_contains "修正入力に MUST 指摘" "fake must" "$TD/logs/cycle2-input.md"
assert_file "walkthrough.md" "$TD/walkthrough.md"

# 6. review が 1 回だけ MUST: X をやり直し、verify ループを経て完了
scenario "review-must-once"
setup_repo review-must-once pass
run_harness FAKE_REVIEW_MUST=once -- --verify
assert_eq "exit code" 0 "$RC"
assert_eq "cycles" 2 "$(pj '.cycles | length')"
assert_eq "trigger" review-must "$(pj '.cycles[1].trigger')"
assert_eq "修正後も verify する" 2 "$(lines "$STATE/verify.calls")"
assert_eq "cycle2 の verify" true "$(pj '.cycles[1].verify.ok')"

# 7. implement 中に落ちても、同じコマンドで続きから再開できる
scenario "resume"
setup_repo resume pass
run_harness FAKE_FAIL_ONCE=impl-1-2
assert_eq "1 回目の exit code" 1 "$RC"
assert_eq "1 回目の phase" implement "$(pj .phase)"
run_harness FAKE_FAIL_ONCE=impl-1-2
assert_eq "2 回目の exit code" 0 "$RC"
assert_eq "task 1 を再実装しない" 1 "$(count '^/harness-implement demo 1 1$' "$STATE/calls.log")"
assert_eq "初回 plan は 1 回" 1 "$(count '^/harness-plan demo$' "$STATE/calls.log")"
assert_eq "explore は 1 回" 1 "$(count '^/harness-explore' "$STATE/calls.log")"

# 9. --verify なのに verify.sh が無い: claude を呼ばずにエラー
scenario "--verify で verify.sh なし"
setup_repo verify-missing none
run_harness -- --verify
assert_eq "exit code" 1 "$RC"
assert_eq "claude を呼ばない" 0 "$(lines "$STATE/calls.log")"

# 10. --stop-after-plan: 初回 plan で止まり、再実行で implement から続ける
scenario "--stop-after-plan"
setup_repo stop-after-plan none
run_harness -- --stop-after-plan
assert_eq "1 回目の exit code" 0 "$RC"
assert_eq "1 回目の phase" implement "$(pj .phase)"
assert_eq "implement しない" 0 "$(count '^/harness-implement' "$STATE/calls.log")"
run_harness -- --stop-after-plan
assert_eq "plan 済みなら何もしない" 0 "$(count '^/harness-implement' "$STATE/calls.log")"
run_harness
assert_eq "2 回目の exit code" 0 "$RC"
assert_eq "phase" done "$(pj .phase)"
assert_eq "初回 plan は 1 回" 1 "$(count '^/harness-plan demo$' "$STATE/calls.log")"

# 12. claude/ が gitignore されていても commit できる
scenario "claude/ が ignore されている"
setup_repo ignored none
echo claude >"$WORK/ignored/excludes"
git -C "$REPO" config core.excludesFile "$WORK/ignored/excludes"
run_harness
assert_eq "exit code" 0 "$RC"
assert_eq "タスクごとに commit" 2 "$(git -C "$REPO" rev-list --count "$(pj .base)"..HEAD)"

# 13. 実行前からある未コミットの変更は commit せず、作業ツリーに残す
scenario "ユーザーの未コミットの変更"
setup_repo user-local none
echo bypass >>"$REPO/README"
echo tmp >"$REPO/user-tmp.txt"
run_harness
assert_eq "exit code" 0 "$RC"
assert_eq "タスクごとに commit" 2 "$(git -C "$REPO" rev-list --count "$(pj .base)"..HEAD)"
assert_eq "README は commit されない" 0 "$(git -C "$REPO" log --oneline "$(pj .base)"..HEAD -- README | wc -l | tr -d ' ')"
assert_eq "user-tmp.txt は commit されない" "" "$(git -C "$REPO" ls-files user-tmp.txt)"
assert_eq "README の変更は作業ツリーに残る" bypass "$(tail -1 "$REPO/README")"
assert_file "user-tmp.txt は残る" "$REPO/user-tmp.txt"
assert_contains "local.patch に README" "README" "$TD/local.patch"
assert_contains "local.patch に user-tmp.txt" "user-tmp.txt" "$TD/local.patch"

# 14. local: true のタスクは commit せず local.patch に足す
scenario "local タスク"
setup_repo local-task none
echo bypass >>"$REPO/README"
run_harness FAKE_LOCAL_TASK=1
assert_eq "exit code" 0 "$RC"
assert_eq "local タスクは commit しない" 1 "$(git -C "$REPO" rev-list --count "$(pj .base)"..HEAD)"
assert_eq "status は local" local "$(pj '.cycles[0].tasks[0].status')"
assert_file "bypass.txt は作業ツリーに残る" "$REPO/bypass.txt"
assert_contains "local.patch に bypass.txt" "bypass.txt" "$TD/local.patch"
assert_contains "local.patch に既存の README" "README" "$TD/local.patch"

# 15. local.patch と同じ箇所を変更したら commit せずに中断する
scenario "local.patch と重なる変更"
setup_repo local-conflict none
echo bypass >"$REPO/fake-impl.txt"
git -C "$REPO" add fake-impl.txt && git -C "$REPO" commit -q -m base
echo user >>"$REPO/fake-impl.txt"
run_harness
assert_eq "exit code" 1 "$RC"
assert_eq "commit しない" 0 "$(git -C "$REPO" rev-list --count "$(pj .base)"..HEAD)"

# 11. --help
scenario "--help"
/bin/bash "$HARNESS" --help >"$WORK/help.out" 2>&1
assert_eq "exit code" 0 "$?"
assert_contains "--verify の説明" "--verify" "$WORK/help.out"
assert_contains "--stop-after-plan の説明" "--stop-after-plan" "$WORK/help.out"

echo
echo "PASS: $PASSES, FAIL: $FAILS"
[[ $FAILS -eq 0 ]]
