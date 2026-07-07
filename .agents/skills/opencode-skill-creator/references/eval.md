# Running and Evaluating Test Cases

This is one continuous sequence — don't stop partway. Do NOT use `/skill-test`.

Put results in `<skill-name>-workspace/` next to the staged skill directory in `%TEMP%\opencode-skills\`. Organize by `iteration-N/eval-ID/`.

## Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn TWO Task tool invocations (`general` subagent) in the same turn:

**With-skill:**
```
Skill path: <path-to-skill>
Task: <eval prompt>
Input files: <none or path>
Save outputs to: <workspace>/iteration-N/eval-ID/with_skill/outputs/
```

**Baseline:**
- **New skill**: no skill path, save to `without_skill/outputs/`
- **Improving existing**: snapshot old skill, point baseline at snapshot, save to `old_skill/outputs/`

Write `eval_metadata.json` per test case with `eval_id`, `eval_name`, `prompt`, `assertions: []`.

## Step 2: Draft assertions while runs progress

Don't wait — draft quantitative assertions. Good assertions are objectively verifiable with descriptive names. Subjective skills need human judgment.

Update `eval_metadata.json` and `evals/evals.json` with drafts.

## Step 3: Capture timing data

When each Task tool invocation completes, save `total_tokens` and `duration_ms` to `timing.json` immediately — this data comes through the notification and isn't persisted elsewhere.

## Step 4: Grade, aggregate, launch viewer

**Gate**: every eval must have paired comparison outputs. Don't continue if pairs are missing.

1. **Grade** — Read `agents/grader.md`, evaluate each assertion. Save to `grading.json` (fields: `text`, `passed`, `evidence`).
2. **Aggregate** — Use `skill_aggregate_benchmark` tool with `benchmarkDir: <workspace>/iteration-N`.
3. **Analyze** — Read `agents/analyzer.md` for patterns: non-discriminating assertions, high-variance evals, time/token tradeoffs.
4. **Launch viewer** — `skill_serve_review` with `workspace`, `benchmarkPath`, optionally `previousWorkspace`. For headless: `skill_export_static_review`.
5. **Tell user**: "I've opened the results in your browser. Two tabs: Outputs and Benchmark."

## Step 5: Read feedback

Read `feedback.json` when user is done. Empty feedback = good. Focus improvements on test cases with specific complaints. Stop the viewer with `skill_stop_review`.

## Iteration Loop

After improving the skill:
1. Rerun into `iteration-N+1/`
2. Launch viewer with `previousWorkspace`
3. Wait for feedback
4. Repeat until: user is happy, all feedback empty, or no meaningful progress
