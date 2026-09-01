---
name: delivery-harness
description: "Orchestrate multi-agent work — break goals into work units, delegate with isolation, collect results, handle failures"
triggers: "Coordinate, orchestrate, multi-agent, delegate work"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2500
---

## When to Use
Orchestrate multi-agent work — break goals into work units,

Trigger: Multi-step tasks, parallel subagent work, complex deliverables.

## WORKFLOW
1. **Analyze** — read goal, assess complexity (Low/Med/High → 1/3-5/5-10 units)
2. **Break down** — split into independent work units (SDD: propose→spec→design→tasks→apply→verify)
3. **Map deps** — build dependency graph: A→B (serial), A∥B (parallel)
4. **Delegate** — launch each unit via `task(subagent_type=...)` with:
   - Clean context per delegation (subagent-isolation rule #1)
   - Exact file paths + Engram IDs for decisions
   - Success criteria per unit
   - **Request structured output**: each delegation MUST return 4-field block preserved as-is:
     `## Decision Taken | ## Files Changed | ## Key Findings | ## Nuance (what would be lost in summary)`
5. **Collect** — gather results, verify each meets criteria
6. **Reconcile** — merge outputs, resolve conflicts (or escalate)
7. **Report** — one status: units done, failures, rollback path

## Rules
- Parallelize ONLY truly independent units
- If B depends on A → serial, never speculate
- Each unit MUST have: success criteria, rollback command, max retries (default: 1)
- Failure at any unit → either retry with fixed prompt OR rollback ALL
- NEVER share subagent internal state between units
- After collection: summarize results, preserve the 4-field contract AS-IS (never summarize: Decision Taken, Files Changed, Key Findings, Nuance)

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One agent can do it all" | Single agent for >5 files / >20 lines | Decompose into clusters ≤10 files via delivery-harness, verify no file overlap before parallel delegation |
| "Parallel is always faster" | Independent edits sharing file overlap | Collect File overlap check — if overlap, serialize: read-only → independent → dependent → verify |
| "4-field summary is optional" | Squeezing Findings/Nuance into one line | Each subagent returns Decision + Files + Findings + Nuance — merge preserves AS-IS, never summarize away |

## Red Flags
- Post-delegation file overlap detected → STOP, re-partition
- Subagent reports >5 files changed without work-unit split → split via `chained-pr`

## Verification
- `scripts/validate-write-scope.ps1 -AllowedPaths "pattern" -BaseRef HEAD` after delegation
- `git diff --stat` no silent failures; empty+completed → retry narrower scope

## Refs
subagent-isolation · work-unit-commits · command-wrapper · execution-mode · chained-pr
---

docs/skills/delivery-harness/reference.md
---
