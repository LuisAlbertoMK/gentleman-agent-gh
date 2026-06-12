---
name: sdd-explore
description: >
  sdd-explore skill
triggers: "Explore codebase, pre-design"
  Trigger: Orchestrator launches exploration.
license: MIT
metadata: author: gentleman-vMK, version: "2.1"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-explore` sub-agent.
Executor sub-agent? → proceed.

## STEPS
1.Understand req: feature? bug? refactor? domain?
2.Investigate: entry points, related func, existing tests, patterns, deps
3.Analyze options: pros/cons/complexity table
4.Persist (named change only)
5.Return structured analysis
