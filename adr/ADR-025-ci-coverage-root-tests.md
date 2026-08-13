# ADR-025: CI coverage for root `tests/` experiment

- **Status**: Accepted (Ciclo 1 v2)
- **Date**: 2026-08-09
- **Deciders**: autonomous improvement protocol v2

## Context

The v1 autonomous-improvement experiment added 46 `*.Tests.ps1` files under root `tests/`. The
existing CI workflow (`.github/workflows/quality-gate.yml`) runs Pester **only** against
`./scripts/tests/*.Tests.ps1` (job `tests`, 875 tests). The root `tests/` suite (99 tests,
covering opencode config validation, permission gates, write-scope, skill frontmatter, JSON-size,
subagent output) was therefore **never executed by CI** — any regression in those 99 tests would
go unnoticed until a developer ran them locally.

## Options evaluated (3)

### A. New parallel CI job `tests-v1` running `./tests/*.Tests.ps1` (CHOSEN)
- ✅ Zero risk to the existing `tests` job (875 tests, stable).
- ✅ Runs in parallel → no added CI latency.
- ✅ Indendent cache key (`psmodules-v1-`) → no cache collision.
- ✅ Clean domain separation (config/permissions vs script logic).
- Effort: LOW.

### B. Expand the existing `tests` job glob to both paths
- ⚠️ Single failure domain: a failing v1 test blocks the whole job.
- ⚠️ Cache key must merge both dirs → any change in either invalidates cache for both.
- Risk: MEDIUM.

### C. Move `tests/` → `scripts/tests/` (consolidation)
- ❌ Forbidden by scope (would mutate 46 test files + break imports + renumber paths).
- Risk: HIGH. Rejected.

## Decision

**Option A** — add a dedicated `tests-v1` job to `quality-gate.yml`, appended after the
existing `tests` job. The 99 v1 tests pass locally (0 failed); the 1 pre-existing E2E failure
(`reports contract_valid=true`) lives in `scripts/tests/`, not `tests/`, so it is unaffected.

## Consequences

- CI now runs 974 tests (875 + 99) → full regression surface for the v1 experiment.
- The two test directories remain separate (conscious domain split, not accidental).
- Future: if the v1 experiment graduates or is retired, remove this job.
