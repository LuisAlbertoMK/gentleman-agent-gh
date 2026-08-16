---
name: sdd
description: "pipeline — 9 phases. Use sdd-quick for LOW-risk fast path."
triggers: "pipeline, phase, spec-driven development"
changelog: docs/ciclos/cycle28-20260815.md
---

# Pipeline
**Fast path for LOW-risk:** `{file:sdd-quick/SKILL.md}` — 3 phases.

## Protocol
All phases share: `{file:sdd/references/sdd-phase-common.md}`

## Usage
**Orchestrator**: Load for overview → load phase for details.
**Subagent**: Load phase via `{file:sdd/phases/{N}-{name}.md}`.

## Choosing Your Path
Fast (sdd-quick): ≤3 files, no schema/auth/API/deps, LOW risk, known codebase.
Full (9-phase): otherwise.
**Gate**: If ANY "No" → full. `Known? ← Schema? ← No deps? ← LOW risk? ← <4 files?`
Unsure: start full; after Explore, switch if scope confirms.

## Orchestrator Routing
```
phase=init → sdd-init
phase=explore → sdd-explore
phase=propose → sdd-propose
Fast path?    → switch to sdd-quick after Propose
```
Each phase writes to `sdd/registry/{change-id}/{phase}.md`.

### Delivery-Harness
Use when task list >5 apply steps.

## Examples (1)
**Fast path** (typo, 2 files, known): All ✓ → Propose: "Fix typo (src/ui/greeting.ts, tests/ui/greeting.test.ts)" → Apply → Verify: npm test → Archive: git commit (~5 min vs 45 min)

## Testing Patterns (3)
1. **Phase compliance**: Each phase produces artifact in registry/{id}/ (9 files: 00-init through 08-archive.md)
2. **Cross-phase traceability**: Scenario → ≥1 task → ≥1 test. Count via grep. Assert: tasks ≥ scenarios ≥ tests.
3. **Regression gate**: Pre-apply baseline (suite pass count). Post-verify assert pass count ≥ baseline. New failure = BLOCK.

## Edge Cases (4)
1. **When NOT to use**: Hotfix <5 min → `quick-executor` | Refactor >10 files → `refactoring-planner` + `delivery-harness` | Spike/prototype → timebox, no artifacts | Config-only → `quality-gate` only
2. **Legacy boundaries**: No tests → Init adds "test strategy" | No CI → Init bootstraps CI before Explore | Unknown deps → Explore produces dep graph + risk | Mixed paradigms → Design specifies boundary layer (adapter/facade)
3. **T1 vs T4**: T1 (<1 file) → Skip | T2 (1-3, known) → sdd-quick | T3 (4-8, MED) → Full | T4 (8+, HIGH) → Full + harness
4. **Schema/auth/API detection**: Schema (DB migration, GraphQL/OpenAPI) → Full | Auth (new role, perm, token, session) → Full | API (new endpoint, breaking, version) → Full | False positive: internal refactor w/o external contract → sdd-quick OK

## Anti-Patterns (7)
1. Skip phases in THOROUGH — gates = traceability
2. Archive without verify — snapshot useless if verify failed
3. Design before scope — Propose defines In/Out; without it = creep
4. Spec without edge cases — happy-path misses 80% bugs (boundary, error, nil, concurrency)
5. Apply before verify — TDD needs red phase first
6. sdd-quick for HIGH-risk — criteria are gates, not suggestions
7. No rollback plan — every proposal must define "undo in 5 min"