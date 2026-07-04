---
description: Fast-forward all SDD planning phases — proposal through tasks
agent: sdd-orchestrator
version: "1.0"
changelog: "1.0 (sprint 2 close: 971->~700 chars, -28%, condensed WORKFLOW list to inline, merged CONTEXT+ENGRAM)"
---

Follow the SDD orchestrator workflow to fast-forward all planning phases for change "$ARGUMENTS".

WORKFLOW (run sub-agents in sequence):
sdd-propose → sdd-spec → sdd-design → sdd-tasks
Present combined summary AFTER all phases (not between each).

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Change name: $ARGUMENTS
- Artifact store mode: engram

ENGRAM PERSISTENCE: See [\_shared/engram-convention.md](../.agents/skills/_shared/engram-convention.md) for full protocol.

Read orchestrator instructions. Do NOT execute phase work inline — delegate to sub-agents.
