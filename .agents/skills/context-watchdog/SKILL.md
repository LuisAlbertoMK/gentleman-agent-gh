---
name: context-watchdog
description: "Monitor context window usage — YELLOW/RED zones, hallucination detection, session break recommendations"
triggers: "Context >100K tokens, context explosion"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: Agent detects context growing, >100K tokens, repeated hallucinations, or "context" mention.
## WhenContext growing Â· Window >60% full Â· Hallucinations/repetition Â· User: "contexto", "resumÃ­", "compress", "session break" Â· Same file 3+ edits
## Token Budget| Model | Window | YELLOW (>60%) | RED (>80%) ||-------|--------|---------------|------------|| Sonnet 4 / GPT-4o | 200K | >120K | >160K || Gemini 2.5 Pro | 1M | >600K | >800K || Haiku 4 / GPT-4o-mini | 200K | >120K | >160K |
## Zones
### YELLOW (60-80%)- Drop disclaimers, transitions, verbose explanations- Use karpathy-prompt level (compact)- No echoing user's question- Reference Engram ID, not repeat content
### RED (>80%)- `mem_save` current state (file/task/pending)- `mem_session_summary` to persist- Suggest new session + 3-line handoff
## Hallucination/Repetition SignalsAgent repeats suggestion 2+ times Â· "as I mentioned before" + wrong info Â· Self-contradiction Â· User: "ya te dije", "lo mismo" â†’ FORCE RED ZONE.
## Same-file Edit Limit3+ consecutive edits â†’ stop, summarize, suggest commit/save, re-read file fresh.
## Decision Tree
```Context check:â”œâ”€â”€ <60% â†’ NORMALâ”œâ”€â”€ 60-80% â†’ YELLOW: lean responses, drop verbose, short answersâ””â”€â”€ >80% â†’ RED: mem_save + summary + recommend session break    â””â”€â”€ Continue? â†’ ULTRA-LEAN mode```
## Commands
```bash# mem_save before break:mem_save(title="Session state {task}", content="**What**: ...")mem_session_summary(content="
## Goal\n...")
```
## Resources- **Lean mode**: [lean-context/](../lean-context/SKILL.md)- **Token cutting**: [karpathy-loop/](../karpathy-loop/SKILL.md)- **State persistence**: [code-memory/](../code-memory/SKILL.md)
