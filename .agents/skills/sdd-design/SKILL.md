---
name: sdd-design
description: "Create technical design documents with architecture decisions, data flow diagrams, file change plans, and testing approach"
triggers: "Technical design, HOW"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches design.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-design` sub-agent.Executor sub-agent? â†’ proceed.
## SECTIONS- Technical Approach: strategyâ†’proposal- Decisions: choice/alternatives/rationale- Data Flow: ASCII diagram- File Changes: path/action/description- Interfaces: new APIs/types- Testing: layerâ†’whatâ†’approach- Migration: data/feature flags/rollout (or "none")- Open Questions: unresolved
## RULES- Read actual code, not guess- Every decision rationale- Use project ACTUAL patterns- ASCII: clarity>beauty
