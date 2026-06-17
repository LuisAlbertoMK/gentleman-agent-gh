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
  version: "2.0"
  changelog: "1.0->2.0: 4R framework (Risk/Readability/Reliability/Resilience) replacing flat 6-dim scoring"
---

4R framework for structured code review. Each R is scored and diagnosed independently, then synthesized into a verdict with actionable fixes.

## When
- User asks for code review ("review this", "CR", "revisar", "criticar")
- Before committing complex changes (>100 lines, cross-module, risky logic)
- Pre-merge on high-impact PRs

## The 4R Framework

| R | What it checks | Weight | Typical severity if failing |
|---|---------------|--------|---------------------------|
| **Risk** | Error handling, edge cases, input validation, failure modes, null/nil safety, rollback capability, monitoring | 30% | 🛑 BLOCKER |
| **Readability** | Naming, structure, cognitive load, comments, complexity (cyclomatic), consistency with project patterns | 20% | ⚠️ WARNING |
| **Reliability** | Retry/fallback, timeout handling, state consistency, data integrity, transaction safety, error propagation | 25% | 🔴 CRITICAL |
| **Resilience** | Fault isolation, backpressure, circuit breaker, graceful degradation, recovery, resource limits, concurrency safety | 25% | 🔴 CRITICAL |

### Per-R Checklist (verify each before scoring)

**Risk — 10 questions:**
1. Are all error paths handled (no empty catches, no `// TODO: handle`)?
2. Are edge cases covered (empty input, nil/null, zero, max, overflow)?
3. Is input validated at boundaries (type, range, format)?
4. Can this fail silently? Would we know?
5. Is there a rollback path for partial failures?
6. Are credentials/secrets exposed in logs or output?
7. Is there monitoring/observability for failure states?
8. Are there race conditions on shared state?
9. Is the failure mode documented or obvious?
10. Does it follow the principle of least privilege?

**Readability — 8 questions:**
1. Are names precise and intention-revealing?
2. Is cyclomatic complexity ≤ 10 per function/method?
3. Are side effects obvious and documented?
4. Does the structure follow project conventions?
5. Would a junior dev understand this in one pass?
6. Are comments explaining WHY not WHAT?
7. Is there duplicated logic that could be extracted?
8. Are abstractions at the right level?

**Reliability — 8 questions:**
1. Are external calls protected by timeout?
2. Is there retry logic with backoff for transient failures?
3. Are fallback/default values defined for failure cases?
4. Is state consistency maintained (transactions, atomicity)?
5. Are resources properly released (defer/close/Dispose)?
6. Is data validated before persistence?
7. Are concurrent writes protected (locks, CAS, transactions)?
8. Does partial failure leave the system in a known state?

**Resilience — 7 questions:**
1. Is there backpressure or rate limiting for load spikes?
2. Can a failure in this component cascade to others?
3. Is there a degradation path (degraded but not down)?
4. Are resource limits bounded (memory, connections, goroutines)?
5. Is there a recovery/reconnect mechanism?
6. Are health checks or circuit breakers present where needed?
7. Can this run in parallel without corruption?

## Output Format

```
## CR: {file/summary}

### 4R Assessment
| R | Score | Verdict | Key Issue |
|---|-------|---------|-----------|
| Risk | 8/10 | 🟢 | None critical |
| Readability | 5/10 | 🟡 | Cyclo >15 in processOrder() |
| Reliability | 4/10 | 🔴 | No retry on upstream call |
| Resilience | 7/10 | 🟢 | Circuit breaker present |

**4R Score**: 6.0/10
**Verdict**: 🔴 CHANGES REQUESTED (Reliability must be fixed)

### Dimension Drill-down (evidence for each R)
| Dimension | Score | 4R Mapping | Issues |
|-----------|-------|------------|--------|
| Correctness | 7/10 | Risk | Edge case: empty order list |
| Architecture | 6/10 | Resilience | Handler >300 lines, no isolation |
| Performance | 8/10 | Reliability | OK |
| Security | 9/10 | Risk | OK |
| Readability | 5/10 | Readability | Cyclo >15 |
| Testability | 7/10 | Risk | Hard to mock upstream |

### Fixes
1. `order.go:142` — add retry with exponential backoff for ProcessPayment()
2. `order.go:88` — extract validateOrder() to reduce cyclomatic complexity
3. `handler.go:55` — add timeout context for upstream call

### Evidence
- `go test ./...` — 142/142 pass
- `go vet ./...` — no warnings
```

## Workflow
```
Request → read diff/file → run Per-R checklist → score each R → map to 6 dims → verdict → fixes → evidence
```

## Verdicts
- ✅ **APPROVED** — all R ≥ 7, no blockers
- 🔶 **CHANGES REQUESTED** — any R 4-6, or 1-2 specific fixable issues
- ❌ **REJECTED** — any R < 4, or fundamental design flaw

