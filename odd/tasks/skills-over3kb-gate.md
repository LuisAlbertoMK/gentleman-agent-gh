# Feature: skills-over3kb-gate

## Intent

Return the pinned benchmark gate to green on `main` by removing the only live
regression: `SkillsOver3kb` grew from 7 (pinned baseline) to 9.

## Context (evidence)

- `main` Quality Gate is red: run `36176062646`, job `tests` / step `Benchmark report`.
- Root cause chain:
  1. `5c503d68` archived `scripts/benchmark.ps1` -> `scripts/archive/benchmark.ps1`,
     leaving `.github/workflows/quality-gate.yml:324` with a dead reference.
  2. PR #55 (`fix/quality-gate-benchmark-ref`) re-points that step to
     `scripts/benchmark-core.ps1` but is still UNSTABLE, because re-pointing
     surfaces the regression the dead reference was masking.
  3. `scripts/benchmark-core.ps1:205` fails the gate on
     `SkillsOver3kb > pinned baseline`.
- Measurement must use the gate's own semantics:
  `Get-Content -Raw` char count, `_shared` excluded, threshold `-gt 3072`.
  `wc -c` overestimates (BOM / multibyte) and is NOT valid evidence.
- Current state (measured): `TOTAL=96`, `OVER3072=9`, baseline `SkillsOver3kb=7`.
- Other gate predicates do NOT fire:
  `TotalSkillBytes=262405` vs 5% limit `267848` (margin 5443);
  `AgentsMdBytes=2731` vs baseline 4908 (gate only checks growth);
  `GlobalJunctionsOk` is skipped under `CI`/`GITHUB_ACTIONS`
  (`scripts/benchmark-core.ps1:206`).

## Decision

Do NOT re-pin the baseline (that legitimizes growth and erases the signal).
Trim two skills back under the 3072-char ceiling using redundancy-only prose
trims, preserving every functional rule and every structural heading.

## Targets

| Skill | Chars now | Action | Chars after |
|---|---|---|---|
| `container-security` | 3073 | drop redundant rationale clause + tighten a parenthetical | ~3016 |
| `security-scanner` | 3197 | drop fully-duplicated `## Anti-Patterns` section + drop a duplicated `--include` | ~3012 |

Redundancy proof for `security-scanner` `## Anti-Patterns`: each of its six items
is already encoded in `## Rules` (1-5), `## Red Flags`, or
`## Anti-Rationalization`. The skill keeps `## Anti-Rationalization`, which
satisfies `scripts/tests/skill-coverage-e2e.Tests.ps1:52` (depth-section rule).

## Acceptance criteria

1. `OVER3072 == 7` measured with the gate's own semantics.
2. `container-security` and `security-scanner` each `<= 3072` chars.
3. Headings preserved: frontmatter `---`, `## When to Use`, `## Rules`.
4. `scripts/benchmark-core.ps1 -Snapshot -Gate` exits 0.
5. `scripts/test-token-budget-regression.ps1` still passes (one-directional check).
6. No test/golden/contract regression (registry goldens carry no content hash).
7. Tier 2 RDD receipt `.rdd/rdd-receipt-028.json` valid against schema.
8. PR to `main`; `main` itself is never touched.

## Tasks

- [ ] T1 — Trim `container-security/SKILL.md` to <= 3072 chars
- [ ] T2 — Trim `security-scanner/SKILL.md` to <= 3072 chars
- [ ] T3 — Verify `OVER3072 == 7` with the exact gate computation
- [ ] T4 — Run `benchmark-core.ps1 -Snapshot -Gate` (expect exit 0)
- [ ] T5 — Run token-budget + skill-coverage + contract suites (no regression)
- [ ] T6 — Work-unit commit(s) + Tier 2 receipt 028
- [ ] T7 — Push branch and open PR to `main`

## Write scope

- `.agents/skills/container-security/SKILL.md`
- `.agents/skills/security-scanner/SKILL.md`
- `odd/tasks/skills-over3kb-gate.md`
- `.rdd/rdd-receipt-028.json`

## Evidence log

(commit identities are recorded here as each task closes)
