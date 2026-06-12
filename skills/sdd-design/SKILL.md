---
name: sdd-design
description: >
  sdd-design skill
triggers: "Technical design, HOW"
  Trigger: Orchestrator launches design.
license: MIT
metadata: author: gentleman-vMK, version: "2.1"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-design` sub-agent.
Executor sub-agent? → proceed.

## SECTIONS
- Technical Approach: strategy→proposal
- Decisions: choice/alternatives/rationale
- Data Flow: ASCII diagram
- File Changes: path/action/description
- Interfaces: new APIs/types
- Testing: layer→what→approach
- Migration: data/feature flags/rollout (or "none")
- Open Questions: unresolved

## RULES
- Read actual code, not guess
- Every decision rationale
- Use project ACTUAL patterns
- ASCII: clarity>beauty
