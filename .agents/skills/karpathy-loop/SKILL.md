---
name: karpathy-loop
description: "Iterative prompt optimization loop — write, measure, cut, repeat with progressive compression levels and decision gates"
triggers: "Karpathy loop, optimize prompt, measure tokens"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: mk
  version: "2.0"
  changelog: "2.0: merged karpathy-prompt (style/rules/budget)"
---

Trigger: "optimize prompt", "reduce tokens", "Karpathy prompt", "less tokens", "context compilation".

## 1. STYLE — 5 Rules (absorbed from karpathy-prompt)
1. **ID+TASK=ENOUGH** — identity + task is sufficient context
2. **MINIMAL** — no 10+ item lists or paragraphs
3. **FORMAT=INSTRUCT** — "Respond ONLY in JSON:{...}"
4. **CONSTRAINTS=FORMAT** — max X chars / code only
5. **IMPLICIT CoT** — no "step by step"; "Reason ONLY if ambiguous"

### WIKI: Compression Levels
- **T1**: Raw full content
- **T2**: LLM-compiled summary
- **T3**: index.md (~200t)
- Pre-compile files → ~3-5K map → use as input

### ANTI-Patterns
- "detailed" → "precise"
- "step by step" → omit
- "10+ rules" → 2-3 constraints
- "verbose identity" → role + task + output

### BUDGET (tokens)
| Element | Cost |
|---------|------|
| ID + TASK | 20-50 |
| + example | +100-200 |
| + constraints | +50-100 |
| + output | +30-50 |
| **OPTIMAL** | **50-300** |

## 2. LOOP: Write → Measure → Cut → Repeat

## 3. PHASES
1. **WRITE**: role + task + 1-2 examples + output. Don't optimize yet.
2. **MEASURE**: chars/4 ≈ tokens. Score: correctness / conciseness / robustness
3. **CUT**: remove redundant / merge / simplify. If no output change → cut.
4. **REPEAT**: score improves + tokens down → continue. Score drops → revert. Stagnant → try new tactic.

## 4. TACTICS by Compression Level
- **T1** (20-30%): filler, transitions, "step by step"
- **T2** (30-50%): merge redundant → bullets, remove context
- **T3** (50-70%): template structures, shortcuts, minimal identity

## 5. DECISION — Remove Element?
```
Remove element?
├─ Output changes? → YES: keep
└─ No → concision improves?
    ├─ YES: remove
    └─ NO → clarity? → YES: keep | NO: remove
```

## 6. STOP Conditions
- Tokens < 50 + works
- 3 iterations without improvement
- Fits in 1 line

**NEVER**: sacrifice correctness for tokens, or leave uncovered edge cases.

## Refs
lean-context · skill-improver · prompt-engineering · metricas · context-watchdog

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness for tokens · Skip edge case coverage · Optimize beyond diminishing returns
