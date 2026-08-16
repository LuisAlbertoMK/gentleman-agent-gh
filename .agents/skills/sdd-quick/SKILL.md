---
name: sdd-quick
description: "3-phase fast SDD for LOW-risk - Propose->Apply->Verify. Use when 1-3 files, known codebase, no schema/auth/API changes."
triggers: "SDD quick, fast path, quick SDD, low risk SDD, simple change SDD"
changelog: docs/ciclos/cycle28-20260815.md
---

# SDD Quick — 3-Phase Fast Path

```
[Propose] → [Apply] ↔ [Verify]
```

## When to Use

| Criterion | Required |
|-----------|----------|
| Files touched | ≤3 |
| Risk zone | GREEN or LOW |
| Codebase familiarity | Known (3x+ edits) |
| Schema/auth/API changes | None |
| New dependencies | None |

**If ANY criterion fails → use full SDD pipeline.**

## Flow

### Phase 1: Propose (simplified)

Load `{file:sdd/phases/02-propose.md}`. Execute with these relaxations:

- Skip `Capabilities` section (not creating new specs)
- Skip `Affected Areas` detailed table (≤3 files, list them inline)
- Keep: Intent, Scope (In/Out), Risks, Rollback, Success Criteria
- Budget: **<200 words** (vs 450 in full SDD)

**Output:** Proposal markdown → persist via `{file:sdd/references/sdd-phase-common.md}` §C

### Phase 2: Apply (standard)

Load `{file:sdd/phases/06-apply.md}`. Execute normally with:

- No tasks breakdown needed (work is obvious from proposal)
- Standard TDD if risky logic, otherwise code + test
- No workload check needed (≤3 files, <400 lines by definition)
- Persist progress via §C

### Phase 3: Verify (essential only)

Load `{file:sdd/phases/07-verify.md}`. Execute with essential gates only:

| Gate | Check |
|------|-------|
| Tests pass | `pytest` / project test runner |
| Build OK | `npm run build` / project build |
| No regressions | Existing tests still pass |

**Skip:** Design coherence, spec scenario mapping, coverage analysis, assertion quality audit.

**Output:** Verify report → persist via §C

## Return Envelope

```
sdd-quick | {change-name}
Phases: Propose→Apply→Verify
Files:{N} | Tests:{P/FAIL} | Build:{P/FAIL}
Status:{Ready|Blocked}
Time:{actual time}
```

## Rules

- **BLOCK if ANY criterion fails** → escalate to full SDD
- No Archive phase → git commit is the archive
- No Spec phase → proposal is the spec
- No Design phase → code patterns from codebase are the design
- Persist proposal + verify report only (skip intermediate artifacts)

## Refs
sdd · execution-mode · quality-gate · commit-crafter

## Anti-Patterns
Using sdd-quick for HIGH-risk changes · Skipping verify · No rollback plan in proposal · Ignoring test failures
