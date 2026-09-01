---
name: plan-execution
description: "Trigger: execute plan, implement plan, step-by-step execution, plan completion. Execute plans with rollback."
triggers: "execute plan, implement plan, step-by-step execution, task execution, plan completion, run plan, do plan"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2303
---
## When to Use
Executing a multi-step plan (from agent, spec, or task list). NOT for 1-file edits (→ quick-executor) or single-concept changes.

## WORKFLOW

**Step 0: ISOLATE**
- Create branch: `git checkout -b plan/<name>` (if git available)
- Commit baseline state for rollback

**Step 1: READ** — Load plan completely. Identify tasks, dependencies, success criteria.

**Step 2: ORDER** — Sequence by dependency. Mark parallelizable items.

**Step 3: EXECUTE** — One task at a time:
- Implement
- Verify (see gates below)
- If verify fails → rollback: `git checkout -- <modified-files>` → mark BLOCKED → continue unblocked tasks
- Mark complete

**Step 4: VERIFY** — Full test suite + build at end.

**Step 5: REPORT** — Summary of done/blocked/failed.

## FAILURE RULES
- 3 failures total OR 2 consecutive → STOP, report to orchestrator
- Blocked ≠ failed. Blocked tasks remain in queue.
- Never mark done without executing.

## OUTPUT
```
### Plan Execution
| Task | Status | Verified | Notes |
### Summary
- Completed: X/Y
- Blocked: X (reasons)
- Failed: X (reasons)
### Final State
- Branch: [name]
- Last commit: [hash]
```

## Rules
1. Isolate before execute. 2. Verify EVERY task. 3. Rollback on failure. 4. 3 total or 2 consecutive failures → STOP.

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
quick-executor · deep-debugging · quality-gate

---
---

docs/skills/plan-execution/reference.md
---

