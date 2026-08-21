---
name: sdd-quick
description: "3-phase fast SDD for LOW-risk - Propose->Apply->Verify. Use when 1-3 files, known codebase, no schema/auth/API changes."
triggers: "SDD quick, fast path, quick SDD, low risk SDD, simple change SDD"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1199
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
Phase detail (relaxations, gates, skips) → reference. All phases persist via `{file:sdd/references/sdd-phase-common.md}` §C.
## Rules
- **BLOCK if ANY criterion fails** → escalate to full SDD
- No Archive phase → git commit is the archive
- No Spec phase → proposal is the spec
- No Design phase → code patterns from codebase are the design
- Persist proposal + verify report only (skip intermediate artifacts)
## Refs
sdd · execution-mode · quality-gate · commit-crafter
## Reference
Phase 1-3 detail → docs/skills/sdd-quick/reference.md