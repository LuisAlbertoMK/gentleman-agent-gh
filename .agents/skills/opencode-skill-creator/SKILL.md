---
name: opencode-skill-creator
description: Create, test, evaluate, optimize, and package OpenCode skills with the opencode-skill-creator plugin. Use when users explicitly mention opencode-skill-creator, OpenCode Skill Creator, creating an OpenCode skill, editing an OpenCode SKILL.md, running skill evals, benchmarking skill performance, or optimizing an OpenCode skill description. Do not use for generic Claude Code or Superpowers skill creation unless the user asks to port that workflow to OpenCode.
---

# OpenCode Skill Creator

Create, test, evaluate, and iterate OpenCode skills.

**Core loop**: Decide intent → Draft skill → Create test prompts → Run with-skill & baseline → Review with user → Iterate → Install.

**Your role**: Detect where the user is in this loop and jump in. For new skills, the intake interview is mandatory (3-5 questions minimum). For existing drafts, skip to eval/iterate.

**Intake gate**: Mandatory for new skills. Ask 3-5 targeted Qs covering: end-to-end behavior, trigger phrases, output format/quality bar, workflow flexibility, test cases needed. Summarize understanding for confirmation. If user skips intake, warn once then proceed.

**Tone**: Adapt to user's technical level. "Evaluation"/"benchmark" OK by default. "JSON"/"assertion" require user to show familiarity. Briefly explain terms when unsure.

## Creating a skill

### Capture Intent (Required Gate for New Skills)

For new skills, this step is mandatory and cannot be skipped. Do not draft SKILL.md, evals, or other files until this interview is complete and the user confirms your summary.

Start by understanding the user's intent. The current conversation might already contain part of the workflow the user wants to capture (e.g., they say "turn this into a skill"). Extract that first: tools used, sequence of steps, corrections, inputs/outputs, and success criteria. Then fill the gaps with questions.

Ask at least 3-5 targeted questions (more when needed). Cover these minimum areas:

1. What should this skill enable OpenCode to do end-to-end?
2. When should this skill trigger? (phrases, contexts, near-misses)
3. What output format and quality bar are expected?
4. What workflow steps must be preserved exactly vs. where can the agent improvise?
5. Should we set up test cases to verify behavior? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on skill type, then let the user decide.

Before moving on, summarize your understanding in plain language and ask the user to confirm or correct it.

If the user explicitly asks to skip intake, warn that final quality and workflow fit will likely be worse. Proceed only after explicit confirmation.

### Interview & Research

Cover edge cases, I/O formats, deps, success criteria. Mirror user's workflow & terminology. Check MCPs for docs/best-practices research via Task tool in parallel. Draft test prompts only after this is solid.

### Write the SKILL.md

Default to `%TEMP%/opencode-skills/<skill-name>/` (staging, not project dir). Components:
- **name**: kebab-case, regex `^[a-z0-9]+(-[a-z0-9]+)*$`
- **description**: Trigger mechanism — be explicit AND "pushy" (OpenCode undertriggers). Include specific contexts, near-misses, and when NOT to use. All trigger info goes here, not body.
- **compatibility**: deps (optional)**

### Skill Writing Guide

#### Skill Structure

```
skill-name/
├── SKILL.md (required — name + description frontmatter)
├── scripts/   - Deterministic tasks (bundled, not loaded)
├── references/- Docs loaded on-demand
└── assets/    - Templates/icons/fonts
```

Skill dir name == `name` field. Keep SKILL.md <500 lines. Reference files >300 lines need a TOC.

For multi-domain skills, organize by variant with a selecting SKILL.md and per-variant reference files.

**Safety**: No malware/exploit/unexpected behavior. OK: roleplay skills.  
**Style**: Imperative tone. Explain WHY (not MUST/ALWAYS). Be general, not overfit.  
**Examples**: Use Input/Output blocks. Keep them focused.

### Test Cases

Draft 2-3 realistic test prompts. Share with user for sign-off before running. Save to `evals/evals.json` (prompts only, no assertions yet). Structure:

```json
{
  "skill_name": "example-skill",
  "evals": [{"id": 1, "prompt": "...", "expected_output": "...", "files": []}]
}
```

Full schema at `references/schemas.md` (includes `assertions` field added later).

## Running and evaluating test cases

