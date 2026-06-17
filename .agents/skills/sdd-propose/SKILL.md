---
name: sdd-propose
description: "Define change proposals with scope, capabilities, approach, risks, rollback plan, and success criteria"
triggers: "Proposal, intent, approach"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches proposal creation.
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-propose` sub-agent.Executor sub-agent? → proceed.
## SECTIONS- Intent: WHY needed- Scope: In/Out of- Capabilities: NEW (→new spec)/MODIFIED (→delta) requirements- Approach: technical strategy- Affected Areas: file path/impact/description- Risks: likelihood/mitigation- Rollback: how to revert- Success Criteria: checkboxes
## RULES- MUST have rollback + success criteria- Capabilities contract with sdd-spec (research existing specs!)- Size: <450 words
