# Golden Prompt Suite (tests/prompts/)

Pattern 1 of skill-testing: regression guard against silent skill bloat or contract drift.

## Purpose
Each *.golden.md pins a representative skill invocation (Input) to the exact Expected Output per the skill ## Output contract, so regressions are caught without a live LLM run.

## Format per file
- ## Skill: name
- ## Trigger: canonical trigger
- ## Input: the prompt/code a user sends
- ## Expected Output: exact output matching the skill contract
- ## Assertion: invariants a correct run must satisfy (format, regression coverage, token_budget)

## Running
Static gate provided by tests/golden-fixtures.Tests.ps1. Run locally:

  .\scripts\run-tests.ps1 -Path tests/golden-fixtures.Tests.ps1

Staged copies are executed by the Gentleman Quality Gate ([12/13] Pester tests).

## Fixtures (10/10 cluster skills)
| Skill | Contract prefix | File |
|---|---|---|
| baseline-ui | UI-CLEANUP | baseline-ui.golden.md |
| ui-engine | UI-IMPLEMENT | ui-engine.golden.md |
| seo | SEO AUDIT | seo.golden.md |
| web-quality-audit | AUDIT | web-quality-audit.golden.md |
| performance | PERF-AUDIT | performance.golden.md |
| performance-tracker | PERF-SCORE | performance-tracker.golden.md |
| accessibility | A11Y-AUDIT | accessibility.golden.md |
| visual-testing | VRT | visual-testing.golden.md |
| vision-analyze | VISION | vision-analyze.golden.md |
| image-pipeline | IMG-PIPELINE | image-pipeline.golden.md |
