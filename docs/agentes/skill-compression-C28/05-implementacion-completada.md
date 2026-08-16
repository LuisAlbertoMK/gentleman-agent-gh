# Skill Compression — Completion Report (Cycle 28 backlog #5)

**Date**: 2026-08-15
**Task**: Compress skills >3KB (SE dim 8.0 → target ≥9.5, achieved 10.0)

## Summary

| Skill | Before (bytes) | After (bytes) | Reduction | Technique |
|---|---|---|---|---|
| `.agents/skills/lean-context/SKILL.md` | 3225 | 2658 | -17.6% (-567B) | Merged redundant `WHEN`/`ESCALATION` sections into single `LEVEL SELECT` + escalation line; compressed `When to Use` prose; tightened USER RESPONSE POLICY; removed LIVE EXAMPLE tutorial table (prose → rules only) |
| `.agents/skills/mini-orchestrator/SKILL.md` | 3804 | 3063 | -19.5% (-741B) | 3-pass Karpathy cut loop: tightened workflow prose, guardrail purpose cells, approval tiers, refs (bullets → inline), anti-patterns (bullets → inline), implementation purpose cells |

**3rd skill**: None existed. Exhaustive search (workspace-wide `SKILL.md` >3072B incl. global `~/.config/opencode/skills`, junction check, git blob sizes at HEAD) found exactly 2 skills >3KB. The task's "3rd" was already compressed in prior cycles: git log shows `270290c0` (automejora-analyzer fix, now 1888B) and `ae9ce945` (9-skill Karpathy T2 pass). `.agents/skills` are real files, NOT junctions (verified `LinkType` empty).

## Verification

| Gate | Result |
|---|---|
| `scripts/score-auto.ps1 -Json` → SE dim | **10.0** (was 8.0; target ≥9.5) ✓ |
| SE evidence | `T:89 >3:0 >5:0 avg:2.5KB` ✓ |
| Overall score | **9.3** (was 8.7, trend up) ✓ |
| `scripts/benchmark.ps1` → SkillsOver3kb | **0** (was 2) ✓ |
| Skills >3072B (raw scan) | **0** ✓ |
| `scripts/cross-ref-check.ps1` | `allClean: true, brokenCrossRefs: 0` ✓ |
| Frontmatter preservation | **byte-exact** vs HEAD for both files ✓ |
| File encoding | LF-only, no BOM (unchanged from original) ✓ |
| UTF-8 multibyte chars (—, →, ≤, ×) | preserved intact ✓ |

## Scope notes

- **`.project.json` modified** by `score-auto.ps1` (normal scorer persistence — stale 08-14 snapshot refreshed with today's run).
- **`scripts/delegation-registry.ps1`** MD5→SHA256 change and `docs/agentes/security-C28/` are **pre-existing** (other session's security work) — NOT touched by this task.
- **Pre-existing test failure** (not caused by this task): `skill-frontmatter.Tests.ps1` "All skills have 'name' field" fails for 5 skills (automejora-analyzer, sdd-apply, sdd-archive, sdd-propose, sdd-tasks) whose frontmatter starts with `description:` instead of `name:`. Reproduced at HEAD with my files stashed. Out of scope.
- **Out of scope for SE=10.0 ceiling**: commands/ (cmdO3=3: sdd-continue 4330B, sdd-archive 3447B, sdd-status 3507B) and prompts/ (prO3=3: gentleman-vMK 5088B, _core-behavior-gp 3445B, gentleman-orchestrator 3128B) still carry H-019 overweight penalty potential. Skills-only work reached SE 10.0; these are separate dimensions' concerns.

## Quality control

- All functional instructions preserved: workflows, guardrail caps, approval tiers, escalation triggers, budget gates, level tables, anti-patterns, refs. Only tutorial prose/examples compressed into actionable rules.
- No merge/junction edits performed (files are standalone).