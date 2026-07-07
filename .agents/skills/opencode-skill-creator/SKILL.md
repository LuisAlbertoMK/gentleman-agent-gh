---
name: opencode-skill-creator
description: Create, test, evaluate, optimize, and package OpenCode skills with the opencode-skill-creator plugin. Use when users explicitly mention opencode-skill-creator, OpenCode Skill Creator, creating an OpenCode skill, editing an OpenCode SKILL.md, running skill evals, benchmarking skill performance, or optimizing an OpenCode skill description. Do not use for generic Claude Code or Superpowers skill creation unless the user asks to port that workflow to OpenCode.
---

# OpenCode Skill Creator

Create & iteratively improve OpenCode skills. Core loop: capture intent → write → eval → iterate → install.

## Workflow

1. **Intake** (mandatory) — 3-5 targeted questions. See `references/intake.md`.
2. **Write SKILL.md** — Stage in `%TEMP%\opencode-skills\<name>\`. Bundled resources in `scripts/`, `references/`. See `references/skill-writing.md`.
3. **Eval** — Run with-skill + baseline in same turn via Task tool. Draft assertions during runs. Launch viewer via `skill_serve_review`. See `references/eval.md`.
4. **Iterate** — Apply feedback, improve, re-run. See `references/iterate.md`.
5. **Optimize description** — Generate 20 trigger eval queries. Run `skill_optimize_loop`. Apply `best_description`. See `references/description-optimization.md`.
6. **Install** — Validate with `skill_validate`, copy to project or global skills dir.

## Available Tools

`skill_validate` · `skill_parse` · `skill_eval` · `skill_improve_description` · `skill_optimize_loop` · `skill_aggregate_benchmark` · `skill_generate_report` · `skill_serve_review` · `skill_stop_review` · `skill_export_static_review`

## References

| File | Content |
|------|---------|
| `references/intake.md` | Interview questions & edge cases |
| `references/skill-writing.md` | Anatomy, patterns, progressive disclosure |
| `references/eval.md` | Running evals, grading, benchmark, viewer |
| `references/iterate.md` | Improvement thinking, blind comparison |
| `references/description-optimization.md` | Trigger eval queries, optimization loop |
| `references/schemas.md` | JSON schemas for evals/grading/benchmark |
| `templates/eval-review.html` | Eval query review UI |
| `agents/grader.md` | Assertion evaluation |
| `agents/comparator.md` | Blind A/B comparison |
| `agents/analyzer.md` | Benchmark analysis |

## Principles

- **Explain the why** — transmit understanding, not rigid MUSTs
- **Progressive disclosure** — SKILL.md orchestrates, references/ has details
- **Generalize** — the skill will be used millions of times, don't overfit
- **Bundle scripts** — if all test cases write the same helper, ship it once
