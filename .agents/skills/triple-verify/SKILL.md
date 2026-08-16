---
name: triple-verify
description: "Triple verification — 3 enfoques, thresholds por zona, modos !ship/!fast/!draft"
triggers: "Triple verify, triangulate, 3 enfoques, !ship, !listo, !fast, !draft"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Triple verification — 3 enfoques, thresholds por zona, modos

## Zones
Zones, thresholds, verify depth defined in `review-rules.jsonc`.
- **Roja**: full triple-verify (E1+E2+E3)
- **Amarilla**: verify if diff > threshold lines
- **Verde**: skip verify, quality-gate only
- Context zones in `context_zones`, workflow modes in `modes`
- **Edit `review-rules.jsonc` — NOT this file**

## 3 Approaches
| E1 — Testing | E2 — Static | E3 — Build/Runtime |
|---|---|---|
| Unit/integration/e2e | Lint, 4R, secrets | Build, dry-run, schema |
| Tests pass, bug repro | No regressions | Build OK, runtime checks |
| Schema validate, PSSA | Lint, 4R review | Dry-run, `-WhatIf` |

## Workflow

**Mode routing** (keyword overrides):
- `!ship/!listo` → quality-gate → triple-verify (por zona) → commit-crafter → commit+push
- `!fast` → quality-gate → commit+push (skip verify)
- `!check` → quality-gate only (no commit)
- `!draft` → no gates
- (no keyword) → zona determina verify depth

**quality-gate ALWAYS mandatory** in `!ship`/`!fast`/`!check` regardless of zone. Zone only affects triple-verify, NOT quality-gate.

**Zone routing** (verify depth, when keyword didn't route):
- Verde → SKIP verify → quality-gate if commit
- Amarilla ≤10L → quality-gate
- Rojo/Amarilla >10L → TRIPLE VERIFY (E1+E2+E3 parallel)
- Fail → STOP + evidence · Pass → continue

## Rules
1. **3 DISTINCT approaches**: behavior + quality + compilation
2. **Default-FAIL**: no evidence of 3 steps → not verified
3. **Build mandatory** for compilable code
4. **!ship = responsibility**: quality-gate NEVER optional
5. **capture-learnings** (inline): run `scripts/session-miner.ps1 -Mode scan -Json` post-task or pre-commit. Parse JSON for new patterns → store in `.learnings/`. `mem_save` decisions/bugfixes to Engram. Skip if unavailable. Stage `.learnings/`.
6. **Override**: `!ship --no-verify` emergency only
7. **Self-improvement override**: difficulty levels from CYCLE.md override verify depth

## References
quality-gate · code-review-agent · judgment-day · commit-crafter · CYCLE.md

## Examples

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

## Testing Patterns

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

## Edge Cases

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

## Anti-Patterns

1. **Ship without quality-gate** — `!ship` without running quality-gate first (bypasses mandatory gate)
2. **Two approaches instead of three** — Running E1+E2 but skipping E3 (build), or E1+E3 but skipping E2 (static)
3. **Skip build for compilable code** — TypeScript/Python/Rust/Go changes without `build` or `typecheck` step
4. **Ignore zone thresholds** — Treating Amarilla 15L diff as Verde (skip verify) or Rojo 5L diff as Amarilla
5. **!ship --no-verify as default** — Using emergency override for routine work (reserved for production incidents)
6. **Verify theater** — Running commands that "look like" verify but don't actually validate (e.g., `pytest` with no tests, `ruff` on excluded paths)
