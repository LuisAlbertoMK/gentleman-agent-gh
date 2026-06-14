---
name: sdd-explore
description: >  sdd-explore skill
triggers: "Explore codebase, pre-design"
license: MIT
metadata: author: gentleman-vMK, version: "2.1"
---

Trigger: Orchestrator launches exploration.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-explore` sub-agent.Executor sub-agent? â†’ proceed.
## STEPS1.Understand req: feature? bug? refactor? domain?2.Investigate: entry points, related func, existing tests, patterns, deps3.Analyze options: pros/cons/complexity table4.Persist (named change only)5.Return structured analysis
