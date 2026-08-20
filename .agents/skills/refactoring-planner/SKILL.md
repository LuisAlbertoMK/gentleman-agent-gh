---
name: refactoring-planner
description: "Plan refactoring with impact analysis, dependency mapping, and step-by-step migration with test baseline"
triggers: "Refactor, refactoring, reestructurar, migrate"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Refactoring: impact analysis, dependency mapping, migration. Test baseline mandatory.

## Pre-flight
| Check | Question | Blocker? |
|---|---|---|
| Tests | Existing? Pass rate? | Yes — no refactor without baseline |
| Coverage | Line %? | Yes if <40% — tests first |
| Dependencies | What depends on this? | Yes — map before touching |
| Risk | How critical? | High→incremental; Low→direct |

## Step types
| Type | Risk | Rollback | Evidence |
|---|---|---|---|
| Extract fn | Low | Single revert | Tests pass |
| Rename/move | Low-Med | Single revert | Tests + imports |
| Change signature | Med | Revert + fix callers | Tests + integration |
| Split module | High | Full revert | All above + no regression |
| Merge modules | High | Full revert | Above + perf |

## Rules
1. NEVER refactor without test baseline — no tests → add first. 2. Each step independently revertible. 3. After EACH step: `go test ./...`. Never batch. 4. Track `[x] Step N`. 5. Step fails → stop, analyze, fix or rollback.

## Output template
```
## Refactor Plan: {target}
### Risk Level: LOW/MED/HIGH
### Dependency Map: {A} <- {B} <- {C} (target)
### Steps
1. [SAFE] Action -- tests pass, single revert
2. [MODERATE] Action -- tests pass, fix imports
3. [RISKY] Action -- integration tests, revert + rebase
### Acceptance: after each step -> tests pass
```

## Scenario: Split Monolithic Module (HIGH)
1. [PREP] Tests at entry points → baseline pass. 2. [SAFE] Extract `types.go` → tests pass. 3. [SAFE] Extract `db.go` → no import cycles. 4. [MODERATE] Extract `handlers.go` → update routes/imports. 5. [RISKY] Split `internal/db|api|types` → full build + integration. 6. [VERIFY] `go test ./... && go build ./...` → baseline perf.

## Failure Recovery
1. `git diff` → what changed. 2. Failure in refactored code → fix mapping. 3. Unrelated → `git stash` refactor, fix baseline, reapply. 4. Unfixable in 5 min → `git checkout -- .`, redo step. **Rollback**: each step maps to 1-2 files — `git checkout <file>`; `git revert` full branch for split/merge.

## Post-Refactor: mem_save
`title:"Refactored {module} — {extract|rename|split}" type:"architecture" content:"What: {X} from {Y} | Why: {reason} | Where: {paths} | Learned: {gotchas}"`

## Refs
metricas · quality-gate · sdd · code-review-agent · triple-verify

## Examples
"refactoring: split main.go" → `go test ./...` baseline → `git mv main.go types.go` → test → extract db.go → risky split → `go test && go build` acceptance.

## Anti-Patterns
Refactor without baseline · Batch steps before testing · Skip impact analysis · No rollback plan · Change API in same refactor