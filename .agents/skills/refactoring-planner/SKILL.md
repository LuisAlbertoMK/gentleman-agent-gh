---
name: refactoring-planner
description: >  refactoring-planner skill
triggers: "Refactor, refactoring, reestructurar, migrate"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

Plan refactoring with impact analysis, dependency mapping, and step-by-step migration.Trigger: "refactor", "refactoring", "reestructurar", "migrate", "reorganizar".
## WhenUser asks to refactor, restructure, migrate, or reorganize code.
## Critical Patterns
### Pre-flight assessment| Check | Question | Blocker? ||-------|----------|----------|| Tests | Existing? How many pass? | Yes â€” no refactor without test baseline || Coverage | What % line coverage? | Yes if <40% â€” write tests first || Dependencies | What depends on this code? | Yes â€” map before touching || Risk | How critical is this path? | High risk â†’ incremental, low risk â†’ direct |
### Output structure
```
## Refactor Plan: {target}
### Risk Level: LOW / MEDIUM / HIGH
### Dependency Map{file A} â† {file B} â† {file C} (target)  â†‘          â†‘{file D}   {file E}
### Steps1. [SAFE] Extract `X()` from file.go â€” no behavior change   - Test: existing tests still pass   - Rollback: revert single commit2. [MODERATE] Move `Y()` to new pkg â€” update imports   - Test: `go test ./...`   - Rollback: git revert3. [RISKY] Change signature of `Z()` â€” affects 3 callers   - Test: run integration tests   - Rollback: git revert + rebase
### Acceptance: after each step â†’ tests pass. Never break.
```
### Step types| Type | Risk | Rollback | Evidence needed ||------|------|----------|-----------------|| Extract fn | Low | Single revert | Tests pass || Rename/move | Low-Med | Single revert | Tests pass + no import errors || Change signature | Med | Revert + fix callers | Tests pass + integration || Split module | High | Full revert | All of above + no regression || Merge modules | High | Full revert | All of above + perf check |
### Rules1. NEVER refactor without test baseline. If no tests â†’ first task is "add tests"2. Each step must be independently revertible3. After EACH step: `go test ./...` (or equivalent). Never batch steps before testing.4. Track progress: `[x] Step 1` `[ ] Step 2`5. If a step fails â†’ stop, analyze, fix or rollback that step
