# Claude MCP Settings

## Context7

ライブラリ・フレームワークの最新ドキュメントを取得するMCPサーバー。

### インストール方法

**プロジェクト単位で設定（`.mcp.json` に反映・gitに含まれる）**

```bash
claude mcp add -s project --transport http context7 https://mcp.context7.com/mcp
```

**ユーザー単位で設定（`~/.claude.json` に反映・gitに含まれない）**

```bash
claude mcp add -s user --transport http context7 https://mcp.context7.com/mcp
```

---

## Backlog

Backlogのチケット・プロジェクト情報を取得するMCPサーバー。  
APIキーが必要なため、`~/.claude.json` に直接記載する（gitに含めない）。

### インストール方法

`~/.claude.json` の `mcpServers` に以下を追加：

```json
"backlog": {
  "command": "npx",
  "args": [
    "backlog-mcp-server"
  ],
  "env": {
    "BACKLOG_DOMAIN": "your-domain.backlog.com",
    "BACKLOG_API_KEY": "your-api-key"
  }
}
```

APIキーは [Backlog個人設定 > API](https://your-domain.backlog.com/EditApiSettings.action) から取得。
