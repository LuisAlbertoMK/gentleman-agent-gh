---
name: work-unit-commits
description: "Plan commits as reviewable work units."
triggers: "work unit, commit splitting, commit organization, reviewable commits, split commit, stacked PR, chained PR commits"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2338
---
## When to Use
Splitting feature into reviewable work units · preparing commits before PR · large change into chained/stacked PRs · healthy reviewer cognitive load · SDD tasks without exceeding 400 lines.
## Rules
| Rule | Req |
|---|---|
| Commit by work unit | A commit = deliverable behavior/fix/migration/docs |
| NOT by file type | Avoid `models`→`services`→`tests` if none works alone |
| Tests with code | Same commit as behavior they verify |
| Docs with change | Same commit as feature/workflow they explain |
| Tell a story | Reviewer understands why each commit exists from diff+message |
| Future PR-ready | Each commit = candidate chained PR slice |
| SDD guard | >400-line forecast → chain before implementing |
## Checklist (pre-commit)
- [ ] One clear purpose
- [ ] Repo works after this commit alone
- [ ] Tests/docs included when relevant
- [ ] Rollback without reverting unrelated work
- [ ] Message explains outcome, not file list
## Chained PRs from Work Units
1. Build smallest independent unit → include verification → commit conventional. 2. If PR→400 lines → promote commits into chained PRs.
## Commands
```bash
git diff --stat
git diff --cached --stat
git log --oneline -5
```
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
commit-crafter · chained-pr · branch-pr · sdd · quality-gate
## Anti-Patterns
Commit by file type · Separate tests from code · >400 lines without chaining · Messages that list files · No SDD forecast check
> docs/skills/work-unit-commits/reference.md

