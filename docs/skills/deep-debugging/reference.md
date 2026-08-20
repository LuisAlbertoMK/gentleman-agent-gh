# Deep Debugging — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/deep-debugging/SKILL.md) for the core methodology and tool escalation.

---

## Examples (5)

### 1. Null reference in async chain
**OBSERVE**: `TypeError: Cannot read property 'id' of undefined` at `UserService.getProfile:42`  
**HYPOTHESIZE**: (1) `fetchUser` returns null on cache miss, (2) race condition in `initializeUser`, (3) middleware skips auth  
**TEST**: grep `fetchUser` → returns null path at `cache.ts:18`  
**DIAGNOSE**: cache miss returns `null` not `Promise<null>`  
**FIX**: `cache.ts:18` — `return null` → `return Promise.resolve(null)`

### 2. Memory leak in event bus
**OBSERVE**: heap grows 50MB/hour under load  
**HYPOTHESIZE**: (1) listeners not removed on unmount, (2) circular refs in payload, (3) weakmap not used  
**TEST**: grep `addEventListener` → 12 adds, 0 removes in `EventBus.ts`  
**DIAGNOSE**: `subscribe` never calls `unsubscribe` on cleanup  
**FIX**: `EventBus.ts:34` — add `return () => bus.off(event, handler)`

### 3. Flaky test: race in DB transaction
**OBSERVE**: `test_user_isolation` fails 1/20 runs  
**HYPOTHESIZE**: (1) transaction not rolled back, (2) shared test DB, (3) async cleanup order  
**TEST**: grep `afterEach` → no rollback in `test-utils.ts`  
**DIAGNOSE**: test DB state leaks between tests  
**FIX**: `test-utils.ts:12` — wrap each test in `transaction.rollback()`

### 4. Silent config override
**OBSERVE**: feature flag `new_ui` ignored in prod  
**HYPOTHESIZE**: (1) env var precedence, (2) config merge order, (3) build-time substitution  
**TEST**: grep `new_ui` → found in `config.ts:8` and `env.ts:22`  
**DIAGNOSE**: `env.ts` loads after `config.ts`, overwrites with `undefined`  
**FIX**: `config.ts:8` — `const flag = env.NEW_UI ?? config.new_ui`

### 5. Cascading timeout in microservices
**OBSERVE**: `GatewayTimeout` at 30s, but service SLA is 5s  
**HYPOTHESIZE**: (1) no circuit breaker, (2) retry storm, (3) shared thread pool  
**TEST**: grep `timeout` → `http-client.ts:45` has 30s default  
**DIAGNOSE**: downstream 5s timeout + 3 retries × 5s = 15s, but gateway 30s masks it  
**FIX**: `http-client.ts:45` — `timeout: 5000`, add circuit breaker

---

## Testing Patterns (3)

### 1. Bisect by commit
```bash
git bisect start HEAD v2.0.0 -- scripts/test.sh
# → finds first bad commit. Use when regression introduced recently.
```

### 2. Minimal repro harness
Extract failing path to `repro.ts` with only inputs + expected output. Run in isolation. Confirms hypothesis without full test suite.

### 3. Property-based stress
```bash
fast-check generates 1000s inputs against suspected function
# Finds edge cases unit tests miss (empty arrays, Unicode, large numbers)
```

---

## Edge Cases (4)

### 1. Heisenbug disappears under debugger
**Scenario**: Timing-sensitive race  
**Fix**: Add deterministic sleep/logging, or use `rr` record-replay

### 2. Error swallowed by catch-all
**Scenario**: `catch (e) { log(e) }` masks root cause  
**Fix**: Re-throw after logging, or use typed error classes

### 3. Config works locally not in CI
**Scenario**: Environment-specific values (paths, secrets)  
**Fix**: Use config schema validation at startup

### 4. Third-party library bug
**Scenario**: No source access  
**Fix**: Minimal repro → vendor patch → upstream PR. Document workaround in `ADR.md`.

---

## Anti-Patterns (Extended)

| Anti-Pattern | Why It Fails | Correct Approach |
|--------------|--------------|------------------|
| Skip OBSERVE step | No baseline for hypothesis | Always quote exact error first |
| Refactor during fix | Introduces new bugs, obscures root cause | Fix first, refactor in separate PR |
| >3 cycles without diagnosis | Wastes time, context explosion | STOP, ask human with findings |
| Assume without grep evidence | Guesswork ≠ debugging | Every hypothesis needs static evidence first |
| Skip tool escalation | Static tools can't find runtime bugs | After 2 grep cycles → print/logging → test harness → debugger |
| Chase symptoms not root cause | Fixes symptom, bug returns | Always trace to file:line |
| Add logging without hypothesis | Noise, no signal | Log to TEST a specific hypothesis |
| Rewrite instead of bisect | Overkill, loses history | `git bisect` first for regressions |
| Ignore shared state | Misses cross-component bugs | Read order: error origin → caller → shared state |

## Externalized Sections (ADR-007 compression)
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

## Read Order
(1) error origin, (2) immediate caller, (3) shared state/config.

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


