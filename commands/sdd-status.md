---
description: Show structured SDD status for an active change
agent: gentle-orchestrator
---

You are the `gentle-orchestrator`. This command is read-only. Do not launch SDD executors and do not edit files.

**HARD GATE:** SDD Session Preflight must already be complete (execution mode, artifact store, chained PR strategy, review budget). If missing, ask the preflight prompt and STOP.

**CONTEXT:**

- Working directory: `git rev-parse --show-toplevel 2>/dev/null || pwd`
- Change name: `$ARGUMENTS`

**TASK:**

1. Resolve status via `gentle-ai sdd-status [change] --cwd <repo> --json --instructions` (openspec/hybrid) or Engram (engram store). See [reference](../docs/commands/sdd-status/reference.md) for dispatch details.
2. Resolve the active change: use `$ARGUMENTS` if provided; if omitted and one active change exists, select it; if ambiguous, ask and STOP.
3. Inspect the artifact store from session preflight. Do not hardcode Engram.
4. Return structured status with: change selection, schemaName, planningHome, changeRoot, artifactPaths, contextFiles, artifact statuses, task progress, dependency states, next recommended action, actionContext, and allowed edit roots.

**READ-ONLY RULES:**

- Do not create, update, or delete artifacts. Do not mark tasks complete.
- Do not launch apply, verify, archive, or continue.
- Route only by `nextRecommended` and dependency states. See [reference](../docs/commands/sdd-status/reference.md) for routing rules.
- If status cannot be resolved safely, return `status: blocked` with the missing information.
