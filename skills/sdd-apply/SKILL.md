---
name: sdd-apply
description: >
  sdd-apply skill
triggers: "Apply tasks, implement"
  Trigger: Orchestrator launches implementation.
license: MIT
metadata: author: gentleman-vMK, version: "3.3"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-apply` sub-agent.
Executor sub-agent? → proceed (gate does NOT apply).

## CONTRACT
Read spec/design/tasks. Persist:
| Mode | Action |
|------|--------|
| engram | `mem_save(topic_key:sdd/{change}/apply-progress)` + mem_update tasks |
| openspec | tasks.md [x] + `openspec/changes/{change}/apply-progress.md` |
| hybrid | both | none | return only |

## STEPS
1. Read spec/design/tasks + code patterns
2. Workload: >400 lines or `Chained PRs recommended` + no decision → **BLOCKED**(return `workload-decision-required`)
3. Previous progress? `mem_search(sdd/{change}/apply-progress)` → read + MERGE
4. Strict TDD? → load strict-tdd.md, produce TDD Cycle Evidence table
5. Execute: spec scenarios → design → write → mark[x]
6. Persist cumulative progress (ALL prior + new)
7. Return summary

## RETURN
```
{name} | Mode:{Strict TDD|Standard}
Tasks:{N}/{total} | Files:{path}|{action}|{what}
Deviations:{list/"None"} | Issues:{list/"None"}
Status:{Ready|Blocked by X}
```

## RULES
- Specs first, design second | Wrong?NOTE | Blocked?STOP
- NEVER overwrite progress — MERGE
- Missing workload decision → STOP before code
- Strict TDD overrides step 5

