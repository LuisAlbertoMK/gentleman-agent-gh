---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histórico, qué pedí, request log"
license: Apache-2.0
metadata:
  tags:
    - content
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: enriched with concrete search examples, engram integration flow, edge cases"
---

Historical log of user requests per session. Auto-append on session end.
Trigger: "bitacora", "historial", "histórico", "peticiones", "qué pedí", "request log".

## When
- User asks "qué pedí", "bitácora", "historial", "request log"
- Session end: auto-append entry to `BITACORA.md`

## Critical Patterns

### Entry format (appended to BITACORA.md)
```text
YYYY-MM-DD — {short description, max 1 line}
```

Examples:
```
2026-06-06 — Skill metricas + tokenización + 6 tools nuevas
2026-06-19 — Enriched 24 skills with references and expanded docs
2026-06-20 — Auth hardening audit on API gateway (3 high findings)
```

### Auto-trigger
After session end: prepend new entry to `BITACORA.md`.

### Query commands
| Command | Action |
|---------|--------|
| `bitacora` | show full log |
| `bitacora --search "Karpathy"` | grep for keyword |
| `bitacora --since 2026-06-01` | entries after date |

### Search with results example
User: `bitacora --search "auth"`

Response:
```
2026-06-20 — Auth hardening audit on API gateway (3 high findings)
2026-06-15 — Added JWT refresh rotation to auth middleware
2026-06-10 — Auth testing: session expiry edge case fixed
```
If no matches: `"No entries matching 'auth' in BITACORA.md"`.

### Cross-session search
User: `qué pedí la semana pasada sobre metrics?`

Flow: `bitacora --search "metrics"` → hits BITACORA.md → then `mem_search("metrics")` → hits Engram for deeper context from prior sessions. Both results shown.

### Integration with Engram
1. `mem_save_prompt` captures full user request → Engram (machine-readable, cross-session)
2. `bitacora --append` writes 1-line summary → BITACORA.md (human-readable, per-project)
3. `bitacora --search "keyword"` returns BITACORA.md matches + suggestion: `"See mem_search('keyword') for full context"`

### Rules
1. 1 line per entry. If more detail needed → engram has it.
2. Never edit past entries — only prepend new ones.
3. `mem_save_prompt` is for Engram (machine-readable). BITACORA.md is summary (human-readable). Both coexist.
4. When BITACORA.md doesn't exist: `"No BITACORA.md found. Creating with header + first entry."` Then create with `# Bitácora` header and current entry.
5. If BITACORA.md exists but is empty (0 bytes): treat as missing, create fresh with header.
6. On `--since` with date before first entry: show all entries. With future date: `"No entries after YYYY-MM-DD"`.

## EDGE CASES
- Empty BITACORA.md → create with `# Bitácora` header + first entry
- BITACORA.md doesn't exist → create it, same as empty
- Search across sessions: BITACORA.md only covers current project — cross-session search uses Engram
- `--since` accepts ISO dates only (YYYY-MM-DD)
- `--since` with future date → no matches, explain
- `--search` with special regex chars → escape before grep (`[`, `*`, etc.) to avoid false positives
- Project dir has no BITACORA.md but `.opencode/` exists → create at project root, not in .opencode
- Concurrent sessions (rare) → each session appends; deduplicate by checking last entry date before writing
- Multiple `--search` + `--since` flags → AND logic: entries matching keyword AND after date
- File locked by another process → warn and skip append, log to stderr
- BITACORA.md grows >100 entries → suggest archival: `"Bitácora has N entries. Consider archiving old entries to BITACORA.archive.md"`

## Refs
dreaming · session-resume · immune-system · auto-metrics · bitacora · engram

## Anti-Patterns
Write novel-length entries · Edit past entries · Skip session-end append · Use bitacora for debug logs · Duplicate entries on re-run · Rely ONLY on bitacora for cross-session context
