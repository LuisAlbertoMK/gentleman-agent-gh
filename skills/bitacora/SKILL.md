---
name: bitacora
description: >
  bitacora skill
triggers: "Bitacora, historial, histórico, qué pedí, request log"
  Historical log of user requests per session. Auto-append on session end.
  Trigger: "bitacora", "historial", "histórico", "peticiones", "qué pedí", "request log".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## When
- User asks "qué pedí", "bitácora", "historial", "request log"
- Session end: auto-append entry to `BITACORA.md`

## Critical Patterns

### Entry format (appended to BITACORA.md)
```
YYYY-MM-DD — {short description, max 1 line}
```
Example: `2026-06-06 — Skill metricas + tokenización + 6 tools nuevas`

### Auto-trigger
After session end: prepend new entry to `BITACORA.md`.

### Query commands
| Command | Action |
|---------|--------|
| `bitacora` | show full log |
| `bitacora --search "Karpathy"` | grep for keyword |
| `bitacora --since 2026-06-01` | entries after date |

### Rules
1. 1 line per entry. If more detail needed → engram has it.
2. Never edit past entries — only prepend new ones.
3. `mem_save_prompt` is for Engram (machine-readable). BITACORA.md is summary (human-readable). Both coexist.

