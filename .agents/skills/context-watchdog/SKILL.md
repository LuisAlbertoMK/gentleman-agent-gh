---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1618
---

## When to Use
Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection.

## Rules
1. Compress at ORANGE (60%), never RED (80%). 2. Always start L1 (60-70%) before escalating. 3. First drift → force YELLOW + L1 immediately. 4. 3+ edits same file → STOP, summarize, commit, re-read. 5. Every 25 calls → `mem_save(topic_key=checkpoint/session-state)`. 6. Same point 2x or hallucination → force RED, break session.

## Budgets + Zones
| Model | Total | YELLOW 40% | ORANGE 60% | RED 80% |
|---|---|---|---|---|
| Sonnet4/GPT-4o/Haiku4 | 200K | >120K | >140K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >700K | >800K |

| Zone | Action |
|---|---|
| GREEN <40% | Normal, L1 every ~8 msgs |
| YELLOW 40-60% | L1+L2, drop verbose |
| ORANGE 60-80% | L2 raw + L3 L1s, **compact at 70%** |
| RED >80% | `mem_save` → `session_summary` → new session |

## Drift + Force-RED
65% failures = drift: re-reads same content, re-states question, references unsaid → force YELLOW + L1. Force-RED: same point 2x · self-contradiction · "as I mentioned" referencing nothing.

## Anti-Patterns
Compress at RED (recovery > savings; rule 1) · Jump to L3 skipping L1 (destroys chain) · Summarize stale instead of pruning (compounds drift)
## Reference
> docs/skills/context-watchdog/reference.md
