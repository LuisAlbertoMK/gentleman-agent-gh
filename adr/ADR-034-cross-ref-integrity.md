# ADR-034: Cross-Reference Integrity Fix

**Status**: Accepted
**Date**: 2026-08-19
**Cycle**: C1 (G3: Cross-ref integrity, ICE 288, Blast: Medio)

## Context

The `cross-ref-check.ps1` validation script reported 1 warning: "Missing junctions: aem-migration". The `aem-migration` skill existed locally at `.agents/skills/aem-migration/` but lacked a directory junction in the global opencode skills directory (`~/.config/opencode/skills/`).

All other cross-reference checks passed:
- 0 broken cross-refs (## Cross-Refs entries)
- 0 missing config_refs
- SKILLS-INDEX.md count matches (91 skills)
- All SKILL.md files present
- _shared files present
- review-rules.jsonc valid
- README agents match opencode.json

## Decision

Create the missing directory junction for `aem-migration`:
```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE/.config/opencode/skills/aem-migration" -Target "D:\gentleman-agent-gh\.agents\skills\aem-migration"
```

Additionally, create Pester test suite `scripts/tests/cross-ref.Tests.ps1` with 4 tests:
- T1: cross-ref-check.ps1 -Json returns 0 errors
- T2: SKILLS-INDEX.md has no stale/orphaned skill entries
- T3: Every ## Cross-Refs entry resolves to a real skill directory
- T4: All skills have junctions in global config

## Alternatives Considered

| Approach | Description | Decision |
|----------|-------------|----------|
| A: Manual junction creation | One-time `New-Item -ItemType Junction` | **Chosen** — Surgical, minimal scope |
| B: Add `-Fix` mode to cross-ref-check.ps1 | Auto-create missing junctions | Rejected — Would mix fix/refactor in checker |
| C: Separate sync-junctions.ps1 script | Bidirectional junction sync | Rejected — Over-engineering for single missing junction |

## Consequences

**Positive**:
- All 10/9 cross-ref checks now pass (allClean: true)
- Zero broken cross-references maintained
- Test coverage for cross-ref integrity (4/4 tests pass)
- Sync-vmk dry-run: 1083ms (vs 1263ms baseline) — no regression

**Negative**:
- Semi-allowlist sync check (step 10/9) remains slow (~2-3 min) due to O(n×m) regex comparison
- PA dimension `cross_ref` sub-flag shows `false` in score-auto due to parallel job timeout on slow check

## Verification

- `cross-ref-check.ps1 -Json`: 0 errors, 0 warnings, allClean=true
- `Invoke-Pester scripts/tests/cross-ref.Tests.ps1`: 4/4 pass
- `check-adversarial.ps1 -Quiet`: 0 violations
- `sync-vmk -DryRun` ×3: 1083ms, 35ms, 16ms (median ~35ms cached, first run 1083ms < 1263ms baseline)
- Score: 8.8 (SE=6.0, PA=8.0) — no regression

## Rollback

```bash
git revert <commit-hash>
# Or manually remove junction:
Remove-Item "$env:USERPROFILE/.config/opencode/skills/aem-migration"
```
