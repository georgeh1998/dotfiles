# Dotfiles

This repository contains personal configuration files and development environment setup.

## Setup

### Zsh

`setup.sh` を実行すると、`~/.zshrc` に `zsh/zshrc` を読み込む `source` 行が追記されます（既にある場合はスキップ）。

```bash
chmod +x setup.sh
./setup.sh
```

`zsh/zshrc` には alias・プロンプト設定・`bin` ディレクトリの PATH 追加が含まれます。
編集後は新しいシェルを開くか `source ~/.zshrc` で反映してください。

### Claude Code

`claude/claude-setup.sh` を実行するだけで、Claude Code に必要なシンボリックリンクがすべて設定されます。

```bash
chmod +x claude/claude-setup.sh
./claude/claude-setup.sh
```

以下のシンボリックリンクが `~/.claude/` に作成されます:

| リンク先 | 内容 |
|---|---|
| `settings.json` | Claude Code のグローバル設定 |
| `skills/` | カスタムスキル一覧 |
| `agents/` | カスタムエージェント定義 |
| `hooks/` | PreToolUse等のフックスクリプト |
| `statusline/` | ステータスライン関連スクリプト一式 |

### CLI Tools

`bin` ディレクトリは `zsh/zshrc` 経由で自動的に PATH に追加されるため、別途の設定は不要です。

**Available commands:**
- `nt <task-name>` - タスク用ディレクトリを作成し、spec.md のテンプレートを配置する
- `st [dir]` - 指定ディレクトリ（省略時はカレント）の Git リポジトリを SourceTree で開く
