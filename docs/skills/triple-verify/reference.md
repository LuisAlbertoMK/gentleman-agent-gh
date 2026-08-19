# Triple Verify — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/triple-verify/SKILL.md) for the core workflow.

---

## Examples (5)

### Example 1: New API Endpoint (Rojo zone)
```bash
# User: "!ship add user-export endpoint"
# Zona: Rojo (auth boundary, new route)
# E1: pytest tests/api/test_user_export.py -v
# E2: ruff check src/api/user_export.py && 4R review
# E3: pnpm build && pnpm dry-run:export
# Result: All 3 pass → commit-crafter → commit+push
```

### Example 2: Refactor Config Loader (Amarilla zone, 15 lines)
```bash
# User: "!ship refactor config loader"
# Zona: Amarilla, diff=15L > 10L threshold
# E1: pytest tests/unit/test_config.py -k "loader" -v
# E2: mypy src/config/loader.py && ruff check
# E3: python -m src.config.loader --dry-run
# Result: E2 catches type error → fix → re-verify → pass
```

### Example 3: Documentation Update (Verde zone)
```bash
# User: "!ship update README examples"
# Zona: Verde (docs only, no code)
# E1: SKIP (no tests for docs)
# E2: SKIP (no lint for .md in this project)
# E3: SKIP (no build)
# quality-gate runs → passes → commit
```

### Example 4: Hotfix with !fast (Rojo zone, emergency)
```bash
# User: "!fast hotfix memory leak in worker"
# !fast keyword OVERRIDES zone → SKIP triple-verify
# quality-gate ONLY → passes → commit+push
# Learnings captured: "Fast path used for production hotfix"
```

### Example 5: Draft Mode Exploration
```bash
# User: "!draft explore new auth strategy"
# !draft → NO gates, NO quality-gate, NO verify
# Free exploration, no commit
# Later: "!ship implement chosen strategy" → full pipeline
```

---

## Testing Patterns (3)

### Pattern 1: Layered Test Execution (E1)
```python
# Unit → Integration → E2E in sequence
def test_e1_layers():
    # 1. Unit: pure functions, no I/O
    assert calculate_discount(100, 0.1) == 90
    
    # 2. Integration: DB, cache, external mock
    with patch("src.api.client") as mock:
        mock.get.return_value = {"status": "ok"}
        assert fetch_user(1) == expected
    
    # 3. E2E: full stack via testcontainer/Playwright
    page.goto("/dashboard")
    expect(page).to_have_title("Dashboard")
```
**Rule**: Each layer must pass before next. Fail fast.

### Pattern 2: Property-Based Verification (E1+E2)
```python
# Hypothesis for invariants + static types for contracts
from hypothesis import given, strategies as st

@given(st.lists(st.integers(), min_size=1))
def test_sort_idempotent(xs):
    assert sorted(sorted(xs)) == sorted(xs)

# mypy validates: List[int] -> List[int] contract
# ruff validates: no side effects in pure function
```
**Rule**: Property tests for behavior, static for contracts.

### Pattern 3: Build-Time Schema Validation (E3)
```bash
# OpenAPI → codegen → compile-time check
pnpm openapi:generate          # generates types from spec
tsc --noEmit                   # validates types compile
pnpm test:contract             # pact/contract tests
```
**Rule**: Schema changes break build, not runtime.

---

## Edge Cases (4)

### Edge Case 1: Generated Code (No Source to Verify)
```bash
# Prisma client, OpenAPI types, Protobuf stubs
# E1: Test USAGE of generated code, not the generated code itself
# E2: Lint only hand-written wrappers
# E3: Build validates generated code compiles
```
**Resolution**: Verify consumption, not generation.

### Edge Case 2: Config-Only Changes (No Compilable Code)
```bash
# .env, docker-compose.yml, k8s manifests
# E1: SKIP (no testable logic)
# E2: yamllint, kubeval, env-schema validate
# E3: dry-run deploy (kubectl apply --dry-run=client)
```
**Resolution**: E2+E3 become primary; E1 optional.

### Edge Case 3: Cross-Repo Dependency (Monorepo)
```bash
# Change in packages/core affects packages/web
# E1: Test affected packages via turbo filter
# E2: Typecheck entire affected graph
# E3: Build affected + dependents
# Turbo/Nx handles blast radius automatically
```
**Resolution**: Use build system's affected graph.

### Edge Case 4: Legacy Code Without Tests (Rojo zone)
```bash
# Must modify untested legacy module
# E1: WRITE characterization tests FIRST (capture current behavior)
# E2: Lint + 4R review of changes only
# E3: Build + smoke test
# Never skip E1 — write tests as part of the fix
```
**Resolution**: Characterization tests = E1 for legacy.

---

## Anti-Patterns (6)

1. **Ship without quality-gate** — `!ship` without running quality-gate first (bypasses mandatory gate)
2. **Two approaches instead of three** — Running E1+E2 but skipping E3 (build), or E1+E3 but skipping E2 (static)
3. **Skip build for compilable code** — TypeScript/Python/Rust/Go changes without `build` or `typecheck` step
4. **Ignore zone thresholds** — Treating Amarilla 15L diff as Verde (skip verify) or Rojo 5L diff as Amarilla
5. **!ship --no-verify as default** — Using emergency override for routine work (reserved for production incidents)
6. **Verify theater** — Running commands that "look like" verify but don't actually validate (e.g., `pytest` with no tests, `ruff` on excluded paths)