---
name: sdd-contracts
description: > Phase contracts: artifact dependencies, result contracts, shared grammar.
  Trigger: Starting SDD cycle, between phases, artifact validation.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## PHASE CONTRACTS
Before any phase: validate inputs exist. After: validate outputs.

| Phase | Requires | Produces |
|-------|----------|----------|
| **explore** | Task + codebase | `analysis.md` |
| **propose** | `analysis.md` | `proposal.md` |
| **spec** | `proposal.md` | `spec.md` (reqs + G/W/T) |
| **design** | `spec.md` | `design.md` (decisions + data flow) |
| **tasks** | `spec.md` + `design.md` | `tasks.md` (file:line steps) |
| **apply** | `tasks.md` + `spec.md` + `design.md` | Code + tests |
| **verify** | `spec.md` + code + tests | `verify-report.md` |
| **archive** | All artifacts | Archive + `delta.md` |

## GRAMMAR (all artifacts)
```
change:{name} phase:{phase} depends_on:[{phase}] satisfies:[{req}]
content: WHAT not HOW · RFC 2119 · G/W/T · explicit trade-offs
```

## DAG (no skipping)
```
explore → propose → spec → design → tasks → apply → verify → archive
```

## VALIDATION
| Condition | Action |
|-----------|--------|
| Input missing | STOP → run prerequisite phase |
| Input stale | FLAG → ask re-validation |
| Bad output | Return schema violations |
| Phase skipped | BLOCK → ask user |
