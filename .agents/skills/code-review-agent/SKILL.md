---
name: code-review-agent
description: "4R code review — Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar código, criticar"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - review
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.0->2.1: slim to <3KB — checklists/rules/output extracted to references/"
---

4R framework: each R scored independently, synthesized into verdict with fixes.

## When
User asks CR · pre-commit complex changes · pre-merge high-impact PRs

## The 4R Framework
| R | What it checks | Weight |
|---|---------------|--------|
| **Risk** | Error handling, edge cases, validation, nil safety, rollback, monitoring | 30% |
| **Readability** | Naming, structure, cognitive load, complexity, project patterns | 20% |
| **Reliability** | Retry/backoff, timeouts, state consistency, data integrity, error propagation | 25% |
| **Resilience** | Fault isolation, backpressure, circuit breaker, graceful degradation, recovery | 25% |

**Per-R checklist** (33 questions) → `skill_resource("code-review-agent", "references/per-r-checklist.md")`. Use BEFORE scoring.

## Workflow
`read diff → load checklist → score 4R → verdict → fixes → evidence`
**Sweet spot**: 200-400 lines. Larger → per file. Smaller → more permissive.

## Verdicts: ✅ all R≥7 | 🔶 any R 4-6 (fixable) | ❌ any R<4 or design flaw

## Output (compact)
```
## CR: {summary}
### 4R | Risk:X | Readability:X | Reliability:X | Resilience:X
Score: X.X/10 | Verdict: ✅/🔶/❌
### Fixes (line ref + what + why)
1. \`file.go:42\` — handle nil before range
### Evidence + Meta: {model} via code-review-agent v2.1
```
Full template → `references/output-template.md`

## Rules
1. Score BEFORE fixing (no anchoring). Score <5 → WHY with checklist item.
2. Clean → "Approved. No issues." Each fix: line ref + what + why.
3. Evidence for Reliability + Risk (run tests/examine error paths).
4. ≥1 fix per R <6. Any R <4 = **BLOCKER**.
5. **Model visibility**: declare model + skill version in every review.
6. Use **adaptive profile**: `mem_search("review-profile/{project}")` before, `mem_save(...)` after. Details → `references/adaptive-profile.md`.
7. Check **verifiable rules** (29 binary) before scoring → `references/verifiable-rules.md`.

## Anti-patterns
| ❌ | ✅ |
|---|-----|
| Vague "looks good" | Score + checklist evidence |
| Only praise, no critique | Balance strengths + risks |
| Skipping one R | All 4R evaluated |
| Repeated findings every session | Load profile → check prior flags |
