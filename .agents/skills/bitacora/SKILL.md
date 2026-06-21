---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histórico, qué pedí, request log"
license: Apache-2.0
metadata:
  tags:
    - content
  author: gentleman-vMK
  version: "1.0"
---

Historical log of user requests per session. Auto-append on session end.Trigger: "bitacora", "historial", "histórico", "peticiones", "qué pedí", "request log".
## When- User asks "qué pedí", "bitácora", "historial", "request log"- Session end: auto-append entry to `BITACORA.md`
## Critical Patterns
### Entry format (appended to BITACORA.md)
```YYYY-MM-DD — {short description, max 1 line}```Example: `2026-06-06 — Skill metricas + tokenización + 6 tools nuevas`
### Auto-triggerAfter session end: prepend new entry to `BITACORA.md`.
### Query commands| Command | Action ||---------|--------|| `bitacora` | show full log || `bitacora --search "Karpathy"` | grep for keyword || `bitacora --since 2026-06-01` | entries after date |
### Rules1. 1 line per entry. If more detail needed → engram has it.2. Never edit past entries — only prepend new ones.3. `mem_save_prompt` is for Engram (machine-readable). BITACORA.md is summary (human-readable). Both coexist.
## EXAMPLE
```
2026-06-19 — Enriched 24 skills with references and expanded docs
2026-06-18 — Configured 3 subagents with free Zen models
```
## EDGE CASES
- Empty BITACORA.md → create with header "# Bitácora" + first entry
- Search across sessions: BITACORA.md only covers current project — cross-session search uses Engram
- `--since` accepts ISO dates only (YYYY-MM-DD)
