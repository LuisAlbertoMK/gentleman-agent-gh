# trial-verify — Reference Materials

> **Externalized from** .agents/skills/trial-verify/SKILL.md to keep the skill under the 3KB token budget (ADR-048, cycle32-p2).
> Contains worked examples (trial #1/#2), testing patterns, edge cases, anti-patterns.
> **Consumable by**: $Skill sub-agent when producing output.

## Worked Examples

### Trial #1 — Synthesis of deep-sub vs quick-sub (C=21/25, A=20/25)
- **Context**: 2026-08-24 auth refactor — 2 candidates: deep reasoning vs quick patch.
- **Prototype**: deep-sub produced typed diff + rollback plan; quick-sub produced minimal diff.
- **Verify**: independent subagent scored efficacy 5/4, token economy 3/5, failure-mode 4/3, protocol 4/4, learning 5/4 → totals 21 vs 20. Verifier bias confirmed (never self-grade alone).
- **Select**: deep-sub C won by 1 pt but token cost higher → synthesis: deep structure + quick guard clauses. Ledger saved as trial/auth-refactor.
- **Lesson**: self-grade without independent verifier inflates scores by ~15%.

### Trial #2 — P3 won 20/25, detection regex fixture-tested 1 hit / 0 FP
- **Context**: regex detection for SkillOpt gate — 3 options: strict regex, fuzzy match, hybrid.
- **Prototype**: each as config diff + fixture test.
- **Verify**: hybrid P3 scored 20/25 (efficacy 5, economy 4, failure-mode 4, consistency 4, persistence 3). Fixture: 1 hit / 0 FP.
- **Select**: P3 winner; known gap: authoring clone lacked core.hooksPath — verify wiring per clone, never trust "wired per docs".

## Testing Patterns

### Pattern 1: Rubric Scoring
```bash
# Simulate verifier scoring 0-5 per rubric
score() { echo "$1 $2 $3 $4 $5" | awk '{print $1+$2+$3+$4+$5}'; }
score 5 3 4 4 5 # -> 21
score 4 5 3 4 4 # -> 20
```

### Pattern 2: Ledger Persistence
```bash
mem_save(topic_key="trial/<topic>", type=decision, content="What: ... Options: ... Scores: ... Winner: ... Why: ...")
mem_search(query="trial/<topic>") # verify persisted
```

### Pattern 3: Budget Guard
```bash
# Abort if >15 tool calls or >3 options or >2 verifications
[ "$options" -gt 3 ] && echo "cap 3 — analysis-paralysis guard"
[ "$verifications" -gt 2 ] && echo "abort verifier loop"
[ "$calls" -gt 15 ] && echo "abort trial — over budget"
```

## Edge Cases

### Edge 1: Verification unavailable after 2 attempts
- Behavior: fallback to simplest option, confidence: low, ledger marks `verification: failed`.
- Do NOT retry third time — prevents infinite loop.

### Edge 2: Verifier disagreement (split scores)
- Behavior: synthesize hybrid with BOTH objections as constraints; document synthesis in ledger `Synthesis: hybrid of A+B with constraints`.

### Edge 3: Irreversible >1 file
- Behavior: Hard stop — ask human. Trial-verify only for reversible Bajo/Medio.

### Edge 4: Over-budget prototype (>15 calls)
- Behavior: prototype only differentiating part, not full implementation.

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| Self-grade without independent subagent | Always delegate verification — bias verified trial #1 |
| Promote defaults that bypass Alto checkpoints | Never bypass Alto — compliance risk; ledger must flag |
| Register skill without updating canonical counts | Update cross-ref + coverage + drift gates same session |
| Cap 3 violated (4+ options) | Enforce enumerate cap 3 — prevents paralysis |
| No ledger | Always mem_save trial/<topic> — learning persistence |
| Prose prototype (no artifact) | Require concrete text/diff/config artifact |

## Learning Loop
Every 10 ledgers run automejora-analyzer: option-TYPE winning >70% within domain becomes default-first-candidate — never bypassing Alto checkpoints.

## Validation (moved from SKILL.md)
Validated pre-codification (trial #1: synthesis deep-sub C=21/25 + quick-sub A=20/25; trial #2: P3 won 20/25, detection regex 1 hit /0 FP). Known gap: authoring clone lacked core.hooksPath — verify wiring per clone.

## Refs
- .agents/skills/trial-verify/SKILL.md · triple-verify · testing-strategy
