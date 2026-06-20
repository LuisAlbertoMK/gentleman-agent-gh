---
name: review-pipeline
description: "Skill stacking: quality-gate → 4R code-review → commit-crafter. Gate-protected pipeline."
triggers: "review pipeline, pipeline, full review, preparar commit, ready to ship, listo para commit"
license: Apache-2.0
metadata:
  tags:
    - engineering
    - pipeline
    - review
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.0->1.1: slim to <3KB — phase details/output extracted to references/"
  dependencies:
    - quality-gate
    - code-review-agent
    - commit-crafter
---

Skill stacking pipeline: **quality-gate → 4R code review → commit craft**. Each phase feeds the next. Fail = STOP + report.

## When
- "ready to ship" / "listo para commit" / "full review" / before PR or complex push

## Pipeline
```
[Phase 0: Load Engram profile] → [Phase 1: quality-gate] ─fail→ STOP
                                       │ pass
                                       ▼
                                  [Phase 2a: Zone check]
                                  ├── ROJA ──→ [Phase 2b: JD dual review] ─fail→ STOP
                                  ├── AMARILLA → [Phase 2c: 4R review]
                                  └── VERDE ──→ skip review
                                       │ pass (all ≥6)
                                       ▼
                                  [Phase 3: commit craft] → ✅ message
```

## Phase Details → `references/phase-details.md`
- P0: Load `mem_search("review-profile/{project}")` — trend awareness + focus R
- P1: quality-gate — tests + secrets + PSSA. Gate **authority**: ALWAYS blocks.
- P2a: Zone check — match changed files vs `review-rules.jsonc zones`. ROJA→JD, AMARILLA→4R, VERDE→skip.
- P2b: JD dual review (ROJA) — load `judgment-day` orchestrator, 2 profile-scoped `code-review-agent` instances.
- P2c: 4R code-review (AMARILLA) — ≥6 pass, 4-5 overrideable, <4 BLOCKED. Save profile after.
- P3: commit-crafter — scope injected from 4R findings (`fix`/`refactor` by R).

## Output → `references/output-format.md`
Pipeline summary with per-phase result + commit message.

## Rules
1. **Gate authority**: Phase 1 ALWAYS blocks. No override.
2. **Review override**: Phase 2 (4-5) user-confirmable with `review-override` tag. <4 impossible.
3. **Evidence chain**: Each phase output consumed by next. Never skip.
4. **Scope injection**: Phase 3 uses 4R findings for commit scope (e.g., `fix(db)` if Reliability flagged).
5. **Max runtime**: >3 tool calls per phase without progress → ask user.

## Anti-patterns
| ❌ | ✅ |
|---|-----|
| Parallel phases (race conditions) | Sequential, each feeding next |
| Ignoring gate failure | Block at Phase 1 until resolved |
| Generic commit ignoring review | Scope/type from 4R findings |
| Override 4R <4 w/o confirmation | Hard block — ask user explicitly |
