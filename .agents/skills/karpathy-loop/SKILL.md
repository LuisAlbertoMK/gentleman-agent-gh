---
name: karpathy-loop
description: "Iterative prompt optimization — write, measure, cut, repeat with progressive compression"
triggers: "Karpathy loop, optimize prompt, measure tokens"
---

## When to Use

## STYLE (5 Rules)
1. **ID+TASK=ENOUGH** — identity+task = enough
2. **MINIMAL** — no 10+ item lists or paragraphs
3. **FORMAT=INSTRUCT** — "Respond ONLY in JSON:{...}"
4. **CONSTRAINTS=FORMAT** — max X chars / code only
5. **IMPLICIT CoT** — no "step by step"; "Reason ONLY if ambiguous"

## LOOP: Write→Measure→Cut→Repeat
1. **WRITE**: role + task + 1-2 examples + output. Don't optimize yet.
2. **MEASURE**: chars/4 ≈ tokens. Score: correctness/conciseness/robustness
3. **CUT**: remove redundant→merge→simplify. No output change→cut.
4. **REPEAT**: score improves+tokens down→continue. Drops→revert. Stagnant→new tactic.

### Concrete example
**Write** (680/170 tok): "Review the following code diff. Focus on error handling..." → 6.3 avg
**Cut T1** (480/120): "Review this diff. Focus on error handling, readability..." → 7.3 ✓
**Cut T2** (340/85): "Senior reviewer. Review diff: 4R (Risk/Readability/Reliability/Resilience). Issue→line+problem+fix..." → 7.3 ✓
**Cut T3** (260/65): "Review diff via 4R. Issue: ln+problem+fix. Rate 1-10. <4=BLOCKER. MD." → 5.3 ✗ → **REVERT** to T2. Final: 340 chars/85 tok, 7.3/10.

## Scoring Table
| Score | Correctness | Conciseness | Robustness |
|-------|-------------|-------------|------------|
| 9-10 | All intents preserved | No wasted tokens | Covers all edge cases |
| 7-8 | Intents preserved, minor rephrase | Some filler | Most edge cases |
| 5-6 | Intent preserved, nuance lost | Wordy but functional | Key edge case missing |
| 3-4 | Intent partially lost | Redundant >2x optimal | Multiple gaps |
| 1-2 | Wrong output format/behavior | Bloated >3x optimal | Critical gaps |
Stop: avg ≥7 AND tokens <100. Revert if any score drops ≥3.

## Compression Levels
| Level | Target | What to cut |
|-------|--------|-------------|
| T1 | 20-30% | filler, transitions, "step by step" |
| T2 | 30-50% | merge redundant→bullets, remove context |
| T3 | 50-70% | template structures, shortcuts, minimal identity |

## Budget
ID+TASK: 20-50 | +example: +100-200 | +constraints: +50-100 | **OPTIMAL: 50-300**

## Decision — Remove?
Output changes?→keep · else concision?→remove · else clarity?→keep · else→remove

## STOP
Tokens <50 + works · 3 iterations no improvement · Fits in 1 line
**NEVER**: sacrifice correctness for tokens, or leave edge cases uncovered.

## Refs
lean-context · skill-improver · metricas · code-review-agent

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness · Stop at T1 when T2 possible · Apply T3 to underspecified prompts · Score subjectively without criteria
