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

> **GATE**: Loaded via `skill()`? STOP. Delegate to `sdd-archive` sub-agent. Executor -> run directly.

## Purpose
Merge delta specs -> main specs, move change folder to archive, complete cycle.

## Inputs
Change name, mode (`engram|openspec|hybrid|none`), structured status per `sdd-status-contract.md`, optional override.

## Persistence (sdd-phase-common B+C)
| Mode | Action |
|---|---|
| engram | Read all artifacts + review topics; record obs IDs; save `sdd/{change}/archive-report` |
| openspec | `openspec-convention.md`; merge + archive |
| hybrid | Both |
| none | Closure summary only |

## Gates
- **Review Receipt**: require `reviewGate.result: allow`. Read transaction/ledger/receipt/gate-context. Missing/pending/malformed/scope-changed/invalidated/escalated -> block. No override.
- **Task Completion**: engram: read `sdd/{change}/tasks`; openspec/hybrid: `openspec/changes/{change}/tasks.md`. Unchecked `- [ ]` -> STOP, return `blocked`, report `sdd-apply` must rerun. Proceed only with orchestrator-approved reconciliation + apply-progress/verify-report proof. Record in report.
- **Strict**: CRITICAL verify-report ALWAYS blocks. Incomplete tasks block (unless stale+proof). Missing artifacts: report, continue only on explicit user partial archive.
- **Action Context**: workspace-planning -> STOP. allowedEditRoots -> stay inside.

## Steps
1. Load skills (Section A).
2. **Sync deltas** (openspec/hybrid; engram/none skip): FOR EACH delta section - ADDED append, MODIFIED replace matching, REMOVED delete (require Reason+Migration), RENAMED rename (old/new). Match by heading. Preserve unrelated. Main spec missing -> copy delta: `openspec/changes/{change}/specs/{domain}/spec.md -> openspec/specs/{domain}/spec.md`.
3. **Archive move** (openspec/hybrid): `openspec/changes/{change}/ -> openspec/changes/archive/YYYY-MM-DD-{change}/` (create archive/ if missing; `rules.archive` from config.yaml). engram/none skip.
4. **Verify**: specs updated, change moved, archive complete, no unchecked tasks, active dir clear (openspec); obs IDs recorded (engram).
5. **Persist (MANDATORY)**: Section C; artifact `archive-report`, key `sdd/{change}/archive-report`, type `architecture`.
6. **Return** (Section D): change, archived-to, specs synced table, contents checklist, "SDD Cycle Complete".

## Rules
- NEVER archive CRITICAL verify-report issues or stale unchecked tasks
- Sync deltas BEFORE archive move; preserve non-delta requirements
- ISO date prefix; WARN before destructive merges
- Archive = AUDIT TRAIL - never modify archived changes
- Create `openspec/changes/archive/` if missing
