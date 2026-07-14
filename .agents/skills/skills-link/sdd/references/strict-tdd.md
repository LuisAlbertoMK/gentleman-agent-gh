# Strict TDD — Apply Phase

> Loaded ONLY when Strict TDD Mode enabled + test runner available. Orchestrator verified both.

## 3 Laws
1. NO production code until failing test exists
2. NO more test than needed to fail
3. NO more code than needed to pass

## Cycle (per task)
```
0. SAFETY NET: Run existing tests for modified files → capture baseline
   FAIL → report "pre-existing failure" (don't fix)

1. UNDERSTAND: Read task + specs + design + existing code/tests

2. RED — Write failing test FIRST (from spec behavior)
   Prefer pure functions. Test MUST ref production code not yet written.
   GATE: don't proceed until test written.

3. GREEN — Minimum code to pass (Fake It allowed)
   Execute → must PASS. FAIL → fix impl, NOT test.
   GATE: GREEN confirmed by execution.

4. TRIANGULATE (REQUIRED) — Add 2nd test, different inputs/outputs
   Execute → if Fake It breaks → generalize. MIN: 2 cases per behavior.
   Skip ONLY if purely structural (1 possible output) + note why.
   GATE: all spec scenarios tested before refactor.

5. REFACTOR — Extract, rename, remove dup, push toward pure
   Execute after EACH step → still PASS.
   GATE: green after every change.

6. Mark done [x]  7. Note deviations
```

## Test Layer (pick highest available)
- Pure logic/calc/transform → Unit
- Component render/interaction → Integration else Unit+mocks
- Multi-component/API → Integration else Unit+mocks
- Critical/E2E → E2E else Integration else Unit
- **Default**: Unit. Never skip — degrade gracefully.

## Test Execution
Read command from: cached capabilities → openspec/config.yaml → detect (package.json/pyproject.toml/go.mod). Run ONLY relevant file, not full suite.

## Pure Function Preference
```python
✅ PURE: calculateDiscount(price, qty): qty>=5 ? price*qty*0.1 : 0
❌ IMPURE: calculateDiscount(item): globalState=dirty; updateDOM(); return val
```

## Approval Testing (refactoring)
1. Identify behavior to preserve
2. Write approval tests capturing CURRENT output (even if wrong)
3. Run → must PASS
4. Refactor prod code → run → must STILL PASS
5. Behavior should change? Update test → RED→implement→GREEN

## Return Summary (include when TDD active)
```
### TDD Cycle Evidence
| Task | Test File | Layer | SafetyNet | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|-----------|-----|-------|-------------|----------|
| 1.1 | path/test.ext | Unit | ✅5/5 | ✅ | ✅Passed | ✅3 cases | ✅Clean |

### Test Summary
- Tests written/passing: {N}/{N}  |  Layers: U({N}) I({N}) E({N})
- Approval tests: {N}  |  Pure functions: {N}
```

## Assertion Quality (MANDATORY)
Every assertion must verify REAL behavior. Passing without exercising production logic = false confidence.

### Banned Patterns
| Pattern | Example | Severity | Fix |
|---------|---------|----------|-----|
| Tautology | `expect(true).toBe(true)` / `assert True` | CRITICAL | Test actual behavior |
| Empty orphan | `expect(result).toEqual([])` w/o companion non-empty test | WARNING | Add companion with different setup |
| Type-only alone | `toBeDefined()` / `assert result is not None` alone | WARNING | Add value assertion in same test |
| Ghost loop | Assertion in for/forEach iterating 0 times | CRITICAL | Assert collection non-empty first |
| Incomplete TDD | Test passes b/c setup doesn't exercise code path | CRITICAL | Add test where component IS rendered |
| Smoke-only | `render`+`toBeInTheDocument` w/o behavioral assertion | WARNING | Must assert WHAT was rendered |
| Impl details | CSS classes, internal state, mock call counts | WARNING | Assert semantic outcome (`role=`, text, disabled) |
| Mock-heavy | mocks > 2× assertions | WARNING | Extract to pure fn or move layer |

### REAL Assertion Criteria
1. **Calls production code** — invokes function/component from impl
2. **Asserts specific output** — concrete expected value from spec
3. **Would FAIL if production code wrong** — changing logic breaks THIS test

```
✅ expect(calculateDiscount(100, 10)).toBe(10)
✅ expect(screen.getByText('Welcome, John')).toBeInTheDocument()
✅ assert response.status_code == 403
```

### Mock Hygiene
- Mock/assert ratio: ≤3 = ✅ | 4-6 = ⚠️ extract to pure fn | 7+ = ❌ wrong layer
- Extract-Before-Mock: transform? Extract pure fn first → 0 mocks needed.

## Rules
- NO production code before test (unbreakable)
- NO skip GREEN execution gate — run + confirm pass
- NO skip triangulation when spec has multiple scenarios
- NO trivial assertions (see Banned Patterns)
- ALWAYS verify every assertion calls production code + asserts specific value
- ALWAYS run Safety Net before modifying existing files
- ALWAYS report TDD Cycle Evidence table (verify phase checks it)
- Infra failure ≠ test failure → report "Blocked" → continue next task
- Prefer pure functions but don't force (React components w/ state OK)
- Refactoring? ALWAYS write approval tests first
- Run ONLY relevant test file during cycle, not full suite