This section is one continuous sequence — don't stop partway through. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` next to the staged skill directory in the system temp area (for example: Unix/macOS `/tmp/opencode-skills/<skill-name>-workspace/`; Windows `%TEMP%\\opencode-skills\\<skill-name>-workspace\\`). Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Don't create all of this upfront — just create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two Task tool invocations (using `general` subagent type) in the same turn — one with the skill, one without. This is important: don't spawn the with-skill runs first and then come back for baselines later. Launch everything at once so it all finishes around the same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about — e.g., "the .docx file", "the final CSV">
```

**Baseline run** (same prompt, but the baseline depends on context):
- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Before editing, snapshot the skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline Task tool invocation at the snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Give each eval a descriptive name based on what it's testing — not just "eval-0". Use this name for the directory too. If this iteration uses new or modified eval prompts, create these files for each new eval directory — don't assume they carry over from previous iterations.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs run — draft assertions

Draft quantitative assertions (objectively verifiable, descriptive names). Subjective skills → skip assertions, use qualitative eval. Update `eval_metadata.json` + `evals/evals.json`.

### Step 3: Capture timing on notification

Each Task completion returns `total_tokens` + `duration_ms`. Save immediately to `timing.json` — this is the only chance.

### Step 4: Grade → Aggregate → Launch viewer

Gate: every eval needs paired outputs (with_skill + baseline). No partial data unless user OKs it.

1. **Grade runs**: Use `agents/grader.md` via Task tool or inline. Save `grading.json` with `{"expectations": [{"text": "...", "passed": bool, "evidence": "..."}]}` — exact field names required by viewer.
2. **Aggregate**: `skill_aggregate_benchmark(benchmarkDir, skillName)` → `benchmark.json` + `benchmark.md`.
3. **Analyze**: See `agents/analyzer.md` for non-discriminating assertions, flaky evals, time/token tradeoffs.
4. **Launch viewer**: `skill_serve_review(workspace, skillName, benchmarkPath, allowPartial: false, previousWorkspace?: ...)`. Headless → `skill_export_static_review`.
5. **Tell user**: "Results in browser — Outputs tab for per-case review, Benchmark tab for stats."

### Step 5: Read feedback

Read `feedback.json`. Empty feedback = OK. Focus on cases with specific complaints. Stop viewer with `skill_stop_review`.

---

## Improving the skill

**Generalize**: Don't overfit to test examples — the skill must work on unseen prompts. If stubborn issues, try different metaphors/patterns.  
**Keep lean**: Remove unused content. Read transcripts, not just outputs. Cut anything causing waste.  
**Explain WHY**: LLMs understand reasoning. Prefer explanation over MUST/ALWAYS — it produces better generalization.  
**Bundle repeated work**: If multiple test cases independently write the same helper script → bundle it in `scripts/`.  
**Take time**: Writing a draft then revising with fresh eyes beats rushing.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs. If you're creating a new skill, the baseline is always `without_skill` (no skill) — that stays the same across iterations. If you're improving an existing skill, use your judgment on what makes sense as the baseline: the original version the user came in with, or the previous iteration.
3. Launch the reviewer with the `skill_serve_review` tool, passing `previousWorkspace` pointing at the previous iteration
4. Wait for the user to review and tell you they're done
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all empty (everything looks good)
- You're not making meaningful progress

---

## Blind comparison (optional)

For rigorous A/B: read `agents/comparator.md` + `agents/analyzer.md`. Give two anonymized outputs to an independent agent → judge quality → analyze why winner won. Requires Task tool. Usually unnecessary — human review is sufficient.

---

## Description Optimization

After creating/improving a skill, offer to optimize its description for trigger accuracy.

### Step 1: Create 20 trigger eval queries

```json
[{"query": "user prompt", "should_trigger": true}, ...]
```

8-10 should-trigger (different phrasings, formal+casual, edge cases) + 8-10 should-not-trigger (near-misses, not obviously irrelevant). Make queries concrete with context (file paths, company names, backstory) — avoid abstract `"Format this data"`.

### Step 2: User review via HTML template

Read `templates/eval-review.html`, replace `__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`. Open temp file in browser. User edits toggles, clicks "Export Eval Set" → `~/Downloads/eval_set.json`.

### Step 3: Run optimization loop

```
skill_optimize_loop(evalSetPath, skillPath, model: <current-model>, maxIterations: 5)
```

Auto-splits 60/40 train/test, evaluates each description 3× per query, iterates up to 5, returns `best_description` (by test score).

### Trigger note

OpenCode only consults skills for non-trivial tasks. Simple queries won't trigger regardless of description. Make eval queries substantive.

### Step 4: Apply result

Update SKILL.md frontmatter with `best_description`. Show user before/after + scores.

---

## Installation

Copy validated skill directory to `.opencode/skills/<name>/` (project) or `~/.config/opencode/skills/<name>/` (global). Validate with `skill_validate`. Keep drafts in staging.

## Plugin tools

`skill_validate` · `skill_parse` · `skill_eval` · `skill_improve_description` · `skill_optimize_loop` · `skill_aggregate_benchmark` · `skill_generate_report` · `skill_serve_review` · `skill_stop_review` · `skill_export_static_review`

## Reference files

- `agents/grader.md` — Assertion grading instructions
- `agents/comparator.md` — Blind A/B comparison
- `agents/analyzer.md` — Benchmark analysis
- `references/schemas.md` — JSON schemas

Add "Create evals JSON and launch viewer" to your TodoList to ensure it runs.
