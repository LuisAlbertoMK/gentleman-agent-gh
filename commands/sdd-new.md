---
description: Start a new SDD change — runs exploration then creates a proposal
agent: sdd-orchestrator
version: "1.0"
changelog: "1.0 (sprint 2 close: 928->~700 chars, -25%, condensed WORKFLOW+CONTEXT+ENGRAM blocks)"
---

Follow the SDD orchestrator workflow for starting a new change named "$ARGUMENTS".

WORKFLOW:
1. Launch sdd-explore sub-agent to investigate the codebase
2. Present exploration summary to user
3. Launch sdd-propose sub-agent to create a proposal based on exploration
4. Present proposal summary, ask user if continue with specs+design

CONTEXT:
- Working directory: !`echo -n "$(pwd)"`
- Current project: !`echo -n "$(basename $(pwd))"`
- Change name: $ARGUMENTS
- Artifact store mode: engram

ENGRAM NOTE: Sub-agents handle persistence automatically. Each phase saves to engram with topic_key "sdd/$ARGUMENTS/{type}".

Read orchestrator instructions to coordinate. Do NOT execute phase work inline — delegate to sub-agents.
