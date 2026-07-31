---
name: bitacora
description: "Historical log of user requests per session — auto-append to BITACORA.md, search, date filtering"
triggers: "Bitacora, historial, histórico, qué pedí, request log"
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

## Edge Cases
- Empty/missing BITACORA.md→create with `# Bitácora` header + first entry
- Cross-session: BITACORA.md covers current project only; cross-session uses Engram
- `--since` accepts ISO dates only (YYYY-MM-DD)
- `--since` future date→no matches, explain
- `--search` with special regex chars→escape before grep (`[`, `*`, etc.)
- No BITACORA.md but `.opencode/` exists→create at project root, not .opencode
- Concurrent sessions→each appends; deduplicate by checking last entry date
- Multiple `--search`+`--since`→AND logic
- File locked→warn and skip, log to stderr
- BITACORA.md >100 entries→suggest archival: `"Bitácora has N entries. Consider archiving to BITACORA.archive.md"`

## Refs
dreaming · session-resume · immune-system · auto-metrics · bitacora · engram

## Anti-Patterns
Write novel-length entries·Edit past entries·Skip session-end append·Use bitacora for debug logs·Duplicate entries on re-run·Rely ONLY on bitacora for cross-session context
