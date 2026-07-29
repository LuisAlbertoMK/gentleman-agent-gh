# SDD — Strategic Design Document

SDD is the spec-driven development workflow for gentleman-agent-gh. Every significant change flows through a 9-phase pipeline that produces persistent, reviewable artifacts.

## Pipeline

```
Init → Explore → Propose → Design → Spec → Tasks → Apply ↔ Verify → Archive
```

| Phase | What it produces | Stored in |
|-------|-----------------|-----------|
| Init | Project context, config | `sdd-config.yaml` |
| Explore | Entry points, options, recommendation | Engram + `docs/sdd/explorations/` |
| Propose | Scope, risks, rollback plan | Engram + `docs/sdd/proposals/` |
| Design | Architecture, data flow, file plan | Engram + `docs/sdd/designs/` |
| Spec | G/W/T specs (RFC 2119) | Engram + `docs/sdd/specs/{change-id}/` |
| Tasks | Phased implementation tasks | Engram + `docs/sdd/tasks/` |
| Apply | Code implementation | Filesystem (git-tracked) |
| Verify | Test results, compliance | Engram + `docs/sdd/reports/` |
| Archive | Registry entry, rollback snapshot | `docs/sdd/registry.yaml` + `docs/sdd/archive/{change-id}/` |

## Permission Model

[`permissions.md`](permissions.md) documents the complete permission model:
- Mode system (auto/semi/manual) and routing behavior
- Delegation permission rules (which agents can delegate to which)
- Write-scope enforcement via `validate-write-scope.ps1`
- Task complexity → Agent routing (T1-T4)
- Agent permission boundaries from `opencode.json`

## Registry

[`registry.yaml`](registry.yaml) is the source of truth for all changes. Every archived change registers there with:
- Change ID, title, and description
- Domains affected
- Files changed
- Status and timestamps

## Fast Path

For LOW-risk changes (1-3 files, known codebase, no schema/auth/API changes): use **SDD-Quick** — 3 phases instead of 9. See `.agents/skills/sdd-quick/SKILL.md`.

## Conventions

- Change IDs: `YYYY-MM-DD-{short-descriptive-slug}`
- Spec requirements use RFC 2119 (MUST/SHOULD/MAY)
- Every requirement needs ≥1 GIVEN/WHEN/THEN scenario
- Specs use `ADDED | MODIFIED | REMOVED` delta format
- Filesystem AND Engram persistence (hybrid mode)
