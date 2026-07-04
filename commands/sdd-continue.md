---
description: Continue the next SDD phase in the dependency chain
agent: sdd-orchestrator
version: "1.0"
changelog: "1.0 (sprint 2 close: 1043->~750 chars, -28%, condensed WORKFLOW+CONTEXT+ENGRAM blocks)"
---

Follow the SDD orchestrator workflow to continue the active change.

WORKFLOW:
1. Check which artifacts exist (proposal, specs, design, tasks)
2. Determine next phase from dependency graph: proposal → [specs ∥ design] → tasks → apply → verify → archive
3. Launch appropriate sub-agent(s) for next phase
4. Present result, ask user to proceed

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Change name: $ARGUMENTS
- Artifact store mode: engram

ENGRAM PERSISTENCE: See [\_shared/engram-convention.md](../.agents/skills/_shared/engram-convention.md) for full protocol.

Read orchestrator instructions. Do NOT execute phase work inline — delegate to sub-agents.
