# Strict TDD Module — Apply Phase

> **Loaded ONLY when Strict TDD Mode enabled + test runner available.**
> Orchestrator verified both. Follow every instruction.

## Philosophy

TDD = software design driven by tests. Tests design API/contracts/behavior. Code = side effect.

### 3 Laws
1. NO production code until failing test exists
2. NO more test than needed to fail
3. NO more code than needed to pass

## Cycle (per task)

```
FOR EACH TASK:
0. SAFETY NET (existing files only)
  ├─ Run existing tests for files being modified
  ├─ Capture baseline: "{N} tests passing"
  ├─ FAIL → STOP, report "pre-existing failure" (don't fix)
  └─ Proves you didn't break what worked

1. UNDERSTAND
  ├─ Read task + specs (acceptance criteria) + design (constraints)
  └─ Read existing code/tests → determine test layer

2. RED — Write failing test FIRST
  ├─ Write test(s) from spec behavior
  ├─ Prefer pure functions (no side effects = testable)
  ├─ Test MUST ref production code that doesn't exist yet
  ├─ If code exists → test NEW behavior only
  └─ GATE: don't proceed to GREEN until test written

3. GREEN — Minimum code to pass
  ├─ Implement only what the failing test needs
  ├─ Fake It allowed (hardcoded OK)
  ├─ EXECUTE → must PASS
  │   ├─ ✅ → triangulate or refactor
  │   └─ ❌ → fix impl, NOT test
  └─ GATE: GREEN confirmed by execution

4. TRIANGULATE (REQUIRED)
  ├─ Add 2nd test with DIFFERENT inputs/outputs
  ├─ EXECUTE → if Fake It breaks → generalize to real logic
  ├─ Repeat until ALL spec scenarios covered
  ├─ MIN: 2 cases per behavior (happy path + edge)
  ├─ WATCH: GREEN that passes trivially (empty collection, 0-iteration loop,
  │   component not rendered, setup doesn't trigger code path) = NOT real GREEN
  ├─ Skip ONLY if: purely structural (config/types) AND 1 possible output
  │   AND explicitly note "Triangulation skipped: {reason}"
  └─ GATE: all spec scenarios tested before refactor

5. REFACTOR — Improve, keep behavior
  ├─ Extract constants/functions, improve naming, remove dup
  ├─ Push toward pure functions, Boy Scout Rule
  ├─ EXECUTE after EACH step → still PASS
  │   ├─ ✅ → safe, continue
  │   └─ ❌ → revert, try smaller
  └─ GATE: green after every change

6. Mark done [x]
7. Note deviations/issues
```

## Choosing Test Layer

From cached `sdd/{project}/testing-capabilities`, pick highest available:

```
├─ Pure logic/calc/transform → Unit (always)
├─ Component render/interaction → Integration if tools exist else Unit+mocks
├─ Multi-component flow/API → Integration if tools else Unit+mocks
├─ Critical flow/E2E → E2E if tools else Integration else Unit
└─ Default: Unit (always fallback)
```
**Never skip task because layer unavailable — degrade gracefully.**

## Test Execution

```
Read test command from:
├─ Cached capabilities → test_runner.command (fastest)
├─ openspec/config.yaml → rules.apply.test_command
└─ Fallback: detect from package.json/pyproject.toml/go.mod

Run ONLY relevant test file (not full suite):
├─ JS/TS: {runner} {test-file-path}
├─ Python: pytest {test-file-path}
├─ Go: go test ./{package}/... -run {TestName}
└─ Full suite → sdd-verify phase
```

## Pure Function Preference

```python
✅ PURE: fn calculateDiscount(price, qty): qty>=5 ? price*qty*0.1 : 0
❌ IMPURE: fn calculateDiscount(item): globalState=dirty; updateDOM(); return val
```
**Why**: Pure = deterministic, no side effects, trivially testable. TDD pushes you here.

## Approval Testing (refactoring existing code)

```
BEFORE touching prod code:
1. Identify behavior to preserve
2. Write approval tests capturing CURRENT output (even if ugly/wrong)
3. Run → must PASS (documents current reality)
4. Refactor prod code
5. Run → must STILL PASS (✅ preserved / ❌ revert)
6. Spec says behavior should change? Update test → RED → implement → GREEN
```

