---
name: opencode-skill-creator
description: "Create, test, evaluate, and iterate OpenCode skills with mandatory intake interview."
triggers: "create skill, edit skill, opencode skill, skill eval, evaluate prompt, benchmark skill, iterate skill, skill testing, skill creation"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1679
---

## When to Use
Create, test, evaluate, and iterate OpenCode skills with man

Loop: Decide → Draft → Test prompts → Run (with-skill & baseline) → Review → Iterate → Install.

## Creating a skill
**Intake** (mandatory): 3-5 questions on behavior, triggers, output quality, workflow, test cases. Skip only if confirmed (warn once). Summarize before drafting.

**Write SKILL.md** in `%TEMP%/opencode-skills/<name>/`. Name: `^[a-z0-9]+(-[a-z0-9]+)*$`. Description explicit + "pushy" (OpenCode undertriggers). All trigger info in frontmatter. Structure: `<name>/{SKILL.md, scripts/, references/, assets/}`. Keep <500 lines, ref files >300L need TOC.

**Test Cases**: 2-3 realistic prompts, user sign-off, save to `evals/evals.json`.

## Iteration: Apply → re-run into `iteration-N+1/` → `skill_serve_review` with `previousWorkspace` → repeat until done. Don't overfit. Prefer explanation over MUST/ALWAYS.

## Installation: Copy to `.opencode/skills/<name>/` (project) or `~/.config/opencode/skills/<name>/` (global). Validate with `skill_validate`.
## Plugin tools: skill_validate · skill_parse · skill_eval · skill_aggregate_benchmark · skill_serve_review · skill_stop_review
## Refs: opencode-skill-creator · skill-testing · skill-registry · skill-improver · karpathy-loop
---

docs/skills/opencode-skill-creator/reference.md
---