---
name: sdd-apply
description: > Implement tasks: write code per specs/design.
  Trigger: Orchestrator launches implementation.
license: MIT
metadata: author: gentleman-programming, version: "3.0"
---

## CONTRACT
engrm: read spec/des/tasks, mem_update progress
openspec: update tasks.md with [x]
hybrid: both
none: return only

## STEPS
1.Load skills
2.Read: specs→WHAT, design→HOW, existing→patterns, config→conventions
3.TDD mode: caps→strict_tdd? TRUE→load strict-tdd.md
4.Execute: task→read spec(scenarios)→read design→match patterns→write→mark[x]
5.Persist: apply-progress
6.Return: {completed/files changed/deviations/issues/status}

## RULES
- ALWAYS specs first (acceptance), design decisions, match patterns
- openspec: mark [x] AS you go
- Design wrong→NOTE not silent deviate
- Blocked→STOP report
- Strict TDD→strict-tdd.md OVERRIDES Step 4