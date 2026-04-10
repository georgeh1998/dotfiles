# Dotfiles

This repository contains personal configuration files and development environment setup.

## Setup

### Config Files

`setup.sh` を実行すると、`config/` 以下の各ディレクトリが `~/.config/` にシンボリックリンクされます。
`.config` ディレクトリ自体ではなく、個別のサブディレクトリ単位でリンクするため、既存の設定とバッティングしません。

```bash
chmod +x setup.sh
./setup.sh
```

| リンク元 | リンク先 | 内容 |
|---|---|---|
| `config/wezterm/` | `~/.config/wezterm/` | WezTerm の設定 |

既にリンク先にディレクトリが存在する場合はスキップされます（既存のシンボリックリンクは上書きされます）。

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
| `statusline.sh` | ステータスラインのラッパースクリプト（以下3つを結合） |
| `statusline-context-window.sh` | コンテキスト使用率をプログレスバーで表示 |
| `statusline-cost.sh` | コスト・経過時間を表示 |
| `statusline-model.sh` | 使用中のモデル名を表示 |


### CLI Tools

`bin` ディレクトリを PATH に追加します:

```bash
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

**Available commands:**
- `nk <task-name>` - Create a new task directory in `.claude/tasks/<task-name>/` with a requirements.md template for Claude Code workflows
