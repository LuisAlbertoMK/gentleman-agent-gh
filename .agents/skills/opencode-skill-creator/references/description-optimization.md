# Description Optimization

The description field in SKILL.md frontmatter is the primary triggering mechanism. After creating/improving a skill, optimize for better triggering accuracy.

## Step 1: Generate trigger eval queries

Create 20 eval queries (JSON array of `{query, should_trigger}` — 8-10 of each).

**Should-trigger**: different phrasings of the same intent — formal, casual. Include uncommon use cases and competitive scenarios.

**Should-not-trigger**: near-misses. Queries sharing keywords but need something different. NOT trivial negatives — those test nothing.

Queries must be realistic: file paths, personal context, column names, URLs, backstory. Mix lengths, include typos and casual speech. Focus on edge cases.

## Step 2: Review with user

Use `templates/eval-review.html`. Replace `__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`. Open in browser. User edits and exports. Check Downloads folder.

## Step 3: Run optimization loop

Save eval set to workspace. Use `skill_optimize_loop`:
```
evalSetPath: <path-to-trigger-eval.json>
skillPath: <path-to-skill>
model: <current-session-model>
maxIterations: 5
```

This splits 60/40 train/test, evaluates (3 runs/query), improves, repeats. Selects best by test score (avoids overfitting).

## How Triggering Works

OpenCode consults skills for complex/multi-step tasks. Simple one-step queries won't trigger regardless of description. Your eval queries should be substantive enough that OpenCode benefits from a skill.

## Step 4: Apply result

Take `best_description`, update SKILL.md frontmatter. Show user before/after and scores.
