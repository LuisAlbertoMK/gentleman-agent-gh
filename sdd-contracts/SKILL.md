---
name: sdd-contracts
description: > Phase contracts: artifact dependencies, result contracts, shared grammar.
  Trigger: Starting SDD cycle, between phases, "qué necesita esta fase", artifact validation.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## PHASE CONTRACTS

Each SDD phase has REQUIRED inputs and PRODUCED outputs. Before running a phase, validate inputs exist. After running, validate outputs produced.

| Phase | Requires (inputs) | Produces (outputs) |
|-------|-------------------|---------------------|
| **explore** | Task description, codebase | `analysis.md` (findings, options, recommendations) |
| **propose** | `analysis.md` | `proposal.md` (intent, scope, approach, risks, rollback) |
| **spec** | `proposal.md` | `spec.md` (requirements + Given/When/Then scenarios) |
| **design** | `spec.md` | `design.md` (approach, decisions, data flow, interfaces) |
| **tasks** | `spec.md` + `design.md` | `tasks.md` (actionable steps with file:line) |
| **apply** | `tasks.md` + `spec.md` + `design.md` | Code changes + test files |
| **verify** | `spec.md` + code changes + test results | `verify-report.md` (compliance matrix) |
| **archive** | All phase artifacts | Archive folder + `delta.md` |

## SHARED GRAMMAR

All SDD artifacts follow this grammar:

```
change: {name}
phase: {explore|propose|spec|design|tasks|apply|verify|archive}
depends_on: [{phase}]     # phases this artifact depends on
satisfies: [{requirement}] # spec scenarios satisfied (apply/verify only)

content:
  - WHAT (not HOW for specs)
  - RFC 2119 keywords (MUST/SHALL/SHOULD/MAY)
  - Given/When/Then for scenarios
  - Trade-offs explicit for decisions
```

## VALIDATION RULES

1. **Before any phase**: check that REQUIRED inputs exist with proper content
2. **If input missing**: STOP → report → run prerequisite phase first
3. **If input stale**: flag that it may be outdated, suggest re-validation
4. **After output**: verify it satisfies the contract schema above

## DEPENDENCY GRAPH (DAG)

```
explore → propose → spec → design → tasks → apply → verify → archive
  ↑          ↑         ↑        ↑       ↑       ↑        ↑        ↑
  └──────────┴─────────┴────────┴───────┴───────┴────────┴────────┘
                    (all flow forward, no skipping)
```

## ERROR HANDLING

| Error | Action |
|-------|--------|
| Missing input artifact | STOP → report which artifact → suggest running previous phase |
| Stale input (modified after phase ran) | FLAG → ask user if re-validation needed |
| Output doesn't match contract | Return error with schema violations |
| Phase skipped | BLOCK if next phase depends on it → ASK user |
