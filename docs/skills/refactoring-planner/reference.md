# refactoring-planner - Reference Materials

> **Externalized from** .agents/skills/refactoring-planner/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
"refactoring: split main.go" → `go test ./...` baseline → `git mv main.go types.go` → test → extract db.go → risky split → `go test && go build` acceptance.



## Externalized Sections (ADR-007 compression)
## Scenario: Split Monolithic Module (HIGH)
1. [PREP] Tests at entry points → baseline pass. 2. [SAFE] Extract `types.go` → tests pass. 3. [SAFE] Extract `db.go` → no import cycles. 4. [MODERATE] Extract `handlers.go` → update routes/imports. 5. [RISKY] Split `internal/db|api|types` → full build + integration. 6. [VERIFY] `go test ./... && go build ./...` → baseline perf.


## Failure Recovery
1. `git diff` → what changed. 2. Failure in refactored code → fix mapping. 3. Unrelated → `git stash` refactor, fix baseline, reapply. 4. Unfixable in 5 min → `git checkout -- .`, redo step. **Rollback**: each step maps to 1-2 files — `git checkout <file>`; `git revert` full branch for split/merge.


## Post-Refactor: mem_save
`title:"Refactored {module} — {extract|rename|split}" type:"architecture" content:"What: {X} from {Y} | Why: {reason} | Where: {paths} | Learned: {gotchas}"`
