---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histÃ³rico, quÃ© pedÃ­, request log"
license: Apache-2.0
metadata:
  tags:
    - content
  author: gentleman-vMK
  version: "1.0"
---

Historical log of user requests per session. Auto-append on session end.Trigger: "bitacora", "historial", "histÃ³rico", "peticiones", "quÃ© pedÃ­", "request log".
## When- User asks "quÃ© pedÃ­", "bitÃ¡cora", "historial", "request log"- Session end: auto-append entry to `BITACORA.md`
## Critical Patterns
### Entry format (appended to BITACORA.md)
```YYYY-MM-DD â€” {short description, max 1 line}```Example: `2026-06-06 â€” Skill metricas + tokenizaciÃ³n + 6 tools nuevas`
### Auto-triggerAfter session end: prepend new entry to `BITACORA.md`.
### Query commands| Command | Action ||---------|--------|| `bitacora` | show full log || `bitacora --search "Karpathy"` | grep for keyword || `bitacora --since 2026-06-01` | entries after date |
### Rules1. 1 line per entry. If more detail needed â†’ engram has it.2. Never edit past entries â€” only prepend new ones.3. `mem_save_prompt` is for Engram (machine-readable). BITACORA.md is summary (human-readable). Both coexist.
