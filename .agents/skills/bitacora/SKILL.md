---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histórico, qué pedí, request log"
changelog: docs/ciclos/cycle28-20260815.md
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

## Query Commands
| Command | Action |
|---------|--------|
| `bitacora` | show full log |
| `bitacora --search "Karpathy"` | grep for keyword |
| `bitacora --since 2026-06-01` | entries after date |
| `bitacora --append "Fix auth middleware"` | manual append |
| `bitacora --stats` | entry count, date range, top keywords |

### Search example
User: `bitacora --search "auth"` → entries matching "auth". No matches→`"No entries matching 'auth' in BITACORA.md"`.

### Cross-session search
`bitacora --search "metrics"`→BITACORA.md + `mem_search("metrics")`→Engram. Both results shown.

### Integration with Engram
1. `mem_save_prompt` captures full request→Engram (machine-readable, cross-session)
2. `bitacora --append` writes 1-line→BITACORA.md (human-readable, per-project)
3. `bitacora --search "keyword"` returns matches + suggestion: `"See mem_search('keyword') for full context"`

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

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/bitacora/reference.md

---
