# Golden Prompt Suite (tests/prompts/)

Pattern 1 of skill-testing: regression guard against silent skill bloat or contract drift (see docs/mejoras/2026-08-16 F4 -- 0 suites found).

## Purpose
Each file pins a representative skill invocation (Input) to the exact Expected Output per the skill ## Output contract, so regressions are caught.

## Format per file
- Skill: name
- Trigger: canonical trigger
- Input: the prompt/code a user sends
- Expected Output: exact output matching the skill contract
- Assertion: invariants a correct run must satisfy (format, slop coverage, token_budget)

## Running
Harness hook to be added by skill-testing.
