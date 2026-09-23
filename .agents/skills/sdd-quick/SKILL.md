---
name: sdd-quick
description: "3-phase fast SDD for LOW-risk - Propose->Apply->Verify. Use when 1-3 files, known codebase, no schema/auth/API changes."
triggers: "SDD quick, fast path, quick SDD, low risk SDD, simple change SDD"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2100
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
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "4 files but still quick" | Files touched >3 | Count files; 4+ → STOP, escalate to full SDD pipeline |
| "Schema change is tiny, quick covers it" | Any schema/auth/API diff | `git diff --stat` shows schema/auth/API → BLOCK, use full SDD |
| "Skip verify to ship faster" | No verify report artifact | Proposal + verify report must persist (rule: skip intermediates only) |

## Red Flags
- ANY When-to-Use criterion fails but quick continues → STOP, escalate to full SDD (rule: BLOCK if ANY fails)
- Commit without verify report → STOP, run Verify phase first

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
sdd · execution-mode · quality-gate · commit-crafter
## Reference
Phase 1-3 detail → docs/skills/sdd-quick/reference.md

