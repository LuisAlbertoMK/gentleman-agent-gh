# bitacora — Reference Materials

> **Externalized from** .agents/skills/bitacora/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
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

### Example 6: C28 — Parallel subagent session logging
```
# Cycle 28: 3 parallel subagents (Security, Skill Compression, Branch Hygiene)
# Each subagent session logs independently
Session A (Security): bitacora --append "C28: Replace MD5 with SHA256 in delegation-registry"
Session B (Compression): bitacora --append "C28: Karpathy compress lean-context 3225→2658B"
Session C (Branches): bitacora --append "C28: Classify 3 stale branches, delete 2, keep 1"

# BITACORA.md after all three (same day, deduplicated by similarity check):
2026-08-15 — C28: Classify 3 stale branches, delete 2, keep 1
2026-08-15 — C28: Karpathy compress lean-context 3225→2658B
2026-08-15 — C28: Replace MD5 with SHA256 in delegation-registry
# Note: Similarity check prevents duplicate "C28:" prefix entries on same day
```

### Example 7: C28 — Score dimension recovery tracking
```
# Tracking score recovery across cycles
User: bitacora --search "Security" --since 2026-08-01
Output:
2026-08-15 — C28: Security 8.0→10.0 (weak_crypto MD5→SHA256)
2026-08-10 — C27: Security audit - weak_crypto detected
2026-08-05 — C26: Add crypto scanner to pre-commit
See mem_search('Security score') for full context
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

### Pattern 4: C28 — Concurrent Session Idempotency
```
# Given: BITACORA.md last entry "2026-08-15 — C28: Security fix"
# When: Session A appends "C28: Security hardening" at 10:00
# And: Session B appends "C28: Security fix applied" at 10:05
# Then: Only ONE entry added (similarity >80% on same date)
# Verify: grep -c "2026-08-15" BITACORA.md increases by 1 only
# Verify: stderr contains "Duplicate suppressed: similar entry exists for 2026-08-15"
```

### Pattern 5: C28 — Archive Threshold Trigger
```
# Given: BITACORA.md has 100 entries
# When: bitacora --append "Entry 101"
# Then: Entry appended + suggestion shown
# Verify: "Bitácora has 101 entries. Consider archiving to BITACORA.archive.md"
# Verify: mv BITACORA.md BITACORA.archive.md creates archive with all 101 entries
# Verify: New BITACORA.md has only "# Bitácora" header
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

### Edge Case 7: C28 — Cross-repo bitacora merge
```
# User works in two repos: gentleman-agent-gh + gentle-orchestrator
# Both have BITACORA.md
# bitacora --search "C28" searches current project only
# For cross-repo: bitacora --search "C28" --all-projects (future)
# Current workaround: mem_search("C28") searches Engram cross-project
```

### Edge Case 8: C28 — Unicode/emoji in description
```
User: bitacora --append "Fix auth 🔒 rate limiting"
# Then: Stored as-is (UTF-8), search works: bitacora --search "🔒"
# grep -P requires -a flag for binary detection — use ripgrep (rg) instead
```

## Anti-Patterns

1. **Write novel-length entries** — One line max. Detail goes to Engram via `mem_save_prompt`.
2. **Edit past entries** — Immutable log. Only prepend.
3. **Skip session-end append** — Auto-trigger is mandatory. If skipped, history is lost.
4. **Use bitacora for debug logs** — It's for user requests only. Debug→application logs.
5. **Duplicate entries on re-run** — Idempotent append: check last entry date+desc before writing.
6. **Rely ONLY on bitacora for cross-session context** — BITACORA.md is per-project summary. Cross-session uses Engram (`mem_search`).
7. **C28: Skip verification after parallel subagent work** — Each subagent must append; orchestrator must verify all 3 entries present (Cycle 28 had 3 parallel subagents).
8. **C28: Treat archive as deletion** — Archive preserves history. `BITACORA.archive.md` is queryable with `bitacora --file BITACORA.archive.md --search "..."`.

## Cross-Refs: dreaming | session-resume | immune-system | auto-metrics | bitacora | engram-protocol
