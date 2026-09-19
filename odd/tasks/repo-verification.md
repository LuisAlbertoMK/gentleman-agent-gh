# ODD: repo-verification

> status: active | created: 2026-09-17 | owner: user | confidence: medium

## Intent

Full-repo verification audit under ODD/RDD criteria: find real problems across gentleman-agent-gh — not cosmetic issues, not new features, not suggestions. Report evidence with file:line and severity. This is the durable doc that carries the audit across sessions.

## Scope In

| Cluster | What to Audit | Why It Matters |
|---------|---------------|----------------|
| 1. Skills frontmatter + budgets | All skills in `.agents/skills/` and `~/.config/opencode/skills/` — validate frontmatter schema, token budgets, trigger consistency, cross-references | Broken frontmatter = invisible skills or wrong routing |
| 2. Scripts PS5.1-safety + side effects | All `scripts/*.ps1` — check for `&&`, `||`, raw bash, destructive side effects on dry-run, encoding | PS 5.1 rejects bash operators; silent failures in prod |
| 3. Junctions .opencode/skills + registry | Verify junction points where skill definitions meet config — registry consistency, missing skills, orphan entries | Junctions are where the system breaks first |
| 4. Security surface | Secrets in commits/history, injection patterns, file permissions, API key exposure, credential leaks | One leaked key = full audit trail compromised |
| 5. Docs staleness | Counts in ARCHITECTURE.md, SKILLS-INDEX.md vs actual file reality — dead links, wrong numbers, stale references | Stale docs erode trust in the system |
| 6. Pester test coverage | Tests that cover the above clusters — verify they exist, pass, and actually assert | Untested code is untrusted code |

## Scope Out

- New features or feature requests
- Refactors (beyond flagging broken things)
- Telemetry, analytics, RTK
- Push operations or git automation
- Performance optimization

## Slice Plan

| # | Cluster | Est. Lines | Preset | Deliverable |
|---|---------|-----------|--------|-------------|
| 1 | Skills frontmatter + budgets | ~150L audit report | P1 (analysis) | file:line findings with severity per skill |
| 2 | Scripts PS5.1-safety | ~80L audit report | P1 (analysis) | dangerous patterns catalog |
| 3 | Junctions .opencode + registry | ~60L audit report | P1 (analysis) | orphan/missing entry list |
| 4 | Security surface | ~100L audit report | P1 (analysis) | secrets + injection findings |
| 5 | Docs staleness | ~70L audit report | P1 (analysis) | count mismatches, dead refs |
| 6 | Pester test coverage | ~50L audit report | P1 (analysis) | coverage gaps vs clusters 1-5 |

**Total est. lines: ~510L** (all read-only audit reports, zero code changes)

**Preset: P1 (analysis)** — all slices are read-only investigation. Agent routes to analysis agent. No code written, no files modified, no commits.

## Verification

- [ ] Slice 1: every skill frontmatter field validated against schema
- [ ] Slice 2: every script checked for PS5.1-forbidden patterns
- [ ] Slice 3: registry cross-referenced against actual skill dirs
- [ ] Slice 4: secrets scan + injection pattern scan complete
- [ ] Slice 5: SKILLS-INDEX.md count matches reality
- [ ] Slice 6: Pester tests exist for each cluster's audit scope
- [ ] Each finding has: file path, line number, severity (CRITICAL/HIGH/MEDIUM/LOW), evidence
- [ ] No findings without evidence — every claim backed by file:line

## Review Log

| Date | Slice | Reviewer | Verdict | Notes |
|------|-------|----------|---------|-------|
| — | — | — | — | Awaiting execution |

## Rollback

N/A — this is a read-only audit. No code changes are applied during the audit itself. Fixes are proposed in findings and executed in a separate session after review.

---

**Next session**: Load this doc → start at Slice 1 → proceed sequentially → each slice produces a 4-field report (Decision Taken | Files Changed | Key Findings | Nuance). Accumulate findings into this doc under a new `## Findings` section after execution begins.
