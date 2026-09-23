---
name: odd
description: "Organic Driven Development — slice features into ≤400L conventional-commit units with review gates. Use sdd-quick for registry/spec concerns."
triggers: "organic driven development, one day delivery, odd, slice plan, daily delivery, commit slicing, review per slice"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2850
---
## Gate: SMALL vs SUBSTANTIAL
| Criteria | SMALL (direct) | SUBSTANTIAL (task plan) |
|----------|---------------|------------------------|
| Lines | ≤50L code; ≤150L docs-only 1-file | >50L or unknown |
| Files | 1 file | >1 file |
| Schema/auth/API | None | Any |
| External deps | None | New deps |
| Tier | 0 (known) | 1+ |
| Commits forecast | ≤2 | >2 |

**All criteria must pass for SMALL.** Otherwise → create `odd/tasks/<feature>.md`.
## Slice Plan
1 slice = 1 conventional commit · ≤400L code (≤800L docs-only) per slice · tests in same commit as behavior.
```
Slice 1: <scope> (<est. lines>) — <outcome>
Slice 2: ...
```
## Presets (ref: opencode-model-router)
| Preset | Phase | Agent | Fallback |
|--------|-------|-------|----------|
| P1 | Propose | analysis agent | vMK |
| P2 | Slice plan | implementation agent | quick |
| P3 | Implement | implementation agent | codex |
| P4 | Verify | quality agent | deep |
| P5 | Review | review agent | vMK |
## Workflow (ODD Cycle)
1. **Gate** — Evaluate SMALL vs SUBSTANTIAL criteria above.
2. **Slice** — Break into ≤400L units. Each slice gets `odd/tasks/<feature>.md` entry.
3. **Implement** — One preset per phase. Commit per slice conventional.
4. **Verify** — Per-slice tests pass + repo works after each commit.
5. **Review** — Log review per slice in task plan Review Log.
## Rollback
Each slice commits independently. Revert slice N without touching N-1 or N+1.
## Anti-Patterns & Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "One big commit is fine" | >400L or >1 logical unit in one commit | Slice Plan: 1 commit = 1 deliverable outcome |
| "Skip review for small" | No review log entry | Workflow step 5 mandatory per slice |
| "Reuse SDD registry" | Confusing ODD slices with SDD spec tracking | ODD=slices+review, SDD=qué/cuándo registry |
## Red Flags
- Slice >400L → split further
- No test in commit with behavior → STOP, add test
- Preset skip without fallback → route through opencode-model-router
## Verification
- cross-ref-check.ps1 → SKILL.md OK
- Each commit: `git diff --stat` ≤400L
## Refs
Cross-Refs: work-unit-commits | sdd-quick | commit-crafter | opencode-model-router
## Reference
Template + examples + presets detail → {file:odd/reference.md}
