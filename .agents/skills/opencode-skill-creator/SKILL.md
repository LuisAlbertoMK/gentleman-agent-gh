---
name: opencode-skill-creator
description: "Create, test, evaluate, and iterate OpenCode skills with mandatory intake interview."
triggers: "create skill, edit skill, opencode skill, skill eval, evaluate prompt, benchmark skill, iterate skill, skill testing, skill creation"
---

## When to Use
Create, test, evaluate, and iterate OpenCode skills with man

<!-- karpathy-compressed: 2026-07-09 -->
Loop: Decide → Draft → Test prompts → Run (with-skill & baseline) → Review → Iterate → Install.

## Creating a skill
**Intake** (mandatory): 3-5 questions on behavior, triggers, output quality, workflow, test cases. Skip only if confirmed (warn once). Summarize before drafting.

**Write SKILL.md** in `%TEMP%/opencode-skills/<name>/`. Name: `^[a-z0-9]+(-[a-z0-9]+)*$`. Description explicit + "pushy" (OpenCode undertriggers). All trigger info in frontmatter. Structure: `<name>/{SKILL.md, scripts/, references/, assets/}`. Keep <500 lines, ref files >300L need TOC.

**Test Cases**: 2-3 realistic prompts, user sign-off, save to `evals/evals.json`.

## Running evals (continuous)
Workspace: `<skill>-workspace/`. Results in `iteration-N/eval-ID/{with_skill,baseline}/outputs/`.

1. **Spawn all runs same turn**: Each test → 2 Task calls (with-skill + baseline). Baseline = `without_skill` (new) or snapshot (improvement).
2. **Draft assertions while running**: Objective → quantitative. Subjective → skip.
3. **Capture timing**: `total_tokens` + `duration_ms` → `timing.json`.
4. **Grade → Aggregate → Viewer**: Grade via `agents/grader.md` → `grading.json`. Aggregate: `skill_aggregate_benchmark(...)`. Analyze: `agents/analyzer.md`. Viewer: `skill_serve_review` or `skill_export_static_review`.
5. **Read feedback**: `feedback.json`. Stop via `skill_stop_review`.

## Iteration: Apply → re-run into `iteration-N+1/` → `skill_serve_review` with `previousWorkspace` → repeat until done. Don't overfit. Prefer explanation over MUST/ALWAYS.

## Installation: Copy to `.opencode/skills/<name>/` (project) or `~/.config/opencode/skills/<name>/` (global). Validate with `skill_validate`.
## Plugin tools: skill_validate · skill_parse · skill_eval · skill_aggregate_benchmark · skill_serve_review · skill_stop_review
## Refs: opencode-skill-creator · skill-testing · skill-registry · skill-improver · karpathy-loop
## Anti-Patterns: Skip intake · One-shot · No baseline · Overfit evals · Install before validate

## Example: Creating a Skill
```
User: "Create a skill for Docker best practices"
Agent (intake): 1. What scenarios? (dev, prod, multi-stage) 2. Triggers? 3. Output format?
Agent (draft): Write SKILL.md → %TEMP%/opencode-skills/docker-best-practices/
Agent (test): 2 test prompts → run with-skill + baseline → compare
Agent (iterate): Fix trigger coverage → re-test → approve
Agent (install): Copy to .opencode/skills/docker-best-practices/
```
