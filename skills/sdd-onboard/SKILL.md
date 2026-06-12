---
name: sdd-onboard
description: >
  sdd-onboard skill
triggers: "Guided SDD walkthrough"
  Trigger: Orchestrator launches onboarding.
license: MIT
metadata: author: gentleman-vMK, version: "1.1"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-onboard` sub-agent.
Executor sub-agent? → proceed.

## PHASES
1.Welcome+scan: small improvement opportunity
2.Explore: analyze current code → explain
3.Propose: write proposal.md
4.Specs: Given/When/Then
5.Design: decisions + rationale
6.Tasks: concrete steps (file:line)
7.Apply: implement tasks
8.Verify: compliance matrix
9.Archive: merge delta→main
10.Summary: what built

## RULES
- REAL change, production quality
- Ask before continuing past Phase 3
- Blockers→STOP explain
- Adapt tone to user level
