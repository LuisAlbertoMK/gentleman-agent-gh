---
name: karpathy-loop
description: "Iterative prompt optimization — write, measure, cut, repeat with progressive compression"
triggers: "Karpathy loop, optimize prompt, measure tokens"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1992
---

## When to Use
Prompt bloated/slow/expensive · need consistent quality at lower cost · production/automation prompts · skill authoring — every skill should pass karpathy-loop.

## STYLE (5 Rules)
1. **ID+TASK=ENOUGH** — identity+task. 2. **MINIMAL** — no 10+ item lists. 3. **FORMAT=INSTRUCT** — "Respond ONLY in JSON:{...}". 4. **CONSTRAINTS=FORMAT** — max X chars / code only. 5. **IMPLICIT CoT** — no "step by step"; "Reason ONLY if ambiguous".

## LOOP: Write→Measure→Cut→Repeat
1. **WRITE**: role + task + 1-2 examples + output. Don't optimize yet. 2. **MEASURE**: chars/4 ≈ tokens; score correctness/conciseness/robustness. 3. **CUT**: remove redundant→merge→simplify; no output change→cut. 4. **REPEAT**: improves+tokens down→continue; drops→revert; stagnant→new tactic.

Example: Write 680/170tok→6.3 | Cut T1 480/120→7.3 | T2 340/85→7.3 | T3 260/65→5.3 ✗ → REVERT T2. Final 340ch/85tok 7.3/10.

## Compression Levels
| Level | Target | What to cut |
|---|---|---|
| T1 | 20-30% | filler, transitions, "step by step" |
| T2 | 30-50% | merge redundant→bullets, remove context |
| T3 | 50-70% | template structures, shortcuts, minimal identity |

## Budget
ID+TASK: 20-50 | +example: +100-200 | +constraints: +50-100 | **OPTIMAL: 50-300**

## Decision — Remove?
Output changes?→keep · else concision?→remove · else clarity?→keep · else→remove

## STOP
Tokens <50 + works · 3 iterations no improvement · Fits in 1 line. **NEVER**: sacrifice correctness for tokens, or leave edge cases uncovered.

## Refs
lean-context · skill-improver · metricas · code-review-agent

## Reference
Worked examples, testing patterns, edge cases, anti-patterns → docs/skills/karpathy-loop/reference.md