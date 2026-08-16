---
name: sdd-archive
description: "Archive completed SDD change by syncing delta specs. Trigger: orchestrator launches archive after implement+verify."
triggers: "SDD archive, archive SDD, close SDD, persist artifacts"
changelog: docs/ciclos/cycle28-20260815.md
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
proposal.md ✅ | specs/ ✅ | design.md ✅ | tasks.md ✅ ({N}/{N})
SDD Cycle Complete — Ready for next change.
```

- NEVER archive CRITICAL verify-report issues or stale unchecked tasks
- Sync delta specs BEFORE archive move; Preserve non-delta requirements
- ISO date prefix (YYYY-MM-DD); WARN before destructive merges
- Archive = AUDIT TRAIL — never modify archived changes; Create `openspec/changes/archive/` if missing

---

### Examples (4-5)

#### Example 1: Standard openspec Archive (single domain)
```bash
# Input: change="add-user-profile", mode="openspec"
# Delta: openspec/changes/add-user-profile/specs/user/spec.md (ADDED heading "## Profile Fields")
# Main: openspec/specs/user/spec.md exists with "## Auth Fields"
# Action: Merge — append "## Profile Fields" to main spec
# Archive: openspec/changes/archive/2026-08-16-add-user-profile/
```

#### Example 2: Hybrid Mode (engram + openspec)
```bash
# Input: change="refactor-auth", mode="hybrid"
# Steps:
#   1. openspec: merge delta specs for auth, session domains
#   2. openspec: move change dir to archive/
#   3. engram: read artifacts, review topics, save observation
#   4. Persist archive-report to Engram with topic_key="sdd/refactor-auth/archive-report"
```

#### Example 3: Main Spec Missing — Create New
```bash
# Input: change="add-notifications", mode="openspec"
# Delta: openspec/changes/add-notifications/specs/notification/spec.md
# Main: openspec/specs/notification/ does NOT exist
# Action: Copy entire delta → openspec/specs/notification/spec.md
# Archive: openspec/changes/archive/2026-08-16-add-notifications/
```

#### Example 4: REMOVED Heading Requires Migration
```bash
# Delta: openspec/changes/remove-legacy-api/specs/api/spec.md
# Operation: REMOVED heading "## Legacy Endpoints"
# Main: openspec/specs/api/spec.md contains "## Legacy Endpoints"
# Requirement: Delta MUST include Migration section under REMOVED heading
#   "### Migration\nClients must migrate to /v2/* by 2026-12-31"
# Without Migration → block archive, return error
```

#### Example 5: none Mode — Closure Only
```bash
# Input: change="spike-db-perf", mode="none"
# Action: Validate no unchecked tasks, reviewGate=allow
# Output: Closure summary only (no spec sync, no archive move, no Engram persist)
# Use case: Research spikes, throwaway prototypes
```

---

### Testing Patterns (3)

#### Pattern 1: Spec Merge Integrity
```typescript
// Verify: ADDED headings appended, MODIFIED replaced, REMOVED deleted, RENAMED renamed
// Given: mainSpec = "## A\n## B", delta = { ops: [{type:"ADDED",heading:"## C"},{type:"MODIFIED",heading:"## B",content:"## B\nNew"}]} 
// Expect: merged = "## A\n## B\nNew\n## C"
// Non-delta headings (## D in main) preserved unchanged
```

#### Pattern 2: Archive Completeness Gate
```typescript
// Verify: All 4 artifacts present in archive dir + active dir cleared
// Artifacts: proposal.md, specs/, design.md, tasks.md (all checked)
// Gate: zero unchecked `- [ ]` in archived tasks.md
// Fail: any missing artifact OR unchecked task → blocked
```

#### Pattern 3: Review Receipt Validation
```typescript
// Verify: reviewGate.result === "allow" + all context present
// Required fields: transaction.id, ledger.hash, receipt.signature, gate.context
// Failures: pending/malformed/scope-changed/invalidated/escalated → block
// Pass: allow + valid signatures + scope match
```

---

### Edge Cases (4)

| Edge Case | Behavior |
|---|---|
| **Concurrent archive of same change** | Second invocation detects archive dir exists → skip with "already archived" (idempotent) |
| **Delta spec references deleted heading** | REMOVED op on non-existent heading → warn, skip op, continue merge (non-blocking) |
| **Config `rules.archive` missing** | Default to `YYYY-MM-DD-{change}` pattern; create `archive/` dir; log warning |
| **Engram save fails (network)** | Retry 3x with backoff; on final failure → return `partial` status with Engram error, openspec archive still completed |

---

### Anti-Patterns (2)

#### ❌ Anti-Pattern 1: Modifying Archived Changes
```bash
# WRONG: Editing files in openspec/changes/archive/2026-08-16-foo/
# Archive is IMMUTABLE audit trail. If spec needs update → new change cycle.
# CORRECT: Create new change "update-foo-spec", run full SDD cycle
```

#### ❌ Anti-Pattern 2: Skipping Review Gate for "Trivial" Changes
```bash
# WRONG: Assuming typo fix / docs-only can bypass reviewGate
# Policy: reviewGate.result: allow is MANDATORY for ALL modes except none
# Even engram/hybrid/openspec with single-line delta → gate required
# CORRECT: Run review (can be lightweight), then archive
```

(End of file)