## Rules
1. Run Per-R checklist BEFORE scoring. Prevents anchoring bias.
2. If an R scores < 5: explain WHY with specific checklist item violation.
3. Each fix: line ref + what + why. No vague suggestions.
4. If clean: "Approved. No 4R issues." No false positives.
5. Evidence required for Reliability + Risk (run tests/examine error paths).
6. At least one fix recommendation per R scoring < 6.
7. **Model visibility**: Always note which model performed the review + skill version (e.g., `Reviewed by: claude-sonnet-4-5 via code-review-agent v2.0`).
8. **Sweet spot**: Review diffs of 200-400 lines for optimal depth. Larger diffs → review per file/module. Smaller diffs → can be more permissive.

## Adaptive Review Profile (Engram-backed)

Before reviewing, load the project's review profile from Engram:

```
mem_search("review-profile/{project}")
```

The profile tracks per-project:
- **Most common R failure**: Which R scores lowest most often → prioritize that R in review
- **Recurring patterns**: Issues found 2+ times (e.g., "missing context timeout on DB calls")
- **Sensitive files**: Files with repeated findings (e.g., `handler.go` → Risk: input validation)
- **Override history**: Which 4R scores were overridden by user and why
- **Last review score**: Previous 4R summary for trend comparison

After review, **update the profile**:

```
mem_save(
  topic_key: "review-profile/{project}",
  type: "pattern",
  content: "
    **What**: Review profile update for {project}
    **Why**: Accumulate review patterns across sessions
    **Findings**:
    - Most frequent R failure: {R}
    - New patterns: {issue 1}, {issue 2}
    - Files flagged: {file1}, {file2}
    - Score trend: {previous}/10 → {current}/10
  "
)
```

## Verifiable Rules per R

Each R has binary (pass/fail) rules checked BEFORE scoring. These are concrete enough that a reviewer MUST answer yes/no for each.

### Risk — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| R01 | All error paths return typed errors | No `panic()`, no empty catches, no `// TODO: handle` |
| R02 | Input validated at every public boundary | `validateInput()` or equivalent at API/file/network entry points |
| R03 | No suppressed errors (`_ = fn()`) | `_ =` is NOT used to discard errors |
| R04 | No nil/null dereference without guard | Every pointer/map/slice dereference is guarded |
| R05 | No secrets in logs or output | `log.Printf("%+v", obj)` not used on sensitive structs |
| R06 | Rollback exists for partial failures | Transaction rollback or compensation action present |
| R07 | Resource limits are enforced | Pagination, rate limiting, or timeout on external resources |

### Readability — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RD01 | Cyclomatic complexity ≤ 10 per function | Count if/else/for/switch/case/&&/|| per function |
| RD02 | No function > 100 lines | (Or agreed project max) |
| RD03 | No nested conditionals beyond 3 levels | if > if > if is max; extract otherwise |
| RD04 | Names reveal intent | No single-letter vars (except loops), no abbreviations |
| RD05 | Comments explain WHY not WHAT | Code is self-documenting for WHAT |
| RD06 | No TODO/FIXME/HACK in non-experimental code | Each must have an issue reference |
| RD07 | No dead code or commented-out blocks | Remove, don't comment |

### Reliability — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RL01 | External calls have timeout | `context.WithTimeout` or `http.Client.Timeout` set |
| RL02 | Retry with backoff on transient failures | At least 1 retry with delay, not immediate retry |
| RL03 | Fallback/default for every external dependency | Default config, cached response, or degraded path |
| RL04 | Resources are released in all paths | `defer` / `finally` / `using` — checked after early returns too |
| RL05 | Concurrent writes are protected | Mutex, CAS, transaction, or channel serialization |
| RL06 | State is validated before persistence | Schema validation, constraint checks before INSERT/UPDATE |
| RL07 | Partial failure doesn't corrupt state | Transactional boundaries or compensating actions |

### Resilience — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RS01 | Backpressure or rate limiting for load | Channel buffer size is bounded, or rate limiter present |
| RS02 | No cascading failure possible | Component failure is isolated (bulkhead pattern) |
| RS03 | Graceful degradation path defined | Non-critical features fail independently |
| RS04 | Resource limits bounded | Max goroutines, max connections, max memory defined |
| RS05 | Recovery/reconnect on transient failure | Reconnection with backoff for network/resources |
| RS06 | Health check or circuit breaker where needed | For critical external dependencies |
| RS07 | Concurrent safety documented | Thread-safety guarantees stated in comments/types |

## Anti-patterns
| ❌ | ✅ |
|---|-----|
| Vague "looks good" | Score + checklist evidence |
| Only praise, no critique | Balance strengths + risks |
| Ignoring one R (always Security, never Resilience) | All 4R evaluated |
| Checklist without synthesis | 4R score + actionable summary |
| Repeating same findings every session | Load review profile, check if issue was flagged before |
| No trend awareness | Compare against profile's previous score |
