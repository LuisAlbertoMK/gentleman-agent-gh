---
name: chained-pr
description: "Split oversized changes into chained PRs that protect review focus."
triggers: "chained PR, stacked PR, sequential branches, PR chain, stacked branches, PR stack, oversized PR, 400 lines, review slices"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2995
---

## When to Use

Load this skill when a planned PR may exceed **400 changed lines**, SDD forecasts `400-line budget risk: High` or `Chained PRs recommended: Yes`, or the user asks for chained/stacked PRs, review slices, or reviewer-load control.

## Rules

- Split PRs over **400 changed lines** unless a maintainer explicitly accepts `size:exception`.
- Keep each PR reviewable in about **≤60 minutes**.
- Use one deliverable work unit per PR; keep tests/docs with the unit they verify.
- State start, end, prior dependencies, follow-up work, and out-of-scope items in every chained PR.
- Every child PR must include a dependency diagram marking the current PR with `📍`.
- In Feature Branch Chain, create a draft/no-merge tracker PR; child PR #1 targets the tracker branch, later children target the immediate parent branch.
- Treat polluted diffs as base bugs: retarget or rebase until only the current work unit appears.
- Do not mix chain strategies after the user chooses one.

## Execution Steps

1. Estimate changed lines and identify independent work units.
2. Ask for a chain strategy when none is cached and the budget is exceeded.
3. Create branches/PRs using the chosen strategy only.
4. Add Chain Context to each PR without replacing the repo PR template.
5. Verify each PR independently: CI/tests/docs/manual checks, rollback scope, and clean diff.
6. Keep tracker PR draft/no-merge until all child PRs are reviewed and integrated.

## References

- [references/chaining-details.md](references/chaining-details.md) — strategy diagrams, PR body section, branch commands, and reviewer guidance.

---
---

docs/skills/chained-pr/reference.md
---
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "chain sin base común" | Chain sin tracker draft o mezclando estrategias | Verificar Execution Steps: tracker draft/no-merge + child #1→tracker + resto→parent + no mix strategies |
| "PR gigante disfrazado de chained" | PR >400 líneas sin split o sin diagrama dependencia 📍 | Verificar Rules: ≤400 líneas + Chain Context + diagrama dependencia con 📍 por PR + ≤60 min review |
| "polluted diff sin rebase" | Diff con cambios no del work unit actual | Verificar base bug: retarget/rebase hasta diff limpio + Verify each PR independiente CI/tests/docs/rollback |


## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: branch-pr | work-unit-commits | commit-crafter

