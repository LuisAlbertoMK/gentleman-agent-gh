---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histórico, qué pedí, request log"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1395
---

Historical log of user requests per session. Auto-append on session end.
Trigger: "bitacora", "historial", "histórico", "peticiones", "qué pedí", "request log".

## When to Use
- User asks "qué pedí", "bitácora", "historial", "request log"
- Session end: auto-append entry to `BITACORA.md`

## Entry Format
```
YYYY-MM-DD — {short description, max 1 line}
```

## Auto-trigger
After session end: prepend new entry to `BITACORA.md`.

## Rules
1. 1 line per entry. More detail→engram.
2. Never edit past entries—only prepend new.
3. `mem_save_prompt` for Engram. BITACORA.md is summary. Both coexist.
4. BITACORA.md missing→create with `# Bitácora` header + first entry.
5. Empty BITACORA.md (0 bytes)→treat as missing, create fresh.
6. `--since` with date before first entry→show all. Future date→"No entries after YYYY-MM-DD".
7. **C28**: Idempotent append — check last entry date+description similarity (>80%) before writing to prevent duplicates across concurrent sessions.
8. **C28**: Archive suggestion at >100 entries — `mv BITACORA.md BITACORA.archive.md` + fresh header.
---

docs/skills/bitacora/reference.md
---
