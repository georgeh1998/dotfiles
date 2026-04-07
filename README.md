# Dotfiles

This repository contains personal configuration files and development environment setup.

## Setup

### Claude Code

`.claude/setup.sh` を実行するだけで、Claude Code に必要なシンボリックリンクがすべて設定されます。

```bash
chmod +x .claude/setup.sh
./.claude/setup.sh
```

以下のシンボリックリンクが `~/.claude/` に作成されます:

| リンク先 | 内容 |
|---|---|
| `settings.json` | Claude Code のグローバル設定 |
| `skills/` | カスタムスキル一覧 |
| `statusline.sh` | ステータスラインのラッパースクリプト（以下2つを結合） |
| `statusline-context-window.sh` | コンテキスト使用率をプログレスバーで表示 |
| `statusline-cost.sh` | モデル名・コスト・コンテキスト使用率・経過時間を表示 |

既存のファイルがある場合は `.bak` にバックアップしてから上書きします。

### CLI Tools

`bin` ディレクトリを PATH に追加します:

```bash
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

**Available commands:**
- `nk <task-name>` - Create a new task directory in `.claude/tasks/<task-name>/` with a requirements.md template for Claude Code workflows
