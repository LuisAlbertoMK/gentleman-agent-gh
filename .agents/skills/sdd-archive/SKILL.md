---
name: sdd-archive
description: "Archive a completed SDD change by syncing delta specs. Trigger: orchestrator launches archive after implementation and verification."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD archive, archive SDD, close SDD, persist artifacts, SDD archive"
  version: "2.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: Loaded via `skill()`? STOP. Delegate to `sdd-archive` sub-agent. Executors only.

Sub-agent? Gate doesn't apply. Execute directly.

## Purpose

Archive SDD change: merge delta specs → main specs, move change folder to archive, complete cycle. Artifacts in English (neutral Spanish if requested). Comments follow target context.

## Inputs

Change name, mode (`engram | openspec | hybrid | none`), structured status per `skills/_shared/sdd-status-contract.md`, optional override text.

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Sections B+C.

| Mode | Action |
|------|--------|
| **engram** | Read all artifacts + review topics. Record observation IDs. Save `sdd/{change-name}/archive-report`. |
| **openspec** | Follow `skills/_shared/openspec-convention.md`. Merge + archive moves. |
| **hybrid** | Both: Engram report + filesystem merge/move. |
| **none** | Closure summary only. No file ops. |

## Gates

- **Review Receipt**: Require `reviewGate.result: allow`. Read transaction, ledger, receipt, gate context. Missing/pending/malformed/`scope-changed`/`invalidated`/`escalated` → block. No override.
- **Task Completion**: Validate tasks artifact final state. **engram**: read `sdd/{change-name}/tasks`. **openspec/hybrid**: read `openspec/changes/{change-name}/tasks.md`. Unchecked `- [ ]` → STOP, return `blocked`, report `sdd-apply` must rerun. Proceed only with orchestrator-approved reconciliation + `apply-progress`/`verify-report` proof. Record reason in report.
- **Strict Policy**: CRITICAL verify-report issues ALWAYS block. Incomplete tasks block (unless stale+proof). Missing artifacts: report, continue only on explicit user partial archive with record.
- **Action Context**: `workspace-planning` → STOP. `allowedEditRoots` → stay inside roots.

## Steps

### 1. Load Skills → Section A from `skills/_shared/sdd-phase-common.md`

### 2. Sync Delta Specs

Gate must pass first. **engram/none**: skip. **openspec/hybrid**: for each delta in `openspec/changes/{change-name}/specs/`:

**Main spec exists** — merge:

```
FOR EACH delta section:
├── ADDED → Append Requirements
├── MODIFIED → Replace matching requirement
├── REMOVED → Delete (require Reason + Migration in delta)
└── RENAMED → Rename (explicit old/new names)
```

Match by heading name. Preserve unrelated requirements. Maintain hierarchy.

**Main spec missing** — copy delta directly:
`openspec/changes/{change-name}/specs/{domain}/spec.md → openspec/specs/{domain}/spec.md`

### 3. Move to Archive

**engram/none**: skip. **openspec/hybrid**: move with ISO date prefix:
`openspec/changes/{change-name}/ → openspec/changes/archive/YYYY-MM-DD-{change-name}/`

Create `archive/` if missing. Apply `rules.archive` from `openspec/config.yaml`.

### 4. Verify

- **openspec/hybrid**: specs updated, change moved, archive complete, no unchecked tasks, active dir clear.
- **engram**: observation IDs recorded, no unchecked tasks.
- **none**: skip.

### 5. Persist Archive Report (MANDATORY)

Follow Section C from `skills/_shared/sdd-phase-common.md`. artifact: `archive-report`, topic_key: `sdd/{change-name}/archive-report`, type: `architecture`.

### 6. Return Summary

Per Section D from `skills/_shared/sdd-phase-common.md`:

```markdown
## Change Archived
**Change**: {change-name}
**Archived to**: `openspec/changes/archive/YYYY-MM-DD-{change-name}/` | Engram | inline

### Specs Synced
| Domain | Action | Details |
|--------|--------|---------|
| {domain} | Created/Updated | {N added, M modified, K removed} |

### Contents
proposal.md ✅ | specs/ ✅ | design.md ✅ | tasks.md ✅ ({N}/{N})

### SDD Cycle Complete — Ready for next change.
```

## Rules

- NEVER archive CRITICAL verify-report issues or stale unchecked tasks
- Sync delta specs BEFORE archive move
- Preserve non-delta requirements
- ISO date prefix (YYYY-MM-DD)
- WARN before destructive merges (large removals)
- Archive is AUDIT TRAIL — never modify archived changes
- Create `openspec/changes/archive/` if missing

