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

## Examples

### Example 1: Basic session-end append
```
# User ends session after: "Fix auth middleware rate limiting"
# Agent runs: bitacora --append "Fix auth middleware rate limiting"
# BITACORA.md now prepended:
2026-08-15 — Fix auth middleware rate limiting
2026-08-14 — Add Karpathy loop skill
2026-08-13 — Migrate to pnpm workspaces
```

### Example 2: Keyword search across entries
```
User: bitacora --search "auth"
Output:
2026-08-15 — Fix auth middleware rate limiting
2026-08-10 — Add JWT refresh token rotation
2026-08-05 — Harden login CSRF protection
See mem_search('auth') for full context
```

### Example 3: Date-range filter
```
User: bitacora --since 2026-08-01
Output:
2026-08-15 — Fix auth middleware rate limiting
2026-08-14 — Add Karpathy loop skill
2026-08-13 — Migrate to pnpm workspaces
2026-08-10 — Add JWT refresh token rotation
2026-08-05 — Harden login CSRF protection
```

### Example 4: Combined search + date filter
```
User: bitacora --search "pnpm" --since 2026-08-01
Output:
2026-08-13 — Migrate to pnpm workspaces
See mem_search('pnpm') for full context
```

### Example 5: Empty/missing BITACORA.md auto-creation
```
# First session in new project, no BITACORA.md exists
User: bitacora --append "Initial project setup"
# Agent creates BITACORA.md:
# Bitácora
2026-08-16 — Initial project setup
```

## Testing Patterns

### Pattern 1: Append & Verify (Golden Path)
```
# Given: BITACORA.md exists with 3 entries
# When: bitacora --append "New feature X"
# Then: BITACORA.md has 4 entries, new entry at top, date is today
# Verify: grep -c "^2026-" BITACORA.md == 4
```

### Pattern 2: Search Relevance
```
# Given: BITACORA.md with 10 entries (3 containing "docker")
# When: bitacora --search "docker"
# Then: Returns exactly 3 entries, all contain "docker" (case-insensitive)
# Verify: output lines == 3; each line =~ /docker/i
```

### Pattern 3: Date Filter Boundaries
```
# Given: Entries on 2026-08-01, 2026-08-15, 2026-08-31
# When: bitacora --since 2026-08-15
# Then: Returns entries from 2026-08-15 and 2026-08-31 (inclusive)
# When: bitacora --since 2026-09-01 (future)
# Then: "No entries after 2026-09-01"
# Verify: boundary inclusive on --since date
```

## Edge Cases

### Edge Case 1: Special regex characters in search
```
User: bitacora --search "C++"
# Implementation: Escape special chars before grep: "C\+\+"
# Result: Matches literal "C++" not regex "C followed by one-or-more"
```

### Edge Case 2: BITACORA.md locked by another process
```
# When: File is write-locked (e.g., editor open with unsaved changes)
# Then: Warn user: "BITACORA.md locked — entry not appended"
# Log to stderr, do not crash session
```

### Edge Case 3: Concurrent sessions appending same day
```
# Session A appends at 10:00, Session B appends at 10:05
# Both see last entry date = today
# Deduplication: Check last entry date before append
# If same date + similar description (>80% similarity) → skip append, warn
```

### Edge Case 4: BITACORA.md exceeds 100 entries
```
# When: Entry count > 100 after append
# Then: Append succeeds + show suggestion:
# "Bitácora has 101 entries. Consider archiving to BITACORA.archive.md"
# Archive: mv BITACORA.md BITACORA.archive.md; create fresh with header
```

### Edge Case 5: Invalid date format in --since
```
User: bitacora --since "august 1 2026"
# Then: "Invalid date format. Use YYYY-MM-DD (e.g., 2026-08-01)"
# No entries returned, no crash
```

### Edge Case 6: Empty BITACORA.md (0 bytes, not missing)
```
# File exists but 0 bytes (corrupted/partial write)
# Treat as missing: overwrite with header + first entry
# Do not preserve empty file
```

## Anti-Patterns

1. **Write novel-length entries** — One line max. Detail goes to Engram via `mem_save_prompt`.
2. **Edit past entries** — Immutable log. Only prepend.
3. **Skip session-end append** — Auto-trigger is mandatory. If skipped, history is lost.
4. **Use bitacora for debug logs** — It's for user requests only. Debug→application logs.
5. **Duplicate entries on re-run** — Idempotent append: check last entry date+desc before writing.
6. **Rely ONLY on bitacora for cross-session context** — BITACORA.md is per-project summary. Cross-session uses Engram (`mem_search`).

## Refs
dreaming · session-resume · immune-system · auto-metrics · bitacora · engram