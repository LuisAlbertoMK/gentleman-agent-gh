---
name: sdd-apply
description: > Implement tasks per specs/design.
  Trigger: Orchestrator launches implementation.
license: MIT
metadata: author: gentleman-programming, version: "3.3"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-apply` sub-agent.
Executor sub-agent? → proceed (gate does NOT apply).

## CONTRACT
Read spec/design/tasks first. Persist per mode:
- **engram**: `mem_save/topic_key: sdd/{change}/apply-progress` + `mem_update` tasks
- **openspec**: `tasks.md` mark [x] + save to `openspec/changes/{change}/apply-progress.md`
- **hybrid**: both | **none**: return only

## STEPS
1. Read spec/design/tasks + existing code patterns + conventions
2. Workload check: if forecast >400 lines or `Chained PRs recommended` and NO delivery decision → **BLOCKED** (return `workload-decision-required`)
3. Previous progress? `mem_search(sdd/{change}/apply-progress)` → read + MERGE (never overwrite)
4. Strict TDD? → load `strict-tdd.md`, produce TDD Cycle Evidence table
5. Execute per task: read spec scenarios → design → write code → mark [x]
6. Persist progress (cumulative — include ALL prior completed tasks)
7. Return summary

## RETURN
```
Change: {name} | Mode: {Strict TDD | Standard}
Tasks: {N}/{total} complete
Files: {path} | {Created/Modified} | {what}
Deviations: {list or "None"}
Issues: {list or "None"}
Status: {Ready for verify / Blocked by X}
```

## RULES
- Specs first, design second — never freelance
- Design wrong? NOTE it. Blocked? STOP.
- Never overwrite apply-progress — always MERGE with previous
- If workload decision missing → STOP before writing code
- Strict TDD overrides step 5
