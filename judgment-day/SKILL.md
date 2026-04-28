---
name: judgment-day
description: >
  Dual adversarial review. Triggers: "judgment day", "judgment-day", "review adversarial", "dual review", "juzgar".
---

## When
- User pide "judgment day"
- After significant implementation
- High-confidence review needed
- Single reviewer might miss edge cases

## Workflow

### 1. Skill Resolution (BEFORE judges)
1. mem_search("skill-registry") → .atl/skill-registry.md
2. Match compact rules por file extension
3. Inject en BOTH Judge prompts

### 2. Parallel Blind Review
- Launch 2 sub-agents via delegate (parallel, NOT sequential)
- Mismo target, independently
- Neither sabe del otro

### 3. Verdict Synthesis
```
Confirmed   → both agents → high confidence, fix
Suspect A   → Judge A only → triage
Suspect B   → Judge B only → triage
Contradiction → disagree → flag manual
```

### 4. Fix + Re-judge
- Apply fixes
- Re-judge until both pass OR escalate (2 iter max)

## Output
```markdown
| Issue | Judge A | Judge B | Action |
|-------|--------|--------|--------|
| bug in X | 🔴 | 🔴 | FIX |
| perf | 🟡 | — | triage |
| style | 🟢 | 🟢 | OK |
```

## Rules
- Never self-review as orchestrator
- Always parallel (2 judges)
- Identical prompts para ambos
- Fix = one change, re-judge

* judgment-day v2.0 — Karpathy Optimized *