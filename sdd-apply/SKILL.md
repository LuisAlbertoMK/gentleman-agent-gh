---
name: sdd-apply
description: >
  Implement tasks from change, writing code per specs and design.
  Trigger: Orchestrator launches you to implement one or more tasks.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

## Purpose
IMPLEMENTATION sub-agent. Receive tasks from `tasks.md`, implement with real code. Follow specs and design strictly.

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read spec/design/tasks. Mark tasks via `mem_update(tasks-id)`. Save progress as `sdd/{change}/apply-progress`
- **openspec**: Follow `_shared/openspec-convention.md`. Update `tasks.md` with `[x]`
- **hybrid**: BOTH — `mem_update` + `[x]` in tasks.md
- **none**: Return progress only

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Read Context
1. Specs → WHAT code must do
2. Design → HOW to structure
3. Existing code → current patterns
4. `config.yaml` → conventions

**Step 2b: Read Previous Progress**
`mem_search("sdd/{change}/apply-progress")` → if found, parse completed tasks → skip them → MERGE with new completions. CRITICAL: overwrite without reading = lost work.

### 3: Resolve TDD Mode
```
Cached testing capabilities → strict_tdd?
├─ true + runner → STRICT TDD (load strict-tdd.md)
└─ false/no runner → STANDARD (no TDD, zero tokens)
```

**Strict TDD Hard Gate**: MUST produce TDD Cycle Evidence table (RED→GREEN→REFACTOR per task). No silent fallback.

### 4: Implement Tasks (Standard)
```
FOR EACH TASK:
  Read description → Read spec scenarios (acceptance criteria)
  → Read design decisions → Match existing patterns → Write code
  → Mark [x] in tasks.md → Note deviations
```

### 5: Mark Tasks Complete
Update `tasks.md`: `- [ ]` → `- [x]` for completed tasks.

### 6: Persist Progress (MANDATORY)
artifact: `apply-progress` | topic_key: `sdd/{change}/apply-progress` | type: `architecture`
**Merge Protocol**: Include ALL previously completed tasks + new completions. Cumulative state.

### 7: Return Summary
```
## Implementation Progress
**Change**: {name} | **Mode**: {Strict TDD | Standard}

### Completed
- [x] {task 1.1}
- [x] {task 1.2}

### Files Changed
| File | Action | What Done |

{TDD Evidence table if Strict TDD}

### Deviations
{List or "None"}

### Issues
{List or "None"}

### Status
{N}/{total} tasks. {Ready for next / Ready for verify / Blocked by X}
```

## Rules
- ALWAYS read specs first — they are acceptance criteria
- ALWAYS follow design decisions
- ALWAYS match existing patterns
- openspec: mark `[x]` AS you go
- Design wrong/incomplete → NOTE in summary, don't silently deviate
- Task blocked → STOP and report
- NEVER implement unassigned tasks
- Strict TDD active → load strict-tdd.md, OVERRIDE Step 4
- Return envelope per `_shared/sdd-phase-common.md` Section D.
