# Feature: main-remediation-4a6c67a9

## Intent

Return `main` to green after the direct push `4a6c67a9` added 7 skill
directories without regenerating any derived artifact, and re-pin the benchmark
baseline so the two benchmark regressions it created are accepted explicitly
instead of silently.

## Context (evidence)

`origin/main` = `4a6c67a9` "feat(sync): Ford-MYCO en chain + paridad 44 agentes
+ fix fallback use-gentleman" (LuisAlbertoMK, direct push, no PR). It added 7
skill dirs: `cognitive-doc-design`, `gentle-ai-bench`,
`gentle-ai-collab-perfect`, `issue-root-resolution`, `rdd-advisory-transport`,
`rdd-defect-workflow`, `systemic-issue-triage`.

Quality Gate run `36253270401` (push to main) = **failure**, two jobs red:

- job `tests` — 1807 pass / **7 fail**
- job `tests-v1` — 484 pass / **1 fail**

Benchmark, measured with the gate's own semantics (`Get-Content -Raw` char
count, `_shared` excluded, `-gt 3072`) in a detached worktree of `4a6c67a9`:

| Metric | Baseline | `dba368a6` | `4a6c67a9` |
|---|---|---|---|
| `TotalSkills` | 96 | 96 | **103** |
| `TotalSkillBytes` | 255094 | 262405 | **310660** |
| `SkillsOver3kb` | 7 | 9 | **15** |
| `AGENTS.md` | 4908 | 2731 | 2704 |

`TotalSkillBytes` limit is `baseline * 1.05 = 267848` → exceeded by **42812**.

## Decision

The user explicitly approved: fix the 8 Pester failures **and** re-pin the
benchmark baseline, accepting the growth.

Arithmetic that forces the re-pin: to get `TotalSkillBytes` back under 267848
without re-pinning, the 6 new oversized skills would have to total ~2946 chars
combined (~491 each). There is no compression that closes that gap. The
alternative to re-pinning is effectively deleting the new skills, which is not
this work unit's call.

## Failure inventory and fix map

| # | Failure | Root cause | Fix |
|---|---|---|---|
| 1 | cross-ref T1 `INDEX says 96, has 103` | `SKILLS-INDEX.md` header count stale | header `all 96 skills` -> `all 103 skills` |
| 2 | cross-ref T2 stale entries | same header count | same edit |
| 3 | dashboard counts `expected 97, got 104` | hardcoded literal in test | `97` -> `104` |
| 4 | dashboard overBudget `-le 8, got 14` | policy bound in test | `8` -> `14` |
| 5 | README count drift `expected 103, got 96` | README literals stale | `96` -> `103` (x2) |
| 6 | E2E canonical count filesystem vs INDEX | `.project.json` + INDEX stale | `.project.json` `skills` -> `103` |
| 7 | E2E depth `cognitive-doc-design` | no depth heading, no `docs/skills/` ref | add a compact depth section |
| 8 | golden `registry-build.golden.json` `skill_count 97 vs 104` | golden not regenerated | re-run `build-skill-registry.ps1` + normalization |
| 9 | benchmark 2 regressions | baseline not re-pinned | `-SetBaseline` (accepted by user) |

`scripts/tests/skill-coverage-e2e.Tests.ps1:55-58` accepts either a depth
heading (`Examples|Testing Patterns|Anti-Patterns|Anti-Rationalization|Edge
Cases|Quality Gates`) or the literal string `docs/skills/` (ADR-007 escape).
`docs/skills/cognitive-doc-design/` does not exist, so the escape would be a
dangling pointer: add a real depth section instead.

## Acceptance criteria

1. The 8 previously failing tests pass locally.
2. `benchmark-core.ps1 -Gate` exits 0 with `CI=true` (the CI condition).
3. Re-pinned baseline reflects the post-change tree.
4. `cognitive-doc-design/SKILL.md` stays `<= 3072` chars (it is 2497 now).
5. No test/golden/contract regression outside the 8 repaired.
6. Tier 2 RDD receipt `.rdd/rdd-receipt-029.json` valid against schema.
7. Branch + PR; `main` is never touched.

## Write scope (allowed edit surfaces)

- `SKILLS-INDEX.md`
- `.project.json`
- `README.md`
- `testdata/golden/registry-build.golden.json`
- `scripts/tests/generate-dashboard-data.Tests.ps1`
- `.agents/skills/cognitive-doc-design/SKILL.md`
- `benchmark-baseline.json`
- `odd/tasks/main-remediation-4a6c67a9.md`
- `.rdd/rdd-receipt-029.json`

## Out of scope (reported, not fixed)

- `SKILLS-INDEX-FULL.md` is stale (`92 skills`, generated 2026-08-28) and no
  test or script references it. Cosmetic drift, needs its own decision.
- The `Benchmark report` step in `main` still points at the archived
  `scripts/benchmark.ps1`; PR #55 owns that fix. Until #55 merges, this branch's
  own Quality Gate will still fail that step.
- The 17 missing global skill junctions in `~/.config/opencode/skills`
  (local machine state; the predicate is skipped in CI).

## Tasks

- [ ] T1 — Branch `fix/main-skill-drift-4a6c67a9` off `origin/main`
- [ ] T2 — Fix the 3 count literals (SKILLS-INDEX, .project.json, README)
- [ ] T3 — Update the 2 dashboard test literals (count + overBudget bound)
- [ ] T4 — Add the depth section to `cognitive-doc-design`
- [ ] T5 — Regenerate `registry-build.golden.json`
- [ ] T6 — Re-pin `benchmark-baseline.json`
- [ ] T7 — Verify the 8 tests + CI-condition gate
- [ ] T8 — Work-unit commit(s) + Tier 2 receipt 029
- [ ] T9 — Push branch and open PR to `main`

## Evidence log

(commit identities are recorded here as each task closes)
