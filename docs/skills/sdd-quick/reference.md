# sdd-quick — Reference Materials

> **Externalized from** .agents/skills/sdd-quick/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Fix typo in error message (1 file, GREEN risk)
```markdown
# Proposal: Fix "Unauthorzed" → "Unauthorized" in auth middleware
## Intent
Correct spelling in error response for 401 status
## Scope
In: src/middleware/auth.ts:42
Out: Nothing else
## Risks
None — string literal only
## Rollback
git checkout src/middleware/auth.ts
## Success
Error message reads "Unauthorized" in 401 response
```
**Verify:** `npm test -- auth.middleware.test.ts` — passes

### Example 2: Add logging to existing function (2 files, GREEN risk)
```markdown
# Proposal: Add debug log to UserService.getById
## Intent
Trace cache hits/misses for performance debugging
## Scope
In: src/services/user.service.ts:15, tests/user.service.test.ts:3
Out: No API changes, no schema changes
## Risks
Log noise if DEBUG=* — mitigated by log level guard
## Rollback
git checkout src/services/user.service.ts tests/user.service.test.ts
## Success
Cache hit/miss logged at debug level; tests pass
```
**Verify:** `pytest tests/user.service.test.ts` — passes

### Example 3: Extract constant to shared config (3 files, LOW risk)
```markdown
# Proposal: Move MAX_RETRY_ATTEMPTS to config/constants.ts
## Intent
Single source of truth for retry policy across services
## Scope
In: src/config/constants.ts (new), src/api/client.ts:8, src/workers/job.runner.ts:12
Out: No behavior change
## Risks
Import cycle if constants imports from api/workers — avoided by leaf-only imports
## Rollback
git checkout src/config/constants.ts src/api/client.ts src/workers/job.runner.ts
## Success
Both files import from constants; tests pass; no runtime change
```
**Verify:** `npm run build && npm test` — passes

### Example 4: Add optional parameter with default (2 files, LOW risk)
```markdown
# Proposal: Add timeoutMs param to fetchWithRetry (default: 5000)
## Intent
Allow callers to tune timeout without breaking existing calls
## Scope
In: src/utils/http.ts:22, tests/http.test.ts:45
Out: No breaking changes; default preserves behavior
## Risks
Callers passing undefined could behave differently — default handles it
## Rollback
git checkout src/utils/http.ts tests/http.test.ts
## Success
Existing calls work; new callers can pass timeoutMs; tests pass
```
**Verify:** `npm test -- http.test.ts` — passes

### Example 5: Rename internal variable for clarity (1 file, GREEN risk)
```markdown
# Proposal: Rename `u` → `currentUser` in AuthContext
## Intent
Improve readability in 50-line component
## Scope
In: src/contexts/AuthContext.tsx:18-35
Out: No external API changes
## Risks
None — internal only, TypeScript catches references
## Rollback
git checkout src/contexts/AuthContext.tsx
## Success
Variable reads `currentUser`; TypeScript compiles; tests pass
```
**Verify:** `npx tsc --noEmit && npm test -- AuthContext` — passes

## Testing Patterns

### Pattern 1: Mirror Existing Test Style
When the codebase uses a consistent test pattern (e.g., `describe/it` with `expect`), **match it exactly**. Don't introduce new styles.

```typescript
// ✅ Good — follows existing pattern
describe('UserService.getById', () => {
  it('returns user when found', async () => {
    const user = await service.getById('123');
    expect(user).toEqual(expectedUser);
  });
});
```

### Pattern 2: One Assertion Per Behavior
Each `it`/`test` block asserts **one logical behavior**. Split if multiple concerns.

```typescript
// ✅ Good — one behavior per test
it('returns 401 when token expired', async () => { ... });
it('returns 403 when token valid but insufficient scope', async () => { ... });

// ❌ Bad — two behaviors in one test
it('handles auth errors', async () => { ... }); // conflates 401 and 403
```

