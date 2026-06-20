---
name: refactoring-planner
description: "Plan refactoring with impact analysis, dependency mapping, and step-by-step migration with test baseline"
triggers: "Refactor, refactoring, reestructurar, migrate"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.0->1.1 (Karpathy compress: 2618->1700B)"
---

## Pre-flight assessment
| Check | Question | Blocker? |
|-------|----------|----------|
| Tests | Existing? Pass rate? | Yes -- no refactor without baseline |
| Coverage | Line %? | Yes if <40% -- write tests first |
| Dependencies | What depends on this? | Yes -- map before touching |
| Risk | How critical? | High -> incremental; Low -> direct |

## Step types
| Type | Risk | Rollback | Evidence |
|------|------|----------|----------|
| Extract fn | Low | Single revert | Tests pass |
| Rename/move | Low-Med | Single revert | Tests pass + no import errors |
| Change signature | Med | Revert + fix callers | Tests pass + integration |
| Split module | High | Full revert | All above + no regression |
| Merge modules | High | Full revert | All above + perf check |

## Rules
1. NEVER refactor without test baseline -- no tests -> first task: add tests
2. Each step independently revertible
3. After EACH step: `go test ./...`. Never batch before testing
4. Track: `[x] Step N`
5. Step fails -> stop, analyze, fix or rollback

## Output template
```
## Refactor Plan: {target}
### Risk Level: LOW/MED/HIGH
### Dependency Map: {A} <- {B} <- {C} (target)
### Steps
1. [SAFE] Action -- tests pass, single revert
2. [MODERATE] Action -- tests pass, update imports
3. [RISKY] Action -- integration tests, revert + rebase
### Acceptance: after each step -> tests pass
```
