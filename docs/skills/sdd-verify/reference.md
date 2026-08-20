# sdd-verify — Reference Materials

> **Externalized from** .agents/skills/sdd-verify/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples (4-5)

### Example 1: Full SDD Verification (Proposal + Specs + Design + Tasks)
```bash
# Orchestrator launches with contextFiles pointing to all artifacts
# Skill loads: sdd-status-contract.md, strict-tdd-verify.md (if enabled)
# Verification runs test suite, typecheck, coverage
# Output: ## Verification Report with compliance matrix showing 100% scenario coverage
```

### Example 2: Tasks-Only Verification (Bug Fix)
```bash
# contextFiles only contains task list from sdd-tasks.md
# Skip spec/design comparison — only verify task completion + test pass
# Verdict: PASS WITH WARNINGS (no runtime evidence for spec compliance)
```

### Example 3: Specs + Tasks Verification (Feature Addition)
```bash
# contextFiles: proposal.md + specs.md + tasks.md (no design.md)
# Map each requirement scenario to test evidence
# Design check skipped with recorded reason: "design.md not provided"
# CRITICAL if any scenario lacks covering test
```

### Example 4: Strict TDD Mode Active
```bash
# strict_tdd: true in gate-context.json
# Load strict-tdd-verify.md module
# Enforce: test written before implementation, red-green-refactor evidence
# Any missing test-first evidence → CRITICAL
```

### Example 5: Incomplete Tasks Blocking Verification
```bash
# 3 of 5 tasks marked complete, 2 pending
# Verdict: BLOCKED — "Task T004 (auth middleware) incomplete, Task T005 (rate limit) incomplete"
# No test execution until all core tasks complete
```

---

## Testing Patterns (3)

### Pattern 1: Requirement-to-Test Traceability Matrix
```markdown
| Requirement ID | Scenario | Test File | Test Function | Status |
|----------------|----------|-----------|---------------|--------|
| REQ-001        | User login with valid credentials | auth.test.ts | shouldLoginValidUser | ✅ PASS |
| REQ-002        | Reject expired token | auth.test.ts | shouldRejectExpiredToken | ❌ FAIL |
| REQ-003        | Rate limit after 100 req/min | rate-limit.test.ts | shouldEnforceRateLimit | ⏭ SKIPPED |
```
- Every spec requirement maps to at least one test
- Test status derived from actual test run output
- Missing test for requirement → CRITICAL `UNTESTED`

### Pattern 2: Contract Compliance Verification
```typescript
// For API/interface contracts: verify runtime behavior matches spec
const contract = await loadContract('openapi.yaml');
const testResults = await runContractTests(contract, baseUrl);
// testResults: { endpoint: string, method: string, passed: boolean, evidence: string }[]
// Any failed contract test → CRITICAL
```

### Pattern 3: Design Coherence Check
```bash
# Compare design.md architecture decisions against actual code structure
# Example: design says "Repository pattern with UserRepository interface"
# Verify: interface exists, implementations depend on interface, no direct DB calls in services
# Mismatch → WARNING (unless breaks spec → CRITICAL)
```

---

## Edge Cases (4)

### Edge Case 1: Partial Artifacts (Missing Design or Specs)
- **Scenario**: Only tasks + specs provided, no design.md
- **Handling**: Skip design verification, record skip reason in report, do not invent design checks
- **Risk**: False confidence if design gaps exist — flag as WARNING in verdict

### Edge Case 2: Flaky Tests Producing Inconsistent Results
- **Scenario**: Test passes on first run, fails on second
- **Handling**: Run test suite 2x; if any flake detected → CRITICAL `FLAKY`
- **Evidence**: Record both run outputs with `test_output_hash` for each run

### Edge Case 3: Spec Requirements Without Testable Scenarios
- **Scenario**: Spec says "system must be secure" — no concrete scenario
- **Handling**: Mark as `UNTESTABLE` in compliance matrix, require manual verification config
- **Do not**: Invent test scenarios or auto-pass

### Edge Case 4: Typecheck Passes but Runtime Behavior Deviates
- **Scenario**: TypeScript compiles, but API returns wrong status code
- **Handling**: Runtime test evidence overrides static analysis
- **Verdict**: FAIL if runtime test fails, regardless of typecheck/lint passing

---

## Anti-Patterns (2)

### Anti-Pattern 1: Verification by Static Analysis Only
```markdown
❌ WRONG: "TypeScript compiles, ESLint clean, therefore PASS"
✅ RIGHT: Run test suite → verify each scenario has passing test → check runtime behavior
```
- Static analysis (typecheck, lint, build) ≠ spec compliance
- Runtime test execution is mandatory per SDD contract
- Missing runtime evidence → `PASS WITH WARNINGS` at best

### Anti-Pattern 2: Fixing Issues During Verification
```markdown
❌ WRONG: Verifier sees failing test, modifies code to make it pass, reports PASS
✅ RIGHT: Report CRITICAL failure with evidence; orchestrator decides fix strategy
```
- Verification is read-only assessment
- Any code modification during verify phase invalidates the verification
- Report issues with severity; let orchestrator route fix to implementation phase

## Conditions & Actions
- `strict_tdd: true` → Strict TDD; load module
- `workspace-planning` → STOP
- Tasks only → Task completion; skip spec/design
- Tasks + specs → Completeness + correctness; skip design
- Full artifacts → Verify all dimensions
- Task incomplete → CRITICAL (core) / WARNING (cleanup)
- Test non-zero / No passing test → CRITICAL `UNTESTED`/`FAILING`
- Design deviation → WARNING unless breaks spec
- Unchecked tasks / No runtime evidence → CRITICAL / `PASS WITH WARNINGS`
- Missing covering tests → CRITICAL (unless manual OK)
