# Completion Report — Skill Changelog Coverage 0→10 (Cycle 28 easy win, docs-only)

**Date**: 2026-08-15
**Task**: Add `changelog:` field to ALL SKILL.md frontmatters so "Skill Changelog Coverage" sub-dim goes 0→10
**Status**: COMPLETED — all verification gates passed

---

## Decision Taken

Discovered the scorer matches `-match 'changelog:'` (case-insensitive regex on full file content, `scripts/lib/score-dims.ps1:649`) — no path validation; canonical changelog path is the cycle doc `docs/ciclos/cycle28-20260815.md`. Bulk-edited 90 SKILL.md files with an EOL-preserving PowerShell script inserting `changelog: docs/ciclos/cycle28-20260815.md` before the closing `---` of each frontmatter block.

## Files Changed

- **90** `.agents/skills/*/SKILL.md` files modified (all 90, including `_shared`), each +1 line in frontmatter
- Script used: `C:\Users\MK\AppData\Local\Temp\opencode\add-skill-changelog.ps1` (one-off, EOL-preserving, idempotent)
- `.project.json` updated by the scorer itself (SD 8.2 → 8.5, `last_updated` 2026-08-15) — not touched manually
- `README.md` diff is a pre-existing working-tree change (89-skills count, already consistent before/after) — untouched

## Key Findings

1. **HIGH — Field format**: `score-dims.ps1:649` counts any file whose content matches `changelog:` (regex, case-insensitive, ANYWHERE in file — not strictly frontmatter). No path/format validation. 0/90 skills had the field before.
2. **HIGH — Denominator quirk**: `totalSkills` = 89 (excludes `_shared`, `score-dims.ps1:401`), but the changelog scan iterates ALL `skillMdFiles` including `_shared`. Adding the field to all 90 yields sub-dim = 90/89×10 = **10.1** (not 10.0) — full coverage regardless.
3. **MEDIUM — Canonical path**: No per-skill changelog history exists (0 prior `changelog:` fields repo-wide; `docs/mejoras/*.md` are analysis reports, not skill changelogs). Used `docs/ciclos/cycle28-20260815.md` (the cycle's changelog-of-record, exists on disk).
4. **Before/after**: SD 8.2 → **8.5** (+0.3, exceeds +0.24 target). Changelog sub-dim 0 → 10.1. Cross-ref: ALL 10 checks PASSED.

## Verification

- `score-auto.ps1 -Json`: Score Depth 8.2 → **8.5** (42 sub-dims), dimensions_detail.SD.s = 8.5
- Changelog sub-dim recomputed independently: 90/89 × 10 = **10.1** ✓
- `cross-ref-check.ps1`: OK ALL CHECKS PASSED (10/10)
- Git diff scope: exactly 90 SKILL.md files, single `+changelog:` line each, placement verified inside frontmatter (before closing `---`) in 3 shapes: short fm, multi-dash body (api-testing/ralph-loop), `_shared` block-style fm
- Encoding preserved: UTF-8 no-BOM (byte 0 = 45 45 45), original EOLs (CRLF and LF) preserved per file

## Nuance

- **No per-skill changelog history exists** — every skill points at the SAME cycle doc (`docs/ciclos/cycle28-20260815.md`). This is honest (it's the repo's changelog-of-record) but semantically coarse: future per-skill changelogs should be appended as arrays, e.g. `changelog: [docs/ciclos/cycle28-20260815.md, docs/mejoras/YYYY-MM-DD-*.md]`.
- **Scorer semantics**: the regex matches `changelog:` anywhere, so a mention in body prose would also count. Field placed in frontmatter per task spec — correct but stricter than the scorer requires.
- **Sub-dim = 10.1 not 10.0** due to the `_shared` numerator/denominator asymmetry in the scorer — a scoring-logic quirk, NOT a violation; full coverage achieved. Do not "fix" by removing `_shared`'s field (scanner counts it).
- `.project.json`/`README.md` were already dirty in the working tree before this task (README skill count 89 matches `totalSkills` both before and after — no README change needed).
