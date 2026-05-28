---
name: self-reflection
description: > Hermes-style closed learning loop. Auto-reflect after tasks, self-evaluate periodically, create/update skills from experience.
  Trigger: Task completion, session end, error patterns, "reflexioná", "aprendé de esto".
license: Apache-2.0
metadata: author: gentleman-programming, version: "2.0"
---

## CLOSED LEARNING LOOP (Hermes-style)

**Observe → Reflect → Optimize → Apply** — automatic after every significant task.

### PER-TASK: After each significant completion
1. **CAPTURE**: what worked? what failed? what non-obvious learning?
2. **EXTRACT**: is this pattern reusable? → `skill-creator` or update existing SKILL.md
3. **EVALUATE**: any error pattern? → fix root cause, not symptom
4. **APPLY**: update behavior for next task (Engram save + skill patch)

### PERIODIC: Every ~5 tool calls or after major task
1. **SELF-CHECK**: performance consistent? repeating mistakes? underutilized skills?
2. **AUTO-IMPROVE**: identify skill to create/update → delegate to `skill-creator`
3. **VERIFY**: improvement measurable? (less errors, faster, more concise)

### SKILL CREATION TRIGGERS (auto-detect)
| Pattern | Action |
|---------|--------|
| Same fix applied 2+ times | → Create skill with the pattern |
| Non-obvious gotcha discovered | → Document in skill or update existing |
| User corrected you on same thing twice | → Create recovery-skill or update protocol |
| Repeated complex workflow | → Create workflow skill |
| Pattern across 3+ files | → Extract to reusable skill |

## SELF-EVALUATION CHECKPOINT
Every major interaction, ask:
```
┌─ Quality: did I fully solve the problem?
├─ Efficiency: did I use too many tokens? too verbose?
├─ Learning: what didn't I know before this task?
├─ Reusability: will I need this again? → skill?
└─ Improvement: what would I do differently next time?
```

## TYPE REFLECTION
| Type | Check |
|------|-------|
| Coding | Correct pattern? maintainable? tested? |
| Troubleshoot | Enough info? correct diagnosis? root cause documented? |
| Design | Requirements understood? tradeoffs explicit? scalable? |
| Skill | Does this deserve its own skill? update existing? |

## FRUSTRATION SIGNALS
"ya te dije" · "no es eso" · "otra vez" · short tone
→ STOP → acknowledge → diagnose root cause → LEARN → update prevention

## COMMANDS
```bash
# After completing a task, reflect:
mem_save(type="learning", content="**What**: ...\n**Learned**: ...")
# If pattern detected:
# delegate(skill-creator) to create new skill
# or edit existing SKILL.md to capture pattern
```
