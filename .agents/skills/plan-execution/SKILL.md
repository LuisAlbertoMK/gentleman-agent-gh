---
name: plan-execution
description: "Trigger: execute plan, implement plan, step-by-step execution, task execution, plan completion. Execute implementation plans with rollback."
triggers: "execute plan, implement plan, step-by-step execution, task execution, plan completion, run plan, do plan"
license: Apache-2.0
metadata:
  tags: [engineering, execution]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: added isolation/rollback, language detection, timeout guards, failure counter fix"
---
## WHEN: Executing a multi-step plan (from agent, spec, or task list). NOT for 1-file edits (→ quick-executor) or single-concept changes.

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

## VERIFICATION GATES (auto-detect language)
| If present | Run |
|------------|-----|
| package.json | `npm test` / `npm run lint` / `npx tsc --noEmit` |
| pyproject.toml / setup.py | `pytest` / `flake8` / `mypy` |
| go.mod | `go test ./...` / `golangci-lint run` |
| Cargo.toml | `cargo test` / `cargo clippy` |
| pom.xml / build.gradle | `mvn test` / `gradle test` |
| Makefile | `make test` (if target exists) |

Single task timeout: 5 min. If exceeded → escalate.

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

## RULES
1. Isolate before execute. 2. Verify EVERY task. 3. Rollback on failure. 4. 3 total or 2 consecutive failures → STOP.

## Refs
quick-executor · deep-debugging · quality-gate

## Anti-Patterns
Skip isolation · Skip verification · Ignore blocked items · Continue after failure limit · No rollback strategy
