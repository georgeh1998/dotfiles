# harness

`claude -p` をフェーズごとに別プロセスで起動する開発ハーネス(`dotfiles/bin/harness`)。
ビルド・検証の成否判定とコミットは bash が行う。

## 使い方

```
harness <task>     # spec.md がある前提で explore → plan → run → review を通す
```

事前に `/spec-writer` で `claude/tasks/<task>/spec.md` を作る。`/harness <task>` スキルからも呼べる。

## プロジェクト設定

`<project>/.harness/config.sh` に `build()` と `verify()` だけを定義する。ハーネスは終了コードだけを見る(0 = 成功)。未定義ならエラー終了する。

```bash
build() { ./gradlew assembleDebug; }
verify() { ./gradlew testDebugUnitTest; }
```

## フェーズとモデル

| フェーズ | モデル | 予算(USD) | 権限 |
|---|---|---|---|
| explore | sonnet | 2 | 読み取り専用ツール |
| plan | opus | 3 | 読み取り専用ツール + `--json-schema` |
| implement | sonnet | 5 | `--dangerously-skip-permissions` |
| fix(最大3回) | sonnet | 3 | `--dangerously-skip-permissions` |
| review(5観点を並列) | opus | 2 / 観点 | 読み取り専用ツール |

review は5本並列で起動するため、起動コストも5倍かかる。`--max-turns` は help に無いので使わず、`--max-budget-usd` で暴走を防ぐ。

## 成果物

`<project>/claude/tasks/<task>/` に保存される: `spec.md` `explore.md` `plan.json` `review-*.md` `logs/`(claude の生 JSON、プロンプト、build/verify ログ)。
`plan.json` の各タスクの `status`(pending/done)で進捗を管理する。

## 失敗時の再開

- 成果物ができなければ、どのフェーズで何が足りないかを表示してエラー終了する
- 直してから同じ `harness <task>` を再実行する。`explore.md` / `plan.json` が既にあればそのフェーズは飛ばす。やり直したいフェーズの成果物は消してから再実行する
- `run` は `plan.json` の status が done のタスクを飛ばし、未完了の先頭から再開する。fix が3回失敗すると停止する。`plan.json` は手で編集してよい
- 再開時は常に先頭の未完了タスクの implement から始まる(手修正済みでも claude が再実行される)
- コミット直後〜status 更新前に中断すると、再開時に同じタスクが再実装される場合がある(plan.json の status を手で done にして回避)
- `git add -A` は `claude/tasks` 以外をすべて含む(未追跡の `.harness/` など)。実行前に作業ツリーをきれいにしておく
- 作業ツリーの未コミットの変更は前回の途中成果として引き継がれる

## テスト

`claude/harness/tests/run-tests.sh`(`fake-claude` スタブを使うので課金されない)。`HARNESS_CLAUDE` 環境変数は、このテスト用に claude コマンドを差し替えるためのフック。

## 未検証事項

- `--dangerously-skip-permissions` 使用時に settings.json の deny ルールが効くか
- `claude -p` 失敗時の終了コードと `.is_error` の関係(両方を見て判定している)
- `--max-budget-usd` を超えたときの挙動
- 本物の claude での通し実行(手動スモークテスト)
