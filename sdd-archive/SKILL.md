---
name: sdd-archive
description: >
  Sync delta specs to main specs, archive completed change.
  Trigger: Orchestrator launches you to archive after implementation + verification.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
ARCHIVE sub-agent. Merge delta specs → main specs (source of truth), move change folder to archive. Complete SDD cycle.

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read all artifacts (proposal, spec, design, tasks, verify-report). Record observation IDs. Save `sdd/{change}/archive-report`
- **openspec**: Follow `_shared/openspec-convention.md`. Perform merge + folder moves.
- **hybrid**: BOTH — engram report (with IDs) + filesystem merge + archive
- **none**: Closure summary only, no file ops

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Sync Delta Specs
engram: Skip (artifacts in Engram only, IDs recorded in report).
none: Skip.
openspec/hybrid: For each delta in `openspec/changes/{change}/specs/`:

**Main spec exists** (`openspec/specs/{domain}/spec.md`):
```
FOR EACH SECTION:
  ADDED → Append to main spec Requirements
  MODIFIED → Replace matching requirement (preserve others)
  REMOVED → Delete matching requirement
```
Match by name (e.g., `### Requirement: Session Expiration`). Maintain formatting.

**Main spec doesn't exist**: Delta IS full spec. Copy directly to `openspec/specs/{domain}/spec.md`.

### 3: Move to Archive
engram/none: Skip.
openspec/hybrid: Move folder with date prefix:
```
openspec/changes/{change}/ → openspec/changes/archive/YYYY-MM-DD-{change}/
```

### 4: Verify Archive
openspec/hybrid: ✅ Main specs updated · ✅ Folder moved · ✅ Archive contains all artifacts · ✅ Active dir cleaned
engram: ✅ All observation IDs recorded in report
none: Skip.

### 5: Persist Report (MANDATORY)
artifact: `archive-report` | topic_key: `sdd/{change}/archive-report` | type: `architecture`

### 6: Return Summary
```
## Change Archived
**Change**: {name}
**Archived to**: `openspec/changes/archive/{date}-{name}/` (openspec/hybrid) | Engram report (engram) | inline (none)

### Specs Synced
| Domain | Action | Details |
| {domain} | Created/Updated | {N added, M modified, K removed} |

### Archive Contents
- proposal.md ✅ · specs/ ✅ · design.md ✅ · tasks.md ✅ ({N}/{N} complete)

### Source of Truth Updated
- `openspec/specs/{domain}/spec.md`

### SDD Cycle Complete
Planned → implemented → verified → archived. Ready for next change.
```

## Rules
- NEVER archive with CRITICAL issues in verification report
- ALWAYS sync delta specs BEFORE moving to archive
- Merge: PRESERVE requirements not in delta
- ISO date format (YYYY-MM-DD) for archive prefix
- Destructive merge (large removals) → WARN orchestrator, ask confirmation
- Archive = AUDIT TRAIL — never delete/modify archived changes
- Create `openspec/changes/archive/` if not exists
- Return envelope per `_shared/sdd-phase-common.md` Section D.
