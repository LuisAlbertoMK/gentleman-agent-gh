---
name: karpathy-loop
description: "Iterative prompt optimization — write, measure, cut, repeat with progressive compression"
triggers: "Karpathy loop, optimize prompt, measure tokens"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: mk
  version: "2.1"
  changelog: "2.0→2.1: Karpathy compress (2540→1620B)"
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

## STOP
- Tokens < 50 + works · 3 iterations no improvement · Fits in 1 line

**NEVER**: sacrifice correctness for tokens, or leave edge cases uncovered.

## Refs
lean-context · skill-improver · prompt-engineering · metricas

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness
