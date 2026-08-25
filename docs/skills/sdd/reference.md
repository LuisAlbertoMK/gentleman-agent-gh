# sdd — Reference Materials

> **Externalized from** .agents/skills/sdd/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains examples, testing patterns, and edge cases.

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
