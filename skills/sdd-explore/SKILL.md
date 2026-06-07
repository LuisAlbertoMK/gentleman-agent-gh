---
name: sdd-explore
description: > Explore codebase before change.
  Trigger: Orchestrator launches exploration.
license: MIT
metadata: author: gentleman-programming, version: "2.1"
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