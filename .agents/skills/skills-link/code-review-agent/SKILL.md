---
name: code-review-agent
description: "4R code review — Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar código, criticar"
license: Apache-2.0
metadata:
  tags: [engineering, review]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.2: karpathy compress"
---
4R framework: each R scored independently, synthesized into verdict with fixes.
## When: User asks CR · pre-commit complex · pre-merge high-impact PRs
## The 4R Framework
| R | Focus | Weight |
|---|-------|--------|
| Risk | Error handling, edge cases, validation, nil safety, rollback, monitoring | 30% |
| Readability | Naming, structure, cognitive load, complexity, project patterns | 20% |
| Reliability | Retry/backoff, timeouts, state consistency, data integrity, error propagation | 25% |
| Resilience | Fault isolation, backpressure, circuit breaker, graceful degradation, recovery | 25% |
## Workflow: `read diff → score 4R → verdict → fixes → evidence`. Sweet spot: 200-400L.
## Verdicts: ✅ all R≥7 · 🔶 any R 4-6 · ❌ any R<4 or design flaw
## Output (compact)
```
## CR: {summary}
### 4R | Risk:X | Readability:X | Reliability:X | Resilience:X | Score: X.X/10 | Verdict: ✅/🔶/❌
### Fixes: line-ref + what + why (1. file.go:42 — handle nil before range)
```
## Rules
1. Score BEFORE fixing (no anchoring). Score<5 → WHY with checklist item.
2. Clean → "Approved. No issues."
3. Evidence for Reliability+Risk (run tests/examine error paths).
4. ≥1 fix per R<6. Any R<4 = **BLOCKER**.
5. **Model visibility**: declare model + version in every review.
6. **Adaptive profile**: `mem_search("review-profile/{project}")` before, `mem_save(...)` after.
7.
## Anti-patterns: Vague "looks good" · Only praise no critique · Skipping one R · Repeated findings every session