### Pattern 3: Test the Contract, Not Implementation
Assert on **inputs/outputs/side effects**, not internal variables or private methods.

```typescript
// ✅ Good — tests observable behavior
it('caches result on second call', async () => {
  await service.getById('123');
  await service.getById('123');
  expect(cache.get).toHaveBeenCalledTimes(1); // side effect
});

// ❌ Bad — tests implementation detail
it('sets internal cache map', async () => {
  await service.getById('123');
  expect(service['cache'].size).toBe(1); // private field
});
```

## Edge Cases

### Edge Case 1: Hidden Dependency on File Count
A "2-file change" becomes 4 files because a shared type is modified and two consumers need updates.
- **Signal:** `grep -r "InterfaceName" --include="*.ts" | wc -l` > expected
- **Response:** If >3 files touched after analysis → **abort to full SDD**

### Edge Case 2: Config Change Cascades
Changing a constant in `config/constants.ts` seems like 1 file, but 8 services import it.
- **Signal:** `grep -r "from.*constants" --include="*.ts" | wc -l` > 3
- **Response:** If consumers >3 → **abort to full SDD** (design review needed)

### Edge Case 3: Test File Count Exceeds Source
Adding a test for a 1-file fix creates 3 test files (unit, integration, e2e).
- **Signal:** Test files > source files in proposal
- **Response:** Consolidate to 1 test file matching existing pattern; if impossible → **full SDD**

### Edge Case 4: Build Passes but Types Drift
TypeScript compiles, but a downstream consumer (untouched in this PR) now has a silent type mismatch.
- **Signal:** `npm run typecheck` passes in repo, but consumer repo fails
- **Response:** Add `npm run typecheck:all` (or equivalent) to Verify gate if cross-repo types exist

## Anti-Patterns

### Anti-Pattern 1: "Just This Once" Scope Creep
Using sdd-quick for a change that *feels* small but touches auth, schema, or API boundaries.
- **Symptom:** "It's just one line in the JWT middleware" → actually changes token shape
- **Fix:** If ANY criterion in "When to Use" table is violated → **full SDD, no exceptions**

### Anti-Pattern 2: Skip Verify Because "Tests Passed Locally"
Running tests locally but not in CI/verify gate, assuming parity.
- **Symptom:** `npm test` passes on machine; CI fails on Node version / env difference
- **Fix:** **Verify gate is mandatory** — run the project's standard test/build commands exactly as CI does

### Anti-Pattern 3: No Rollback Plan
Proposal omits rollback because "it's trivial to revert."
- **Symptom:** Rollback section says "git revert" without file list
- **Fix:** Rollback **must** list exact files: `git checkout file1.ts file2.ts`

### Anti-Pattern 4: Proposal as Implementation Notes
Writing the proposal *after* coding, as a retroactive summary.
- **Symptom:** Proposal references commit SHAs or "as implemented"
- **Fix:** Proposal **precedes** Apply phase. If code exists, you're in full SDD Apply already.

## Externalized Sections (ADR-007 compression)
## Return Envelope

```
sdd-quick | {change-name}
Phases: Propose→Apply→Verify
Files:{N} | Tests:{P/FAIL} | Build:{P/FAIL}
Status:{Ready|Blocked}
Time:{actual time}
```

## Flow — Phase Detail
### Phase 1: Propose (simplified)
Load `{file:sdd/phases/02-propose.md}`. Relaxations: Skip `Capabilities` + `Affected Areas` table (list ≤3 files inline). Keep: Intent, Scope (In/Out), Risks, Rollback, Success Criteria. Budget: **<200 words**. Output → §C.
### Phase 2: Apply (standard)
Load `{file:sdd/phases/06-apply.md}`. No tasks breakdown; standard TDD if risky logic; no workload check (≤3 files). Persist via §C.
### Phase 3: Verify (essential only)
Load `{file:sdd/phases/07-verify.md}`. Gates: Tests pass | Build OK | No regressions. **Skip:** Design coherence, spec mapping, coverage, assertion audit. Output → §C.
