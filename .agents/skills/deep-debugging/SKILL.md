---
name: deep-debugging
description: "Trigger: deep debug, root cause, hypothesis, multi-file bug, ambiguous failure. Hypothesis-driven debugging."
triggers: "deep debug, root cause, hypothesis, multi-file bug, ambiguous failure, debug, RCA"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Multi-file bugs, ambiguous failures. NOT for 1-file edits (→ quick-executor), architecture decisions (→ sdd), or refactors (→ refactoring-planner).

## METHODOLOGY: Hypothesis-Driven Debugging

Output each step name as completed:

1. **OBSERVE**: Quote exact error/symptom. If no error, describe behavioral difference.
2. **HYPOTHESIZE**: 2-3 root causes. Rank by: (1) direct evidence, (2) structural proximity, (3) frequency.
3. **TEST**: One cycle = one hypothesis. **Methods (escalate):** grep/read (static) → add print/logging → run test harness → use debugger/profiler → minimal repro. After 2 grep cycles with no answer → escalate to runtime tools.
4. **DIAGNOSE**: Pick strongest evidence. Cite file:line.
5. **PLAN**: Before/after for each affected file. Check cascading impacts. If fix requires structural changes → note it, continue fix first, refactor after.
6. **EXECUTE**: One logical change per edit.
7. **VERIFY**: Tests first → typecheck/lint → syntax parse → escalate.

Read order: (1) error origin, (2) immediate caller, (3) shared state/config.

## TOOL ESCALATION
| Stage | When | Tools |
|-------|------|-------|
| Static | First 2 cycles | grep, read, git log |
| Dynamic | No answer after 2 cycles | print/logging, test harness |
| Runtime | Still stuck | debugger, profiler, strace/APM |
| Minimal repro | Complex bugs | Isolate to smallest reproducing case |

## CONTEXT CHECKPOINT
After 4+ hypothesis rounds: summarize findings, save progress, compress context before continuing.

## SEVERITY
| P0 | Production down, data loss | P1 | Major functionality broken | P2 | Degraded performance | P3 | Minor issue |

## OUTPUT
```
### Diagnosis
- Severity: P[N]
- Symptom: [quote error]
- Root cause: [file:line — why]
- Evidence: [grep/read/profiler output]
### Fix
- File: path → [before] → [after]
- Verification: [command + expected]
```

## Rules
1. Max 5 hypotheses before narrowing. Max 3 cycles total. 2. Unclear after 3 cycles → STOP, ask human. 3. Never refactor during bug fix. 4. Verify with evidence, not assumptions.

## Refs
refactoring-planner · code-review-agent

## Anti-Patterns
Skip OBSERVE step · Refactor during fix · >3 cycles without diagnosis · Assume without grep evidence · Skip tool escalation
Chase symptoms not root cause · Add logging without hypothesis · Rewrite instead of bisect · Ignore shared state

## Examples
1. **Null reference in async chain** — OBSERVE: `TypeError: Cannot read property 'id' of undefined` at `UserService.getProfile:42`. HYPOTHESIZE: (1) `fetchUser` returns null on cache miss, (2) race condition in `initializeUser`, (3) middleware skips auth. TEST: grep `fetchUser` → returns null path at `cache.ts:18`. DIAGNOSE: cache miss returns `null` not `Promise<null>`. FIX: `cache.ts:18` — `return null` → `return Promise.resolve(null)`.

2. **Memory leak in event bus** — OBSERVE: heap grows 50MB/hour under load. HYPOTHESIZE: (1) listeners not removed on unmount, (2) circular refs in payload, (3) weakmap not used. TEST: grep `addEventListener` → 12 adds, 0 removes in `EventBus.ts`. DIAGNOSE: `subscribe` never calls `unsubscribe` on cleanup. FIX: `EventBus.ts:34` — add `return () => bus.off(event, handler)`.

3. **Flaky test: race in DB transaction** — OBSERVE: `test_user_isolation` fails 1/20 runs. HYPOTHESIZE: (1) transaction not rolled back, (2) shared test DB, (3) async cleanup order. TEST: grep `afterEach` → no rollback in `test-utils.ts`. DIAGNOSE: test DB state leaks between tests. FIX: `test-utils.ts:12` — wrap each test in `transaction.rollback()`.

4. **Silent config override** — OBSERVE: feature flag `new_ui` ignored in prod. HYPOTHESIZE: (1) env var precedence, (2) config merge order, (3) build-time substitution. TEST: grep `new_ui` → found in `config.ts:8` and `env.ts:22`. DIAGNOSE: `env.ts` loads after `config.ts`, overwrites with `undefined`. FIX: `config.ts:8` — `const flag = env.NEW_UI ?? config.new_ui`.

5. **Cascading timeout in microservices** — OBSERVE: `GatewayTimeout` at 30s, but service SLA is 5s. HYPOTHESIZE: (1) no circuit breaker, (2) retry storm, (3) shared thread pool. TEST: grep `timeout` → `http-client.ts:45` has 30s default. DIAGNOSE: downstream 5s timeout + 3 retries × 5s = 15s, but gateway 30s masks it. FIX: `http-client.ts:45` — `timeout: 5000`, add circuit breaker.

## Testing Patterns
1. **Bisect by commit** — `git bisect start HEAD v2.0.0 -- scripts/test.sh` → finds first bad commit. Use when regression introduced recently.
2. **Minimal repro harness** — Extract failing path to `repro.ts` with only inputs + expected output. Run in isolation. Confirms hypothesis without full test suite.
3. **Property-based stress** — `fast-check` generates 1000s inputs against suspected function. Finds edge cases unit tests miss (empty arrays, Unicode, large numbers).

## Edge Cases
1. **Heisenbug disappears under debugger** — Timing-sensitive race. Fix: add deterministic sleep/logging, or use `rr` record-replay.
2. **Error swallowed by catch-all** — `catch (e) { log(e) }` masks root cause. Fix: re-throw after logging, or use typed error classes.
3. **Config works locally not in CI** — Environment-specific values (paths, secrets). Fix: use config schema validation at startup.
4. **Third-party library bug** — No source access. Fix: minimal repro → vendor patch → upstream PR. Document workaround in `ADR.md`.
