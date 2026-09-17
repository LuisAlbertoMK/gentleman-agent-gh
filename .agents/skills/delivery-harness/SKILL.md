---
name: delivery-harness
description: "Orchestrate multi-agent work — break goals into work units, delegate with isolation, collect results, handle failures"
triggers: "Coordinate, orchestrate, multi-agent, delegate work"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2800
---
## Workflow
1. **Analyze** — assess complexity (Low/Med/High → 1/3-5/5-10 units)
2. **Break down** — independent work units (SDD: propose→spec→design→tasks→apply→verify)
3. **Map deps** — A→B (serial), A∥B (parallel)
4. **Fit gate (mandatory)** — `delegation-fit-gate.ps1 -AgentName <a> -FileCount <n> -LineCount <n>`; FAIL→re-partition ≤10 files or re-route (Orchestrator Guard)
5. **Delegate** — clean context (subagent-isolation #1), file paths + Engram IDs, success criteria, 4-field output block: `Decision Taken | Files Changed | Key Findings | Nuance`. First window→`gentleman-initializer`.
6. **Collect** — verify each meets criteria
7. **Reconcile** — merge, resolve conflicts
8. **Report** — units done, failures, rollback path

## Rules
- Parallelize ONLY independent units; B depends on A→serial
- Each unit: success criteria, rollback command, max retries (default 1)
- Failure→retry fixed prompt OR rollback ALL
- NEVER share subagent internal state
- Preserve 4-field contract AS-IS (never summarize)

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One agent can do it all" | >5 files / >20 lines single agent | Decompose ≤10 files, verify no overlap |
| "Parallel is always faster" | File overlap between units | Serialize overlapping units |
| "4-field summary is optional" | Squeezing Findings/Nuance | Preserve AS-IS, never summarize away |
| "Gate FAIL is advisory" | Delegating with FAIL | Re-partition or re-route |

## Red Flags
- File overlap post-delegation → STOP, re-partition
- >5 files changed without split → `chained-pr`
- delegation-fit-gate FAIL ignored → STOP

## Verification
- Pre: `& scripts/delegation-fit-gate.ps1 -AgentName <a> -FileCount <n> -LineCount <n>`; FAIL→re-partition
- Post: `& scripts/validate-write-scope.ps1 -AllowedPaths "pattern" -BaseRef HEAD`
- `git diff --stat` — no silent failures; empty+completed→retry narrower

→ docs/skills/delivery-harness/reference.md · Cross-Refs: subagent-isolation · work-unit-commits · command-wrapper · execution-mode · chained-pr
