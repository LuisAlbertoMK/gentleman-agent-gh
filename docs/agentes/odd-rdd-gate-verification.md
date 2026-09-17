# ODD/RDD Gate Verification Report

**Date**: 2026-09-17  
**Artifacts verified**: odd/SKILL.md, odd/reference.md, rdd/SKILL.md, rdd/reference.md, scripts/odd-freeze.ps1, SKILLS-INDEX.md

## Gate Results

| Gate | Status | Detail |
|------|--------|--------|
| 1. Cross-refs | ✅ PASS | `cross-ref-check.ps1` — canonicalSkills: 96, brokenCrossRefs: 0. Warning: "Missing junctions: odd, rdd" (pre-existing infra, not artifact-caused) |
| 2. Token budget | ✅ PASS (after fix) | odd/SKILL.md: 2654B ≤ 3072B ✓, rdd/SKILL.md: 3072B ≤ 3072B ✓ (was 3142B, fixed), odd/reference.md: 93L ≤ 200L ✓, rdd/reference.md: 120L ≤ 180L ✓, odd-freeze.ps1: 55L ≤ 80L ✓ |
| 3. PS syntax | ✅ PASS | PSParser: 0 errors. No `&&`, `||`, or PS7-only syntax. 5.1-safe. |
| 4. Frontmatter | ✅ PASS | odd: name/description("Organic Driven Development")/triggers/changelog/token_budget ✓. rdd: name/description("Receipt-Driven Development")/triggers/changelog/token_budget ✓ |
| 5. SKILLS-INDEX.md | ✅ PASS | Version 5.7 ✓, count 96 ✓, odd in Coordination group ✓, rdd in Quality group ✓ |
| 6. Token budget script | ✅ PASS | `check-token-budget.ps1` — "OK Token budget: skills 2592B/3200 (avg), prompts 1199B/4000 (avg), H-019 overweight penalty 0" |

## Fixes Applied (artifact-caused)

1. **rdd/SKILL.md — byte reduction** (3142B → 3072B, -70B):
   - Line 3: Trimmed " Opt-in, risk-tiered." from description (-21B)
   - Line 10: Trimmed " Disable per scope." (-19B)
   - Line 25: Trimmed " — reviewers see real diff" (-28B)
   - Line 84: Fixed cross-ref separator `*` → ` | ` (+6B, format fix for cross-ref-check.ps1 parser)
   - Line 87: Shortened reference path to `{file:rdd/reference.md}` format (-8B)
   - Net: -70B exactly at limit

## Pre-existing Infra Issues (NOT touched)

1. **Missing junctions: odd, rdd** — cross-ref-check.ps1 warns about missing junction/symlink files in `.opencode/skills/`. This is repo infrastructure (junction creation), not an artifact issue. Reported as-is.
