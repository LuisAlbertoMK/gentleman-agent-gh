---
name: sdd-archive
description: "Archive completed SDD change by syncing delta specs. Trigger: orchestrator launches archive after implement+verify."
triggers: "SDD archive, archive SDD, close SDD, persist artifacts"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1992
---
Mode per `sdd-status-contract.md`:
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
1. Load Skills → 2. Sync Delta Specs (gate first; ADDED→append, MODIFIED→replace, REMOVED→delete w/ Reason+Migration, RENAMED→rename; missing main→copy to `openspec/specs/{domain}/spec.md`) → 3. Move to Archive → `archive/YYYY-MM-DD-{change}/` + `rules.archive` → 4. Verify (specs updated, change moved, no unchecked tasks) → 5. Persist (artifact `archive-report`, topic_key `sdd/{change}/archive-report`) → 6. Return Summary.
- NEVER archive CRITICAL verify-report issues or stale unchecked tasks
- Sync delta specs BEFORE archive move; Preserve non-delta requirements
- ISO date prefix; WARN before destructive merges
- Archive = AUDIT TRAIL — never modify archived changes; create `openspec/changes/archive/` if missing
## Reference
Return summary template + extended details → docs/skills/sdd-archive/reference.md