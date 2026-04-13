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
| `config/yazi/` | `~/.config/yazi/` | Yazi の設定 |

既にリンク先にディレクトリが存在する場合はスキップされます（既存のシンボリックリンクは上書きされます）。

#### Yazi プラグイン

`plugins/` ディレクトリは `.gitignore` で除外しています。プラグインは `package.toml` で管理し、以下のコマンドで復元できます:

```bash
ya pkg install
```

プラグインの追加・管理:

```bash
ya pkg add owner/repo       # プラグイン追加（package.toml に自動記録）
ya pkg upgrade              # 全プラグインを最新に更新
ya pkg delete owner/repo    # プラグイン削除
ya pkg list                 # インストール済み一覧
```

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
| `hooks/` | PreToolUse等のフックスクリプト |
| `statusline/` | ステータスライン関連スクリプト一式 |


### Yazi Plugins

```bash
# rich-preview.yazi: ファイルのリッチプレビュー（PDF・画像・動画など）を表示するプラグイン
git clone https://github.com/AnirudhG07/rich-preview.yazi.git config/yazi/plugins/rich-preview.yazi
```

### CLI Tools

`bin` ディレクトリを PATH に追加します:

```bash
echo "export PATH=\"$(pwd)/bin:\$PATH\"" >> ~/.zshrc
source ~/.zshrc
```

**Available commands:**
- `nk <task-name>` - Create a new task directory in `.claude/tasks/<task-name>/` with a requirements.md template for Claude Code workflows
