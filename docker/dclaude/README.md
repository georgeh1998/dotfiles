# Docker

Claude Code をサンドボックス環境で動かすための Docker 設定。

## イメージのビルド

```bash
docker build -t claude-code-sandbox ./docker/dclaude
```

## Claude Code の起動

```bash
docker run -it --rm \
  -v "$(pwd):/$(pwd)" \
  -v "$HOME/.claude.json:/home/appuser/.claude.json" \
  --workdir "/$(pwd)" \
  claude-code-sandbox \
  claude --dangerously-skip-permissions
```

`dclaude` シェル関数を使えば、カレントディレクトリで上記コマンドを簡単に実行できる（`zsh/zshrc` に定義済み）。

## ファイル構成

```
docker/dclaude/
├── Dockerfile   # イメージ定義
└── README.md    # このファイル
```

## 注意事項

- `--dangerously-skip-permissions` はサンドボックス内での使用を想定
- ホストのカレントディレクトリがコンテナにマウントされる
- `~/.claude.json`（認証情報）もマウントされる
