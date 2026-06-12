---
name: context-watchdog
description: > Runtime context monitor. Detects context explosion and triggers compression or session break.
  Trigger: Agent detects context growing, >100K tokens, repeated hallucinations, or "context" mention.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## When
Context growing · Window >60% full · Hallucinations/repetition · User: "contexto", "resumí", "compress", "session break" · Same file 3+ edits

## Token Budget
| Model | Window | YELLOW (>60%) | RED (>80%) |
|-------|--------|---------------|------------|
| Sonnet 4 / GPT-4o | 200K | >120K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >800K |
| Haiku 4 / GPT-4o-mini | 200K | >120K | >160K |

## Zones

### YELLOW (60-80%)
- Drop disclaimers, transitions, verbose explanations
- Use karpathy-prompt level (compact)
- No echoing user's question
- Reference Engram ID, not repeat content

### RED (>80%)
- `mem_save` current state (file/task/pending)
- `mem_session_summary` to persist
- Suggest new session + 3-line handoff

## Hallucination/Repetition Signals
Agent repeats suggestion 2+ times · "as I mentioned before" + wrong info · Self-contradiction · User: "ya te dije", "lo mismo" → FORCE RED ZONE.

## Same-file Edit Limit
3+ consecutive edits → stop, summarize, suggest commit/save, re-read file fresh.

## Decision Tree
```
Context check:
├── <60% → NORMAL
├── 60-80% → YELLOW: lean responses, drop verbose, short answers
└── >80% → RED: mem_save + summary + recommend session break
    └── Continue? → ULTRA-LEAN mode
```

## Commands
```bash
# mem_save before break:
mem_save(title="Session state {task}", content="**What**: ...")
mem_session_summary(content="## Goal\n...")
```

## Resources
- **Lean mode**: [lean-context/](../lean-context/SKILL.md)
- **Token cutting**: [karpathy-loop/](../karpathy-loop/SKILL.md)
- **State persistence**: [code-memory/](../code-memory/SKILL.md)
