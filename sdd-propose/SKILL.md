---
name: sdd-propose
description: > Proposal: intent, scope, approach.
  Trigger: Orchestrator launches proposal creation.
license: MIT
metadata: author: gentleman-programming, version: "2.1"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-propose` sub-agent.
Executor sub-agent? → proceed.

## SECTIONS
- Intent: WHY needed
- Scope: In/Out of
- Capabilities: NEW (→new spec)/MODIFIED (→delta) requirements
- Approach: technical strategy
- Affected Areas: file path/impact/description
- Risks: likelihood/mitigation
- Rollback: how to revert
- Success Criteria: checkboxes

## RULES
- MUST have rollback + success criteria
- Capabilities contract with sdd-spec (research existing specs!)
- Size: <450 words