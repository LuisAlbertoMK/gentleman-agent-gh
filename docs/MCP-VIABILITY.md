# MCP Viability Report — gentleman-vMK

> **Date**: 2026-06-21 | **Source**: Official MCP Registry, modelcontextprotocol/servers, Smithery (4,851 servers)
> **Purpose**: Identify MCP servers that extend agent capability beyond built-in tools, with minimal overhead.

## Top 5 Recommended MCPs

| # | MCP | What It Enables | Install | Auth | Est. Token Overhead |
|---|-----|-----------------|---------|------|-------------------|
| 1 | **Memory MCP** (`@modelcontextprotocol/server-memory`) | Persistent knowledge graph across sessions — user prefs, conventions, decisions | `npx -y @modelcontextprotocol/server-memory` | None | ~500 tokens |
| 2 | **Sequential Thinking** (`@modelcontextprotocol/server-sequential-thinking`) | Structured, auditable reasoning traces — branching, revision, thought chains | `npx -y @modelcontextprotocol/server-sequential-thinking` | None | ~200 tokens |
| 3 | **Playwright MCP** (`@playwright/mcp`) | Full browser automation (22 tools): navigate, click, snapshot, network capture, PDF | `npx -y @playwright/mcp` | None | ~1,500 tokens |
| 4 | **GitHub MCP** (`github/github-mcp-server`) | Full GitHub API: issues, PRs, code search, workflows, projects | `docker run -i --rm ghcr.io/github/github-mcp-server` (or Go binary) | GitHub PAT | ~2,000 tokens |
| 5 | **Fetch MCP** (`mcp-server-fetch`) | URL → clean markdown, respects robots.txt | `pip install mcp-server-fetch` | None | ~200 tokens |

## Phase 1 (Zero-effort, today)
```json
"mcp": {
  "memory": { "type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-memory"] },
  "sequential-thinking": { "type": "local", "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"] },
  "fetch": { "type": "local", "command": ["python", "-m", "mcp_server_fetch"] }
}
```
**3 servers, 0 API keys, ~900 tokens overhead** — instant capability gain.

## Phase 2 (API-keyed)
```json
"mcp": {
  "github": { "type": "local", "command": ["./github-mcp-server", "stdio"], "environment": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_TOKEN}" } },
  "playwright": { "type": "local", "command": ["npx", "-y", "@playwright/mcp"] }
}
```

## What Each Unlocks vs Built-in Tools

| MCP | Built-in Limitation | MCP Fix |
|-----|-------------------|---------|
| Memory | Engram is session-only, no cross-session entity graph | Persistent knowledge graph with relations and search |
| Sequential Thinking | No structured reasoning trace in logs | Auditable step-by-step with branching/revision |
| Playwright | No browser access — can't test SPAs, take screenshots, fill forms | Full browser with accessibility-tree snapshots |
| GitHub | `gh` CLI is limited to basic operations | Full API: project boards, cross-repo search, workflow triggers |
| Fetch | `webfetch` tool exists but limited | More robust URL fetching with robots.txt compliance |

## MCPs to Avoid
- **Archived reference servers** (Puppeteer, PostgreSQL, Slack, Brave, etc.) — no security updates since May 2025
- **Unverified Smithery community servers** — no security audit, can access filesystem/env
- **Docker-based MCPs on Windows without WSL2** — path translation issues with stdio
- **Any server exposing `execute_command`/`run_shell` without sandboxing** — security risk

## Token Budget Consideration
~4.4K tokens for all 5 recommended MCPs = ~2.2% of 200K context. Negligible.

## Priority Recommendation
**Start with Phase 1** (Memory + Sequential Thinking + Fetch). These 3 are zero-config, official, and directly address agent weaknesses: memory persistence and reasoning auditability. Add GitHub and Playwright when those specific capabilities are needed.
