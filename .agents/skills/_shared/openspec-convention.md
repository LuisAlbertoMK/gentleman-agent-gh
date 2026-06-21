# OpenSpec File Convention

## Directory Structure
```
openspec/{config.yaml, specs/{domain}/spec.md, changes/{change-name}/{state.yaml, exploration.md, proposal.md, specs/{domain}/spec.md, design.md, tasks.md, verify-report.md}, changes/archive/YYYY-MM-DD-{change-name}/}
```

## Artifact Ownership
| Phase | Creates/Updates | Path |
|-------|----------------|------|
| orchestrator | state.yaml | `changes/{change}/state.yaml` |
| init | bootstrap | `config.yaml`, `specs/`, `changes/`, `changes/archive/` |
| explore | exploration.md (opt) | `changes/{change}/exploration.md` |
| propose | proposal.md | `changes/{change}/proposal.md` |
| spec | specs/{domain}/spec.md | `changes/{change}/specs/{domain}/spec.md` |
| design | design.md | `changes/{change}/design.md` |
| tasks | tasks.md | `changes/{change}/tasks.md` |
| apply | updates tasks.md | `changes/{change}/tasks.md` (marks `[x]`) |
| verify | verify-report.md | `changes/{change}/verify-report.md` |
| archive | moves + merges | `changes/{change}/` → `changes/archive/YYYY-MM-DD-{change-name}/` + updates `specs/{domain}/spec.md` |

## Rules
- Create change dir first | Read+update, never blind overwrite | Existing artifacts = continuation
- Config: `openspec/config.yaml` with per-phase rules (proposal→rollback, specs→GWT/RFC2119, design→diagrams, tasks→hierarchical, apply→patterns/tdd/test_command, verify→test_build_coverage, archive→warn destructive)

## Archive
`changes/{change}/` → `changes/archive/YYYY-MM-DD-{change-name}/`. Audit trail — never delete/modify.
