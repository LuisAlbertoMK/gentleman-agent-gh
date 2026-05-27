---
name: context-watchdog
description: >
  Runtime context monitor. Detects context explosion and triggers compression or session break.
  Trigger: Agent detects context growing, >100K tokens, repeated hallucinations, or "context" mention.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
Context is growing large · Model window >60% full · Hallucinations or repetition detected · User mentions "contexto", "resumí", "compress", "session break" · Same file edited 3+ times in a row

## Critical Patterns

### 1. Token Budget Monitoring
Track approximate context usage. At each major interaction:
- Check model window size (200K for Sonnet 4, GPT-4o; 1M for Gemini)
- If >60% full → enter YELLOW zone → start conserving
- If >80% full → enter RED zone → suggest compression or session break
```
Token budget per model:
| Model | Window | YELLOW (>60%) | RED (>80%) |
|-------|--------|---------------|------------|
| Sonnet 4 / GPT-4o | 200K | >120K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >800K |
| Haiku 4 / GPT-4o-mini | 200K | >120K | >160K |
```

### 2. Compression Protocol
When in YELLOW zone:
- Drop disclaimers, transitions, verbose explanations from ALL responses
- Use `karpathy-prompt` level responses (compact)
- No echoing back user's question
- Reference past decisions by Engram ID, not by repeating content

When in RED zone:
- Call `mem_save` with current state summary (what file, what task, what's pending)
- Call `mem_session_summary` to persist everything
- Suggest the user start a new session
- BEFORE new session: provide the user with a 3-line handoff to paste

### 3. Hallucination / Repetition Detection
```
Signals:
├── Agent repeats the same suggestion 2+ times
├── Agent says "as I mentioned before" + wrong info
├── Agent contradicts itself across messages
├── User says "ya te dije", "you already said that", "lo mismo de antes"
└── Action: ENTER RED ZONE → force save + suggest session break
```

### 4. Same-file Edit Limit
If the agent has edited the same file 3+ times consecutively:
- Stop and summarize what changed
- Suggest committing or saving progress
- Read the file again fresh (context may have stale version)

## Decision Tree
```
Context check:
├── <60% → NORMAL: no action
├── 60-80% → YELLOW:
│   ├── Enable lean responses (karpathy-prompt mode)
│   ├── Drop all verbose output
│   └── Prefer short answers + code only
└── >80% → RED:
    ├── Save state: mem_save + mem_session_summary
    ├── Report: "Context at ~{N}K/{Window}K — recommend session break"
    ├── Ask user: continue compressed or new session?
    └── If continue → ULTRA-LEAN mode (minimum tokens possible)
```

## Commands
```bash
# Quick context check indicators:
# - Count lines in conversation (rough proxy)
# - Check if agent is repeating itself
# - Check number of consecutive edits to same file
# - Check recent user sentiment (frustration signals)

# Engram save before break:
# mem_save(title="Session state {task}", content="**What**: ...")
# mem_session_summary(content="## Goal\n...")
```

## Resources
- **Lean mode**: [lean-context/](../lean-context/SKILL.md) for ultra-compact responses
- **Token optimization**: [karpathy-loop/](../karpathy-loop/SKILL.md) for prompt cutting tactics
- **Session save**: [code-memory/](../code-memory/SKILL.md) for state persistence patterns
