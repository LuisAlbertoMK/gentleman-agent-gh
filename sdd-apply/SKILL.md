---
name: sdd-apply
description: > Implement tasks per specs/design.
  Trigger: Orchestrator launches implementation.
license: MIT
metadata: author: gentleman-programming, version: "3.2"
---

## CONTRACT
engram: read spec/design/tasks, mem_update progress
openspec: update tasks.md with [x] | hybrid: both | none: return

## STEPS
1. Skills→read(spec,design,patterns,conventions)
2. TDD strict? load strict-tdd.md
3. Execute: task→read spec scenarios→design→write→mark[x]
4. Return: {completed, files, deviations, issues, status}

## RULES
- Specs first, match design, mark [x] as you go
- Design wrong→NOTE, Blocked→STOP
- Strict TDD overrides step 3
