# SDD Archive — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/sdd-archive/SKILL.md) for the core workflow.

---

## Examples (5)

### Example 1: Standard openspec Archive (single domain)
```bash
# Input: change="add-user-profile", mode="openspec"
# Delta: openspec/changes/add-user-profile/specs/user/spec.md (ADDED heading "## Profile Fields")
# Main: openspec/specs/user/spec.md exists with "## Auth Fields"
# Action: Merge — append "## Profile Fields" to main spec
# Archive: openspec/changes/archive/2026-08-16-add-user-profile/
```

### Example 2: Hybrid Mode (engram + openspec)
```bash
# Input: change="refactor-auth", mode="hybrid"
# Steps:
#   1. openspec: merge delta specs for auth, session domains
#   2. openspec: move change dir to archive/
#   3. engram: read artifacts, review topics, save observation
#   4. Persist archive-report to Engram with topic_key="sdd/refactor-auth/archive-report"
```

### Example 3: Main Spec Missing — Create New
```bash
# Input: change="add-notifications", mode="openspec"
# Delta: openspec/changes/add-notifications/specs/notification/spec.md
# Main: openspec/specs/notification/ does NOT exist
# Action: Copy entire delta → openspec/specs/notification/spec.md
# Archive: openspec/changes/archive/2026-08-16-add-notifications/
```

### Example 4: REMOVED Heading Requires Migration
```bash
# Delta: openspec/changes/remove-legacy-api/specs/api/spec.md
# Operation: REMOVED heading "## Legacy Endpoints"
# Main: openspec/specs/api/spec.md contains "## Legacy Endpoints"
# Requirement: Delta MUST include Migration section under REMOVED heading
#   "### Migration\nClients must migrate to /v2/* by 2026-12-31"
# Without Migration → block archive, return error
```

### Example 5: none Mode — Closure Only
```bash
# Input: change="spike-db-perf", mode="none"
# Action: Validate no unchecked tasks, reviewGate=allow
# Output: Closure summary only (no spec sync, no archive move, no Engram persist)
# Use case: Research spikes, throwaway prototypes
```

---

## Testing Patterns (3)

### Pattern 1: Spec Merge Integrity
```typescript
// Verify: ADDED headings appended, MODIFIED replaced, REMOVED deleted, RENAMED renamed
// Given: mainSpec = "## A\n## B", delta = { ops: [{type:"ADDED",heading:"## C"},{type:"MODIFIED",heading:"## B",content:"## B\nNew"}]}
// Expect: merged = "## A\n## B\nNew\n## C"
// Non-delta headings (## D in main) preserved unchanged
```

### Pattern 2: Archive Completeness Gate
```typescript
// Verify: All 4 artifacts present in archive dir + active dir cleared
// Artifacts: proposal.md, specs/, design.md, tasks.md (all checked)
// Gate: zero unchecked `- [ ]` in archived tasks.md
// Fail: any missing artifact OR unchecked task → blocked
```

### Pattern 3: Review Receipt Validation
```typescript
// Verify: reviewGate.result === "allow" + all context present
// Required fields: transaction.id, ledger.hash, receipt.signature, gate.context
// Failures: pending/malformed/scope-changed/invalidated/escalated → block
// Pass: allow + valid signatures + scope match
```

---

## Edge Cases (4)

| Edge Case | Behavior |
|---|---|
| **Concurrent archive of same change** | Second invocation detects archive dir exists → skip with "already archived" (idempotent) |
| **Delta spec references deleted heading** | REMOVED op on non-existent heading → warn, skip op, continue merge (non-blocking) |
| **Config `rules.archive` missing** | Default to `YYYY-MM-DD-{change}` pattern; create `archive/` dir; log warning |
| **Engram save fails (network)** | Retry 3x with backoff; on final failure → return `partial` status with Engram error, openspec archive still completed |

---

## Anti-Patterns (2)

### ❌ Anti-Pattern 1: Modifying Archived Changes
```bash
# WRONG: Editing files in openspec/changes/archive/2026-08-16-foo/
# Archive is IMMUTABLE audit trail. If spec needs update → new change cycle.
# CORRECT: Create new change "update-foo-spec", run full SDD cycle
```

### ❌ Anti-Pattern 2: Skipping Review Gate for "Trivial" Changes
```bash
# WRONG: Assuming typo fix / docs-only can bypass reviewGate
# Policy: reviewGate.result: allow is MANDATORY for ALL modes except none
# Even engram/hybrid/openspec with single-line delta → gate required
# CORRECT: Run review (can be lightweight), then archive
```