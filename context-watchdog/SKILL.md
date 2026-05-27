---
name: context-watchdog
description: >
  Runtime context monitor. Detects context explosion and triggers compression or session break.
  Trigger: Agent detects context growing, >100K tokens, repeated hallucinations, or "context" mention.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
Context growing · Window >60% full · Hallucinations/repetition · User says "contexto/resumí/compress/session break" · Same file edited 3+ times consecutively

## Zones

| Zone | Usage | Action |
|------|-------|--------|
| GREEN | <60% | Normal |
| YELLOW | 60-80% | Lean responses, drop verbose, no echo, ref by Engram ID |
| RED | >80% | Save state (mem_save + session_summary), suggest break, 3-line handoff |

Thresholds: Sonnet4/GPT-4o=200K, Gemini2.5=1M. YELLOW@120K/600K. RED@160K/800K.

## Hallucination/Repetition Detection
Signals → ENTER RED:
- Agent repeats same suggestion 2x+
- Agent says "as I mentioned before" + wrong info
- Agent contradicts itself across msgs
- User: "ya te dije", "you already said that", "lo mismo"
- Action: force save + suggest break

## Same-file Edit Limit
3+ consecutive edits to same file → stop, summarize, suggest commit. Re-read file fresh.

## Quick Commands
```bash
# Rough check: line count, repetition, edit frequency, user sentiment
# Save before break:
# mem_save + mem_session_summary
```

## Resources
- **Lean mode**: [lean-context/](../lean-context/SKILL.md)
- **Token cutting**: [karpathy-loop/](../karpathy-loop/SKILL.md)
- **State persist**: [code-memory/](../code-memory/SKILL.md)
