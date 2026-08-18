# ralph-loop — Reference Materials

> **Externalized from** .agents/skills/ralph-loop/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Anti-Patterns
Output DONE prematurely · Lie to escape loop · Never check iteration state · Ignore max iterations · Skip <promise>DONE</promise> on completion

---

## Examples

### Example 1: Multi-file Refactor with Verification
```bash
# Task: Refactor auth module to use new JWT library across 5 files
ralph-loop "Refactor src/auth/*.ts to use jsonwebtoken v9. Replace all sign/verify calls. Run tests after each file. Stop when all tests pass."
```
Iteration 1: Update `src/auth/tokens.ts` → tests pass
Iteration 2: Update `src/auth/middleware.ts` → tests pass
Iteration 3: Update `src/auth/login.ts`, `src/auth/refresh.ts`, `src/auth/logout.ts` → all pass
Iteration 4: Run full suite → `<promise>DONE</promise>`

### Example 2: Progressive Test Coverage Improvement
```bash
# Task: Increase coverage from 45% to 80% for payment module
ralph-loop "Add tests to src/payment/ until coverage >= 80%. Target uncovered branches in processPayment, validateCard, handleRefund. Run npm test -- --coverage after each batch."
```
Iteration 1: Add 15 tests for `processPayment` → coverage 58%
Iteration 2: Add 12 tests for `validateCard` → coverage 71%
Iteration 3: Add 8 tests for `handleRefund` + edge cases → coverage 82%
Iteration 4: Final verification → `<promise>DONE</promise>`

### Example 3: Bug Fix with Root Cause Validation
```bash
# Task: Fix race condition in WebSocket reconnection logic
ralph-loop "Fix race condition in src/ws/reconnect.ts. Steps: 1) Reproduce with concurrent connect/disconnect. 2) Add mutex/lock. 3) Stress test 1000 iterations. 4) Verify no duplicate connections."
```
Iteration 1: Write reproduction script → confirms race at ~200 ops
Iteration 2: Implement connection guard with atomic state → repro passes
Iteration 3: Run stress test (1000x) → 0 failures
Iteration 4: Add integration test → `<promise>DONE</promise>`

### Example 4: Documentation Sync Across Repo
```bash
# Task: Sync all README files with current API after v2.3 release
ralph-loop "Update all README.md files in packages/* to reflect v2.3 API changes. Check: new endpoints, deprecated params, migration guide links. Validate with markdown lint."
```
Iteration 1: Update `packages/core/README.md` → lint pass
Iteration 2: Update `packages/cli/README.md`, `packages/sdk/README.md` → lint pass
Iteration 3: Update `packages/adapters/*/README.md` (7 files) → lint pass
Iteration 4: Verify cross-links work → `<promise>DONE</promise>`

### Example 5: Database Migration with Rollback Testing
```bash
# Task: Add user_preferences table with rollback safety
ralph-loop "Create migration for user_preferences table. Steps: 1) Write up/down migrations. 2) Test up on dev DB. 3) Test down (rollback). 4) Verify data integrity. 5) Run full migration suite."
```
Iteration 1: Create `migrations/047_user_preferences.up.sql` + `.down.sql`
Iteration 2: Apply up → verify schema + seed data
Iteration 3: Apply down → verify clean rollback
Iteration 4: Re-apply up → run full suite → `<promise>DONE</promise>`

---

## Testing Patterns

### Pattern 1: Iteration Checkpoint Testing
```bash
# After each logical unit of work, run focused verification
npm test -- --testPathPattern="auth/tokens" --verbose
# Only proceed to next iteration if exit code 0
```

**When to use:** Multi-file changes where each file must be independently correct before proceeding.

### Pattern 2: Progressive Coverage Gate
```bash
# Enforce minimum coverage threshold per iteration
npm test -- --coverage --coverageThreshold='{"global":{"branches":60,"functions":70}}'
# Fails fast if threshold not met, forcing more tests in next iteration
```

**When to use:** Coverage improvement tasks where each iteration must measurably advance the metric.

### Pattern 3: Stress/Soak Validation
```bash
# Run extended validation before claiming completion
for i in {1..100}; do node stress-test.js; done
# Or: k6 run --vus 50 --duration 30s load-test.js
# Zero failures required across all runs
```

**When to use:** Concurrency fixes, performance improvements, or any change where correctness under load must be proven.

---

## Edge Cases

### Edge Case 1: External Dependency Blocks Progress
**Scenario:** API rate limit, third-party service down, or missing credentials halt work.
**Response:** Document blocker in state file, output `<blocker>API rate limited - need credentials</blocker>` instead of false promise. Loop pauses until user resolves.

### Edge Case 2: Max Iterations Reached Before Completion
**Scenario:** Task underestimated; hits `maxIterations` (default 100).
**Response:** State file shows `iteration: 100`, `active: false`. User must manually restart with higher `maxIterations` or refined scope.

### Edge Case 3: Git Conflicts During Iteration
**Scenario:** Parallel work creates merge conflicts in files you're modifying.
**Response:** Stop current iteration, resolve conflicts, commit resolution, then continue. Do NOT force-complete with unresolved conflicts.

### Edge Case 4: Test Flakiness Causes False Failures
**Scenario:** Intermittent test failures unrelated to your changes.
**Response:** Re-run failed test 3x. If passes 2/3, document as flaky and proceed. If consistently fails, treat as real failure. Never ignore consistent failures.

---

## Anti-Patterns

### Anti-Pattern 1: False Completion Promise
**What:** Outputting `<promise>DONE</promise>` when tests fail, features incomplete, or verification skipped.
**Why it breaks:** Loop terminates with broken code. Next session inherits broken state.
**Correct approach:** Only promise when ALL acceptance criteria verifiably met. If stuck, request help.

### Anti-Pattern 2: Scope Creep Within Single Loop
**What:** Starting with "fix login bug" but expanding to "refactor all auth + add 2FA + update docs" in one loop.
**Why it breaks:** Iterations become unfocused, maxIterations exhausted, completion criteria ambiguous.
**Correct approach:** Define ONE clear completion criterion upfront. Split large work into chained loops with explicit handoff.
