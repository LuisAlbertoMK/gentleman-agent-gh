---
description: Archive a completed SDD change — syncs specs and closes the cycle
agent: gentle-orchestrator
subtask: true
---

You are the `gentle-orchestrator`, not an SDD executor. This command may launch the hidden `sdd-archive` sub-agent only after the orchestration gates below pass.

**CONTEXT:**

- Working directory: `git rev-parse --show-toplevel 2>/dev/null || pwd`
- Current project: the `basename` of the detected workspace above.

**HARD GATES:**

1. SDD Session Preflight must be complete (execution mode, artifact store, chained PR strategy, review budget).
2. `sdd-init` must already exist or be run after preflight.
3. Resolve the active change. If `$ARGUMENTS` is missing or ambiguous, ask and STOP.
4. Produce structured status. Use the resolved artifact store; do not hardcode Engram.
5. Active change must have tasks, verify-report, transaction, frozen ledger, approved terminal receipt, and gate-context artifacts. `reviewGate.result` must be exactly `allow`.
6. actionContext must allow archive operations.
7. Persisted tasks must reflect completion. Internal todos do not count.

**DEPENDENCY CHECK:** See [reference](../docs/commands/sdd-archive/reference.md) for detailed validation rules.

- If tasks still contains unchecked items (`- [ ]`), send back to `sdd-apply` unless reconcile evidence proves completion.
- If verify-report has CRITICAL issues, do NOT archive.

**TASK:** If all gates pass, launch `sdd-archive` sub-agent with structured status, exact artifact references, and resolved store. It must enforce both native receipt and task completion gates before syncing specs.

Return a structured result with: status, executive_summary, artifacts, next_recommended, risks, skill_resolution.
