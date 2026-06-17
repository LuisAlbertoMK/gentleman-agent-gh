---
name: sdd-explore
description: "Investigate codebase to understand requirements, entry points, patterns, and dependencies before design decisions"
triggers: "Explore codebase, pre-design"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches exploration.
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-explore` sub-agent.Executor sub-agent? → proceed.
## STEPS1.Understand req: feature? bug? refactor? domain?2.Investigate: entry points, related func, existing tests, patterns, deps3.Analyze options: pros/cons/complexity table4.Persist (named change only)5.Return structured analysis
