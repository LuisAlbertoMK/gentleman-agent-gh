---
name: opencode-skill-creator
description: "Create, test, evaluate, and iterate OpenCode skills. Trigger: user mentions creating/editing a skill, running evals, evaluating prompts, benchmarking performance, optimizing descriptions, or iterating on a skill they're building. For new skills, conduct mandatory intake interview (3-5 questions). Do NOT use for non-OpenCode skill creation (Claude Code, Superpowers) unless user asks to port that workflow."
---

Create, test, evaluate, and iterate OpenCode skills. Core loop: Decide → Draft → Test prompts → Run (with-skill & baseline) → Review → Iterate → Install.

## Creating a skill
**Intake** (mandatory): 3-5 questions on behavior, triggers, output quality, workflow, test cases. Skip only if user confirms (warn once). Summarize before drafting.

**Write SKILL.md** in `%TEMP%/opencode-skills/<name>/`. Name: `^[a-z0-9]+(-[a-z0-9]+)*$`. Description explicit + "pushy" — OpenCode undertriggers. All trigger info in frontmatter. Structure: `<name>/ {SKILL.md, scripts/, references/, assets/}`. Keep <500 lines, ref files >300L need TOC.

**Test Cases**: 2-3 realistic prompts, user sign-off, save to `evals/evals.json`.

## Running evals (continuous — don't stop mid-way)
Workspace: `<skill>-workspace/`. Results in `iteration-N/eval-ID/{with_skill,baseline}/outputs/`.

1. **Spawn all runs same turn**: Each test → 2 Task calls (with-skill + baseline). Baseline = `without_skill` (new) or snapshot (improvement).
2. **Draft assertions while running**: Objective → quantitative. Subjective → skip assertions.
3. **Capture timing**: `total_tokens` + `duration_ms` → `timing.json` immediately.
4. **Grade → Aggregate → Viewer**: Grade via `agents/grader.md` → `grading.json`. Aggregate: `skill_aggregate_benchmark(...)`. Analyze: `agents/analyzer.md`. Viewer: `skill_serve_review` or headless `skill_export_static_review`.
5. **Read feedback**: `feedback.json`. Stop via `skill_stop_review`.

## Iteration loop
Apply improvements → re-run all tests into `iteration-N+1/` → `skill_serve_review` with `previousWorkspace` → repeat until satisfied/empty feedback/no progress. Don't overfit. Prefer explanation over MUST/ALWAYS.

## Installation
Copy to `.opencode/skills/<name>/` (project) or `~/.config/opencode/skills/<name>/` (global). Validate with `skill_validate`.

## Plugin tools
`skill_validate` · `skill_parse` · `skill_eval` · `skill_improve_description` · `skill_optimize_loop` · `skill_aggregate_benchmark` · `skill_generate_report` · `skill_serve_review` · `skill_stop_review` · `skill_export_static_review`

## Reference files
- `agents/grader.md` — Grading
- `agents/comparator.md` — Blind A/B
- `agents/analyzer.md` — Analysis
- `references/schemas.md` — Schemas
- `references/description-optimization.md` — Post-creation desc optimization

Add "Create evals JSON and launch viewer" to TodoList.