## Return Summary

When Strict TDD active, INCLUDE this:

```markdown
### TDD Cycle Evidence
| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1.1 | `path/test.ext` | Unit | ✅ 5/5 | ✅ Written | ✅ Passed | ✅ 3 cases | ✅ Clean |

### Test Summary
- **Total tests written/passing**: {N}/{N}
- **Layers**: Unit({N}) Integration({N}) E2E({N})
- **Approval tests**: {N} or "None"
- **Pure functions created**: {N}
```
**Columns**: Safety Net = pre-existing tests (N/A for new files). RED = test before code. GREEN = executed + passing. TRIANGULATE = additional cases (>1 scenario). REFACTOR = cleanup after green.

## Assertion Quality Rules (MANDATORY)

Every assertion must verify REAL behavior. A test passing without exercising production logic = false confidence.

### Banned Patterns (NEVER write)

```
# TRIVIAL — no production code involved
expect(true).toBe(true) | assert True | expect(1).toBe(1)

# EMPTY COLLECTION without setup context
expect(result).toEqual([]) | assert len(result) == 0
→ Only valid IF precondition produces empty AND companion test with different setup produces non-empty

# TYPE-ONLY — proves existence, not value
expect(result).toBeDefined() | assert result is not None
→ OK only when combined with value assertion in same test

# GHOST LOOP — assertion inside loop iterating 0 times
for item in queryAllByTestId("item"): expect(item)  # NEVER RUNS if []
→ FIX: assert collection non-empty first: expect(items).toHaveLength(3)

# INCOMPLETE TDD — GREEN without triangulate
Test passes because setup doesn't exercise code path (e.g., component never rendered)
→ FIX: add test where component IS rendered, verify behavior

# SMOKE ONLY — render + toBeInTheDocument without behavioral assertion
→ NOT a valid test. Must assert WHAT was rendered.

# IMPL DETAILS — CSS classes, internal state, mock call counts
expect(el.className).toContain("text-xs") | expect(mock.calls.length).toBe(3)
→ Assert behavior: screen.getByRole("alert"), button disabled, text content

# MOCK-HEAVY — mocks > 2x assertions → wrong layer
→ Extract logic to pure function or move to integration/E2E
```

### REAL Assertion Criteria
1. **Calls production code** — invokes function/component from impl
2. **Asserts specific output** — concrete expected value from spec
3. **Would FAIL if production code wrong** — changing logic breaks THIS test

```
✅ REAL: expect(calculateDiscount(100, 10)).toBe(10)
✅ REAL: expect(screen.getByText('Welcome, John')).toBeInTheDocument()
✅ REAL: assert response.status_code == 403
```

### Mock Hygiene
- Mock/assertion ratio guide: ≤3 = ✅ healthy | 4-6 = ⚠️ extract to pure fn | 7+ = ❌ wrong layer
- Extract-Before-Mock: Testing a data transform? Extract pure function first → 0 mocks needed.

### Empty Collection Rule
`assert len(result) == 0` valid ONLY when:
1. Precondition SHOULD produce empty (no matching records)
2. Production code ran + processed data
3. Companion test with DIFFERENT setup produces non-empty

If can't explain WHY empty → trivial assertion.

### Smoke Test Rule
`render(<X />)` + `toBeInTheDocument()` = smoke test. NOT unit/integration test. Does NOT count toward TDD coverage. Must be accompanied by real behavioral assertions.

### Implementation Detail Coupling
CSS class assertions = NEVER valid. Test semantic outcomes (`role="alert"`, `toBeDisabled()`, text content) or use visual regression tools.

## Rules
- NO production code before test (unbreakable)
- NO skip GREEN execution gate — run + confirm pass
- NO skip triangulation when spec has multiple scenarios
- NO trivial assertions (see Banned Patterns)
- ALWAYS verify every assertion calls production code + asserts specific value
- ALWAYS run Safety Net before modifying existing files
- ALWAYS report TDD Cycle Evidence table (verify phase checks it)
- Infra failure (not test failure) → report "Blocked" → continue next task
- Prefer pure functions but don't force where not fitting (React components w/ state)
- Refactoring? ALWAYS write approval tests first
- Run ONLY relevant test file during cycle, not full suite
