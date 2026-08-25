---
name: sdd
description: "pipeline — 9 phases. Use sdd-quick for LOW-risk fast path."
triggers: "pipeline, phase, spec-driven development"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1582
---
# Pipeline
**Fast path for LOW-risk:** `{file:sdd-quick/SKILL.md}` — 3 phases.
## Protocol
All phases share: `{file:sdd/references/sdd-phase-common.md}`
## Usage
**Orchestrator**: Load for overview → load phase for details.
**Subagent**: Load phase via `{file:sdd/phases/{N}-{name}.md}`.
## Choosing Your Path
Fast (sdd-quick): ≤3 files, no schema/auth/API/deps, LOW risk, known codebase. Full (9-phase): otherwise.
**Gate**: If ANY "No" → full. `Known? ← Schema? ← No deps? ← LOW risk? ← <4 files?` Unsure: start full; switch after Explore.
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
## Anti-Patterns (7)
1. Skip phases in THOROUGH — gates = traceability
2. Archive without verify — snapshot useless if verify failed
3. Design before scope — Propose defines In/Out; without it = creep
4. Spec without edge cases — happy-path misses 80% bugs
5. Apply before verify — TDD needs red phase first
6. sdd-quick for HIGH-risk — criteria are gates, not suggestions
7. No rollback plan — every proposal must define "undo in 5 min"
## Reference
Examples (1) + Testing Patterns (3) + Edge Cases (4) → docs/skills/sdd/reference.md
