---
description: Continue the next SDD phase in the dependency chain
agent: gentle-orchestrator
---

Follow the SDD orchestrator workflow to continue the active change.

**HARD GATE:** SDD Session Preflight must already be complete (execution mode, artifact store, chained PR strategy, review budget). If missing, ask the preflight prompt and STOP. Do not launch the next phase in the same turn.

**WORKFLOW:**

1. Resolve status via `gentle-ai sdd-continue [change] --cwd <repo>` (openspec/hybrid only) or Engram (engram store). See [reference](../docs/commands/sdd-continue/reference.md) for dispatch details.
2. Determine the next phase from the dependency graph: `proposal → [specs ∥ design] → tasks → apply → verify → archive`.
3. Launch the appropriate sub-agent only if status says the dependency is ready. Route by `nextRecommended` and `blockedReasons`; never infer from free text.
4. Present the result and ask the user to proceed.

**CONTEXT:**

- Working directory: `git rev-parse --show-toplevel 2>/dev/null || pwd`
- Change name: `$ARGUMENTS`
- Execution mode, artifact store, delivery strategy, review budget: ask/cache per orchestrator

**ENGRAM NOTE:** Search `mem_search(query: "sdd/$ARGUMENTS/", project: "{project}")` to list artifacts.

Read the orchestrator instructions to coordinate this workflow. Do NOT execute phase work inline — delegate to sub-agents.

**STATUS CONTRACT:** See [reference](../docs/commands/sdd-continue/reference.md) for adapter-specific status contract paths.
