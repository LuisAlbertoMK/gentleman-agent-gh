---
name: code-review-agent
description: "4R code review — Risk/Readability/Reliability/Resilience with evidence gates and actionable fixes"
triggers: "Code review, CR, revisar código, criticar"
---

4R framework: each R scored independently, synthesized into verdict with fixes.

## When
User asks CR · pre-commit complex · pre-merge high-impact PRs

## The 4R Framework
| R | Focus | Weight |
|---|-------|--------|
| Risk | Error handling, edge cases, validation, nil safety, rollback, monitoring | 30% |
| Readability | Naming, structure, cognitive load, complexity, project patterns | 20% |
| Reliability | Retry/backoff, timeouts, state consistency, data integrity, error propagation | 25% |
| Resilience | Fault isolation, backpressure, circuit breaker, graceful degradation, recovery | 25% |

## Workflow
`read diff → score 4R → verdict → fixes → evidence`. Sweet spot: 200-400L.

## Verdicts
- ✅ all R≥7
- 🔶 any R 4-6
- ❌ any R<4 or design flaw

## Output (compact)
```
## CR: {summary}
### 4R | Risk:X | Readability:X | Reliability:X | Resilience:X | Score: X.X/10 | Verdict: ✅/🔶/❌
### Fixes: line-ref + what + why (1. file.go:42 — handle nil before range)
```

### Full output example
```
## CR: API auth middleware — missing nil check + no rate limit
### 4R | Risk:3 | Readability:7 | Reliability:5 | Resilience:4 | Score: 4.8/10 | Verdict: ❌ BLOCKER
### Fixes
1. src/middleware/auth.go:42 — `user, err := db.FindUser(id)` — err not checked → Risk BLOCKER
   - Fix: `if err != nil { return nil, fmt.Errorf("find user: %w", err) }`
   - Evidence: err is silently swallowed; if db is down, handler proceeds with nil user
2. src/middleware/auth.go:67 — `db.Query("SELECT ...")` — no timeout on DB call → Reliability
   - Fix: add context.WithTimeout 5s to all queries
3. src/middleware/ratelimit.go:12 — rate limit hardcoded to 1000 req/s → Resilience
   - Fix: make configurable via env var, default 100, add sliding window
4. src/middleware/auth.go:88 — `log.Printf("auth failed: %v", err)` — logs sensitive data → Risk
   - Fix: sanitize error before logging
### Model: claude-4-opus-20260514
```

## Adaptive Profile Flow
```
1. mem_search("review-profile/{project}") — load past CR patterns for this project
   - Found: "previous review flagged missing context deadlines in this team"
   - → Adjust: be explicit about context propagation patterns
2. Run 4R review with adjusted lens
3. mem_save(title: "CR profile — {project} #{N}", type: pattern, topic_key: "review-profile/{project}")
   - Content: what was flagged, what was accepted, team response patterns
   - → Next review loads this profile automatically
```

## Rules
1. Score BEFORE fixing (no anchoring). Score<5 → WHY with checklist item.
2. Clean → "Approved. No issues."
3. Evidence for Reliability+Risk (run tests/examine error paths).
4. ≥1 fix per R<6. Any R<4 = **BLOCKER**.
5. **Model visibility**: declare model + version in every review.
6. **Adaptive profile**: `mem_search("review-profile/{project}")` before, `mem_save(...)` after.
7. **Scope detection**: diff <50L → surface-read (fast track). diff >400L → flag as "large CR, suggest splitting into 2+ reviews for full depth"
8. **Evidence chain for BLOCKER**: (a) locate exact line, (b) trace the vulnerability path, (c) reference language/runtime behavior, (d) propose concrete fix. Every BLOCKER must have all 4 links.

## BLOCKER evidence chain example
```
BLOCKER: src/handler/order.go:88 — `rows, _ := db.Query(...)`
  Evidence chain:
  1. Line 85: `func GetOrders() ([]Order, error)` — returns error
  2. Line 88: error discarded with `_` → callers get zero Orders
  3. Line 92: caller treats empty `[]Order{}` as "no data" not "db error"
  4. Line 95: UI shows empty state instead of error toast
  Impact: silent data loss when Postgres is unreachable.
  Fix: `rows, err := db.Query(...)` + propagate error up
```

## Anti-patterns
Vague "looks good" · Only praise no critique · Skipping one R · Repeated findings every session · BLOCKER without evidence chain · Ignoring project conventions from adaptive profile · Reviewing >400L diffs as single unit

## Refs
judgment-day · senior-engineer · skill-improver · quality-gate · triple-verify · engram-protocol
