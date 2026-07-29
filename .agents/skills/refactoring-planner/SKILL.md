---
name: refactoring-planner
description: "Plan refactoring with impact analysis, dependency mapping, and step-by-step migration with test baseline"
triggers: "Refactor, refactoring, reestructurar, migrate"
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

## Scenario: Split Monolithic Module (HIGH risk)
1. [PREP] Write tests at entry points → baseline pass
2. [SAFE] Extract `types.go` from `main.go` → tests pass
3. [SAFE] Extract `db.go` (data layer) → tests pass, no import cycles
4. [MODERATE] Extract `handlers.go` → update routes to import from new pkg
5. [RISKY] Split into `internal/db`, `internal/api`, `internal/types` → full build + integration
6. [VERIFY] `go test ./... && go build ./...` → match baseline perf

## Failure Recovery
**If tests fail after a step:**
1. Run `git diff` to see what changed
2. Failure in refactored code? → fix the mapping error
3. Failure in unrelated code? → `git stash` the refactor, fix baseline, reapply
4. Unfixable in 5 min? → `git checkout -- .` on refactor files, redo step

**Rollback per step:** Each step maps to 1-2 files — `git checkout <file>` reverts single-step damage. Only `git revert` the full branch for split/merge steps.

## Post-Refactor: mem_save
```
title: "Refactored {module} — {extract|rename|split}"
type: "architecture"
content: |
  **What**: Extracted {X} from {Y} into standalone package
  **Why**: {coupling reason, tech debt rationale}
  **Where**: {file paths}
  **Learned**: {import cycle gotcha, unexpected dependency}
```

## Refs
metricas · quality-gate · sdd · code-review-agent · triple-verify

## Anti-Patterns
Refactor without test baseline · Batch steps before testing · Skip impact analysis · No rollback plan · Change API in same refactor
