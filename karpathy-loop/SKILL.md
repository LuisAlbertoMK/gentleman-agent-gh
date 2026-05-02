---
name: karpathy-loop
description: >
  Karpathy optimization cycle: write → measure → cut → repeat.
  Trigger: Optimize prompt, reduce tokens, improve effectiveness.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## The Loop
```
Write → Measure → Cut → Repeat → Optimal
```

## Phases

### 1: WRITE
Write initial version: role + task + 1-2 examples + output format. Don't optimize yet.

### 2: MEASURE
```bash
echo "$PROMPT" | wc -c  # chars / 4 ≈ tokens
```
Score 1-10: Correctness · Conciseness · Robustness

### 3: CUT
- Can I remove this phrase?
- Is this example necessary?
- Can I merge these instructions?
- Any redundancy?

**Rule:** If it doesn't change the result, remove it.

### 4: REPEAT
Re-measure. Score improves AND tokens drop → continue. Score drops → revert last change. Stagnant → try another tactic.

## Iteration Template
```markdown
## Karpathy Loop — Iteration #[N]
### Prompt
[prompt]
### Metrics
| Tokens | ~X | Correctness | X/10 | Conciseness | X/10 | Robustez | X/10 |
### Changes
- [change 1]
### After
| Metric | Before | After |
| Tokens | X | Y |
```

## Cut Tactics
**Level 1 (20-30%):** Remove filler · Cut greetings · Drop "think step by step" · Merge similar phrases
**Level 2 (30-50%):** Merge redundant instructions · Paragraphs → bullets · Remove unnecessary context · Combine similar examples
**Level 3 (50-70%):** Use template structures · Shortcuts ("Constraints:" vs list) · Remove verbose identity → role + task + output format only

## Decision Matrix
```
Can I remove [element]?
├─ Changes output? → YES: keep | NO: improves concision?
│   ├─ YES: remove
│   └─ NO: adds clarity? → YES: keep | NO: remove
```

## Stop Threshold
Stop if: Tokens < 50 AND works · 3 iterations without improvement · Prompt fits 1 line
Never stop if: Sacrificing correctness for tokens · Edge cases uncovered

## Example
**Initial (150 tokens):** "Eres un desarrollador senior de Go con más de 10 años de experiencia especializado en APIs REST..."
**Iter 1 (35 tokens):** "Eres dev Go senior. Implementá endpoint login JWT. Tests coverage. Response: Go code only." — Score: 9/10
**Iter 2 (12 tokens):** "Go dev. Login JWT endpoint + tests." — Score: 8/10
**Result: 88% reduction, 8/10 quality**

## Commands
```bash
prompt_tokens() { echo "$1" | wc -c | awk '{print int($1/4)}' }
```
