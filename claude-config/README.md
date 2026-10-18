# Claude MCP Settings

## スコープ別設定ファイル

| スコープ | ファイル | 用途 |
|---|---|---|
| project（git管理あり） | `.mcp.json` | チーム共有のMCP設定 |
| project（git管理なし） | `~/claude.json` の `projects[].mcpServers` | 個人用プロジェクト設定 |
| user | `~/.claude.json` のトップレベル `mcpServers` | 全プロジェクト共通設定 |

---

## MCPサーバー一覧

### Atlassian

JiraやConfluenceの読み書きを行うMCPサーバー。

- **スコープ**: project（`.mcp.json`）

```bash
claude mcp add -s project --transport http atlassian https://mcp.atlassian.com/v1/mcp
```

---

### Context7

ライブラリ・フレームワークの最新ドキュメントを取得するMCPサーバー。

- **スコープ**: project（`.mcp.json`）

```bash
claude mcp add -s project --transport http context7 https://mcp.context7.com/mcp
```

---

### Figma

Figmaのデザインファイル・コンポーネント情報を取得するMCPサーバー。

- **スコープ**: project（`.mcp.json`）

```bash
claude mcp add -s project --transport http figma https://mcp.figma.com/mcp
```

---

### Backlog

Backlogのチケット・プロジェクト情報を取得するMCPサーバー。

- **スコープ**: user（`~/.claude.json`）

`~/.claude.json` の `mcpServers` に以下を追加：

```json
"backlog": {
  "command": "npx",
  "args": ["backlog-mcp-server"],
  "env": {
    "BACKLOG_DOMAIN": "your-domain.backlog.com",
    "BACKLOG_API_KEY": "your-api-key"
  }
}
```

APIキーは [Backlog個人設定 > API](https://your-domain.backlog.com/EditApiSettings.action) から取得。
