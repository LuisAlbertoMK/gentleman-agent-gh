---
name: karpathy-loop
description: "Iterative prompt optimization — write, measure, cut, repeat with progressive compression"
triggers: "Karpathy loop, optimize prompt, measure tokens"
---

## STYLE (5 Rules)
1. **ID+TASK=ENOUGH** — identity + task = sufficient context
2. **MINIMAL** — no 10+ item lists or paragraphs
3. **FORMAT=INSTRUCT** — "Respond ONLY in JSON:{...}"
4. **CONSTRAINTS=FORMAT** — max X chars / code only
5. **IMPLICIT CoT** — no "step by step"; "Reason ONLY if ambiguous"

## LOOP: Write → Measure → Cut → Repeat

1. **WRITE**: role + task + 1-2 examples + output. Don't optimize yet.
2. **MEASURE**: chars/4 ≈ tokens. Score: correctness / conciseness / robustness
3. **CUT**: remove redundant → merge → simplify. No output change → cut.
4. **REPEAT**: score improves + tokens down → continue. Drops → revert. Stagnant → new tactic.

### Concrete example: code review prompt

**WRITE** (iteration 0 — 680 chars / 170 tok):
```
You are a senior code reviewer. Review the following code diff. Focus on error handling, readability, reliability, and resilience. For each issue found, include the line number, a description of the problem, and a suggested fix. Rate each category from 1-10. If any category scores below 4, mark the review as BLOCKER. Output in markdown format with sections for each category.
```

**MEASURE**: Score: 8/10 correctness, 4/10 conciseness, 7/10 robustness = 6.3 avg

**CUT** (iteration 1 — T1: 20% compression → 480 chars / 120 tok):
```
You are a senior code reviewer. Review this diff. Focus on error handling, readability, reliability, resilience. For each issue: line number, problem, suggested fix. Rate each 1-10. Any <4 = BLOCKER. Output markdown with category sections.
```
Score: 8/10 correctness, 7/10 conciseness, 7/10 robustness = 7.3 avg ✓

**CUT** (iteration 2 — T2: 40% compression → 340 chars / 85 tok):
```
Senior reviewer. Review diff: 4R (Risk/Readability/Reliability/Resilience). Issue→line+problem+fix. Rate 1-10 each. <4=BLOCKER. Markdown output.
```
Score: 7/10 correctness, 9/10 conciseness, 6/10 robustness = 7.3 avg ✓ (same avg, keep)

**CUT** (iteration 3 — T3: 55% compression → 260 chars / 65 tok):
```
Review diff via 4R. Issue: ln+problem+fix. Rate 1-10. <4=BLOCKER. MD.
```
Score: 4/10 correctness, 9/10 conciseness, 3/10 robustness = 5.3 avg ✗ → **REVERT** to iteration 2.

**Final**: 340 chars / 85 tok, score 7.3/10. 50% compression ratio.

## Scoring Table

| Score | Correctness | Conciseness | Robustness |
|-------|-------------|-------------|------------|
| 9-10 | All intents preserved, no ambiguity | No wasted tokens, minimal viable | Covers all edge cases |
| 7-8 | Intents preserved, minor rephrase | Some filler remains | Most edge cases covered |
| 5-6 | Intent preserved but nuance lost | Wordy but functional | Key edge case missing |
| 3-4 | Intent partially lost | Redundant, >2x optimal | Multiple gaps |
| 1-2 | Wrong output format/behavior | Bloated, >3x optimal | Critical gaps |

Stop when: score avg ≥ 7 AND tokens < 100. Revert if any score drops by ≥ 3.

## COMPRESSION LEVELS
| Level | Target | What to cut |
|-------|--------|-------------|
| T1 | 20-30% | filler, transitions, "step by step" |
| T2 | 30-50% | merge redundant → bullets, remove context |
| T3 | 50-70% | template structures, shortcuts, minimal identity |

## BUDGET
| Element | Cost |
|---------|------|
| ID + TASK | 20-50 |
| + example | +100-200 |
| + constraints | +50-100 |
| **OPTIMAL** | **50-300** |

## DECISION — Remove?
```
Remove? → Output changes? YES→keep | NO→concision improves? YES→remove | NO→clarity? YES→keep | NO→remove
```

### Decision tree in practice
```
Test: "Review the following code" vs "Review this diff"
Q: Output changes? A: No (same behavior)
Q: Concision improves? A: Yes (shorter)
→ REMOVE "the following code", use "this diff"
```

## STOP
- Tokens < 50 + works · 3 iterations no improvement · Fits in 1 line

**NEVER**: sacrifice correctness for tokens, or leave edge cases uncovered.

## Refs
lean-context · skill-improver · prompt-engineering · metricas · code-review-agent

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness · Stop at T1 when T2 possible · Apply T3 to underspecified prompts · Score subjectively without criteria
