---
description: "Archive completed SDD change by syncing delta specs. Trigger: orchestrator launches archive after implement+verify."
triggers: "SDD archive, archive SDD, close SDD, persist artifacts"
---

> **ORCHESTRATOR GATE**: `skill()` → STOP. Delegate to `sdd-archive` sub-agent.

Change name, mode (`engram|openspec|hybrid|none`), status per `sdd-status-contract.md`, optional override.

| Mode | Action |
|---|---|
| **engram** | Read artifacts + review topics; save `sdd/{change}/archive-report` |
| **openspec** | Follow `openspec-convention.md`; merge + archive |
| **hybrid** | Both |
| **none** | Closure summary only |

- **Review Receipt**: Require `reviewGate.result: allow`. Read transaction, ledger, receipt, gate context. Missing/pending/malformed/scope-changed/invalidated/escalated → block.
- **Task Completion**: Validate final state. Unchecked `- [ ]` → STOP, return `blocked`. Proceed only with orchestrator-approved reconciliation + proof.
- **Strict Policy**: CRITICAL verify-report issues ALWAYS block. Incomplete tasks block (unless stale+proof). Missing artifacts: report, continue only on explicit user partial archive.
- **Action Context**: `workspace-planning` → STOP. `allowedEditRoots` → stay inside.

1. **Load Skills** → §A of `sdd-phase-common.md`
2. **Sync Delta Specs** (gate must pass first)
   - engram/none: skip
   - openspec/hybrid: for each delta in `openspec/changes/{change}/specs/`:
     - **Main exists** — merge: ADDED→append, MODIFIED→replace, REMOVED→delete (need Reason+Migration), RENAMED→rename. Match by heading. Preserve unrelated.
     - **Main missing** — copy delta to `openspec/specs/{domain}/spec.md`
3. **Move to Archive** (engram/none: skip; openspec/hybrid):
   `openspec/changes/{change}/` → `openspec/changes/archive/YYYY-MM-DD-{change}/`
   Create `archive/` if missing. Apply `rules.archive` from `openspec/config.yaml`.
4. **Verify**
   - openspec/hybrid: specs updated, change moved, archive complete, no unchecked tasks, active dir clear
   - engram: observation IDs recorded, no unchecked tasks
   - none: skip
5. **Persist Archive Report** — §C of `sdd-phase-common.md`: artifact `archive-report`, topic_key `sdd/{change}/archive-report`, type `architecture`
6. **Return Summary**
```markdown

**Change**: {change-name}
**Archived to**: `openspec/changes/archive/YYYY-MM-DD-{change}/` | Engram | inline
### Specs Synced
| Domain | Action | Details |
|---|---|---|
| {domain} | Created/Updated | {N added, M modified, K removed} |
### Contents
proposal.md �� | specs/ �� | design.md �� | tasks.md �� ({N}/{N})
SDD Cycle Complete — Ready for next change.
```

- NEVER archive CRITICAL verify-report issues or stale unchecked tasks
- Sync delta specs BEFORE archive move; Preserve non-delta requirements
- ISO date prefix (YYYY-MM-DD); WARN before destructive merges
- Archive = AUDIT TRAIL — never modify archived changes; Create `openspec/changes/archive/` if missing
