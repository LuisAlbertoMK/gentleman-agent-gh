# MCP Server Survey — July 2026

> **Context**: Current tool budget 23/50 used (engram 18 + context7 2 + sequential-thinking 3).  
> **27 tools remaining** for new servers.  
> **Cross-ref**: MCP Security Checkpoint → `docs/operations/mcp-security-checkpoint.md` (verified by 3 subagents).  
> **⚠️ Tool counts from Security Checkpoint §5.5 & §6.3** — verified by 3 subagent audit.

## Priority Order (MUST first)

| # | MCP | Tools* | Risk | Install | Why |
|---|-----|--------|------|---------|-----|
| P1 | **Filesystem** | ~9 | 🟡 | `npx @modelcontextprotocol/server-filesystem` | Scoped file read/write/search — complements native tools |
| P2 | **Git** | ~6 | 🟡 | `uvx mcp-server-git` | Local git ops: diff, log, status, stage, commit |
| P3 | **GitHub** | ~56 | 🟡 (conditional)** | `npx @github/mcp-server` | ⚠️ **NO-GO per Security Gate** — exceeds 50 tool budget by 52% even alone. Needs Dynamic Tool Loading. PAT scopes: minimum `repo+read:org`. |
| P4 | **Fetch** | ~1 | 🟡 | `npx @modelcontextprotocol/server-fetch` | Web content → Markdown. 🟡 Medio (SSRF vector — see checkpoint §4.2). |
| P5 | **Playwright** | ~22 | 🟡 | `npx @playwright/mcp@latest` | Browser automation. Only if on-demand activation available. |
| P6 | **Brave Search** | ~2 | 🟢 | `npx @anthropic-ai/brave-search-mcp-server` | Web + local search via Brave Search API (free tier). |

> *Tool counts from Security Checkpoint §5.5 (verified by 3 subagents). GitHub MCP exposes 56 tools, not 9 — the official server covers issues, PRs, repos, actions, search, code, and more.  
> **GitHub MCP risk is conditional on PAT scope: 🟢 with `repo+read:org`, 🟡 with `workflow`, 🔴 with `admin:org`/`delete_repo`.

## Budget Math

| Scenario | Tools | Total | Verdict |
|----------|-------|-------|---------|
| Filesystem + Git | 9+6 = 15 | 38/50 | ✅ Viable |
| + Fetch + Brave Search | 15+1+2 = 18 | 41/50 | ✅ Comfortable |
| + Playwright | 18+22 = 40 | 63/50 | ❌ OVER BUDGET |
| + GitHub | 40+56 = 96 | 119/50 | ❌ WAY OVER |
| Realistic max (FS+Git+F+BS) | 9+6+1+2 = 18 | 41/50 | ✅ **Recommended** |

## Decision

**Install now**: Filesystem + Git (15 tools → 38/50). Covers local dev loop.  
**Next batch**: Fetch + Brave Search (+3 → 41/50, comfortable).  
**On-demand only**: Playwright (22 tools, needs budget review).  
**BLOCKED**: GitHub MCP (56 tools, exceeds budget — needs OpenCode Dynamic Tool Loading).

## Security Notes

- All `npx -y` servers fetch+execute on every launch — pin versions (`@1.2.3`) in prod
- GitHub PAT scopes: minimum `repo + read:org`, NEVER `workflow`/`admin:org`/`delete_repo`
- Filesystem allow-list = project root only, never home dir (mitigation against supply chain)
- Fetch risk: 🟡 Medio (SSRF — can access localhost). Acceptable for personal repo.
- 52% of remote MCP endpoints are dead (Apr 2026 audit) — prefer local STDIO
- Security Gate process in `docs/operations/mcp-security-checkpoint.md` §6 — mandatory before any install
