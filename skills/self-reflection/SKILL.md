---
name: self-reflection
description: >
  Hermes-style closed learning loop. Auto-reflect after tasks, self-evaluate periodically, create/update skills from experience.
  Trigger: Task completion, session end, error patterns, "reflexioná", "aprendé de esto".
license: Apache-2.0
metadata: author: gentleman-programming, version: "2.1"
---

## CLOSED LOOP (Hermes-style)
**Observe → Reflect → Optimize → Apply** — auto after EVERY task.

### Per-Task (after done/listo/next)
1. **CAPTURE**: worked? failed? non-obvious? → Engram
2. **EXTRACT**: reusable? → `skill-creator` or update SKILL.md
3. **EVALUATE**: error root cause → `immune-system` + prevention rule
4. **APPLY**: update behavior (Engram + skill + AGENTS.md if general)
5. **SCORE**: `auto-metrics` (6 dims) — always
6. **IMMUNIZE**: if error or <7 → anti-pattern + AGENTS.md Rules

### Periodic (~5 tools or after major task)
1. **SELF-CHECK**: consistent? repeating? underused skills?
2. **AUTO-IMPROVE**: skill to create/update → delegate `skill-creator`
3. **VERIFY**: measurable? (less errors, faster, concise)

## Skill Creation Triggers
| Pattern | Action |
|---------|--------|
| Same fix 2+ times | Create skill with pattern |
| Non-obvious gotcha | Doc in skill/update existing |
| User corrected 2x | Recovery-skill or update protocol |
| Repeated complex workflow | Workflow skill |
| Pattern across 3+ files | Extract to reusable skill |

## Checkpoint (every major interaction)
```
├─ Quality: solved problem?
├─ Efficiency: too many tokens? verbose?
├─ Learning: didn't know before?
├─ Reusability: need again? → skill?
└─ Improvement: differently next time?
```

## Type Reflection
- **Coding**: pattern? maintainable? tested?
- **Troubleshoot**: enough info? correct diagnosis? root cause?
- **Design**: reqs understood? tradeoffs? scalable?
- **Skill**: deserves own? update existing?

## Frustration Signals
"ya te dije" · "no es eso" · "otra vez" · short tone
→ STOP → acknowledge → diagnose root → LEARN → update prevention

## Commands
```bash
# Reflect after task
mem_save(type="learning", content="**What**: ...\n**Learned**: ...")
# If pattern: delegate(skill-creator) or edit SKILL.md
```
