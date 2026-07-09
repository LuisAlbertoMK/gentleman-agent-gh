---
name: opencode-skill-creator
description: "Create, test, evaluate, and iterate OpenCode skills. Trigger: user mentions creating/editing a skill, running evals, evaluating prompts, benchmarking performance, optimizing descriptions, or iterating on a skill they're building. For new skills, conduct mandatory intake interview (3-5 questions). Do NOT use for non-OpenCode skill creation (Claude Code, Superpowers) unless user asks to port that workflow."
---

Create, test, evaluate, and iterate OpenCode skills.

**Core loop**: Decide intent → Draft skill → Create test prompts → Run with-skill & baseline → Review → Iterate → Install.

## Creating a skill

### Intake (mandatory for new skills)
3-5 questions covering: end-to-end behavior, trigger phrases, output format/quality, workflow flexibility, test cases. Skip only with explicit user confirmation (warn once). Summarize understanding before drafting.

### Write SKILL.md
Stage in `%TEMP%/opencode-skills/<name>/`. Name: kebab-case `^[a-z0-9]+(-[a-z0-9]+)*$`. Description must be explicit + "pushy" — OpenCode undertriggers. Include specific contexts, near-misses, and when NOT to use. All trigger info in frontmatter, not body.

Structure:
```
<name>/
├── SKILL.md (name + description frontmatter)
├── scripts/   — Deterministic tasks (bundled, not loaded)
├── references/— Docs loaded on-demand
└── assets/    — Templates/icons/fonts
```

Keep SKILL.md <500 lines. Reference files >300 lines need TOC. Multi-domain skills: selecting SKILL.md + per-variant ref files.

**Style**: Imperative. Explain WHY. Be general, don't overfit. Examples: Input/Output blocks, focused.

### Test Cases
Draft 2-3 realistic prompts, user sign-off. Save to `evals/evals.json`:
```json
{"skill_name": "<name>", "evals": [{"id": 1, "prompt": "...", "expected_output": "...", "files": []}]}
```
Full schema: `references/schemas.md`.

## Running evals (continuous sequence — don't stop mid-way)

Workspace: `<skill>-workspace/` next to staging dir. Results in `iteration-N/eval-ID/{with_skill,baseline}/outputs/`.

### Step 1: Spawn all runs same turn
Each test case → 2 Task tool invocations (with-skill + baseline) in the SAME turn. Baseline for new skill = `without_skill`; for improvement = skill snapshot.

### Step 2: Draft assertions while runs execute
Quantitative for objective skills (file transforms, code gen, fixed workflows). Subjective → skip assertions, use qualitative eval.

### Step 3: Capture timing
Each Task returns `total_tokens` + `duration_ms`. Save to `timing.json` immediately.

### Step 4: Grade → Aggregate → Launch viewer
- Grade: `agents/grader.md` via Task. Save `grading.json` (exact fields: `expectations[{text, passed, evidence}]`)
- Aggregate: `skill_aggregate_benchmark(benchmarkDir, skillName)` → `benchmark.json` + `.md`
- Analyze: `agents/analyzer.md` for non-discriminating assertions, flaky evals
- Viewer: `skill_serve_review(workspace, name, benchmarkPath)`. Headless → `skill_export_static_review`
- Notify: "Results in browser — Outputs tab for per-case, Benchmark tab for stats"

### Step 5: Read feedback
Read `feedback.json`. Stop viewer via `skill_stop_review`.

## Iteration loop
1. Apply improvements to skill
2. Re-run all test cases into `iteration-N+1/` (with baselines)
3. `skill_serve_review` with `previousWorkspace` pointing to prior iteration
4. Wait for user review; repeat until: user satisfied, feedback empty, or no meaningful progress

**Improve**: Don't overfit to test examples — must work on unseen prompts. Prefer explanation over MUST/ALWAYS. Bundle repeated helper scripts in `scripts/`.

## Description optimization (post-creation, optional)
1. Create 20 trigger eval queries (8-10 should-trigger + 8-10 should-not, concrete contexts)
2. User reviews via `templates/eval-review.html` → exports `eval_set.json`
3. `skill_optimize_loop(evalSetPath, skillPath, model, maxIterations: 5)` → auto-splits 60/40, evaluates 3×/query, returns `best_description`
4. Update frontmatter description, show before/after + scores

**Note**: OpenCode only consults skills for non-trivial tasks. Make eval queries substantive.

## Installation
Copy validated skill to `.opencode/skills/<name>/` (project) or `~/.config/opencode/skills/<name>/` (global). Validate with `skill_validate`. Keep drafts in staging.

## Plugin tools
`skill_validate` · `skill_parse` · `skill_eval` · `skill_improve_description` · `skill_optimize_loop` · `skill_aggregate_benchmark` · `skill_generate_report` · `skill_serve_review` · `skill_stop_review` · `skill_export_static_review`

## Reference files
- `agents/grader.md` — Assertion grading
- `agents/comparator.md` — Blind A/B comparison
- `agents/analyzer.md` — Benchmark analysis
- `references/schemas.md` — JSON schemas

Add "Create evals JSON and launch viewer" to TodoList.
