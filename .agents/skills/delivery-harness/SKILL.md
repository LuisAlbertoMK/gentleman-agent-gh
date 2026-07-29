---
name: delivery-harness
description: "Orchestrate multi-agent work — break goals into work units, delegate with isolation, collect results, handle failures"
triggers: "Coordinate, orchestrate, multi-agent, delegate work"
---

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

## RULES
- Parallelize ONLY truly independent units
- If B depends on A → serial, never speculate
- Each unit MUST have: success criteria, rollback command, max retries (default: 1)
- Failure at any unit → either retry with fixed prompt OR rollback ALL
- NEVER share subagent internal state between units
- After collection: summarize results, preserve the 4-field contract AS-IS (never summarize: Decision Taken, Files Changed, Key Findings, Nuance)

## ERROR HANDLING
| Failure | Action |
|---------|--------|
| Subagent timeout | Retry once with stricter scope, then flag BLOCKER |
| Wrong output | Re-delegate with corrected context + Engram ID of error |
| Dependency fail | Cascade: rollback dependents, report partial delivery |
| Merge conflict | Open conflict file, delegate resolution to human |

## DEPENDENCIES
- subagent-isolation (context boundaries)
- work-unit-commits (commit organization)
- command-wrapper (safe command execution)

## Refs
subagent-isolation · work-unit-commits · command-wrapper · execution-mode · chained-pr

## Anti-Patterns
Parallelize dependent units · Share context between subagents · No rollback plan · Skip unit success criteria · Collect without verifying
