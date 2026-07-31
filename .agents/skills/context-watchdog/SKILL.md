---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
---

## When to Use
Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection

<!-- karpathy-compressed: 2026-07-10 -->
# Context Watchdog

## Rules
1. Compress at ORANGE (60%), never RED (80%)
2. Always start L1 (60-70%) before escalating
3. First drift → force YELLOW + L1 immediately
4. 3+ edits same file → STOP, summarize, commit, re-read
5. Every 25 calls → `mem_save(topic_key=checkpoint/session-state)`
6. Same point 2x or hallucination → force RED, break session

## Budgets + Zones

| Model | Total | YELLOW 40% | ORANGE 60% | RED 80% |
|-------|-------|-----------|-----------|---------|
| Sonnet4/GPT-4o/Haiku4 | 200K | >120K | >140K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >700K | >800K |

| Zone | Action |
|------|--------|
| GREEN <40% | Normal, L1 every ~8 msgs |
| YELLOW 40-60% | L1+L2, drop verbose |
| ORANGE 60-80% | L2 raw + L3 L1s, **compact at 70%** |
| RED >80% | `mem_save` → `session_summary` → new session |

## Compression Levels

| L | Trigger | Action | Savings |
|---|---------|--------|---------|
| **L1** | ~8 msgs / ~15 calls | Oldest block ≥8 msgs → summary | 60-70% |
| **L2** | ~20 msgs / ≥3 L1s | Decisions → 1-2 lines + Engram ID | 40-50% |
| **L3** | YELLOW+ | 1-liner/topic + `Ref: engram-obs-{id}` | 80-90% |

```
Tokens% < Turns# → Action
<40%  <8 → Normal | <40% ≥8 → L1 | 40-60% ≥20 → L1+L2
60-80% any → L2+L3 compact@70% | >80% any → mem_save + break
```

## Stale Content Detection (DCP)
**30-40% waste = stale, not excess.** Prune at L1: scan >25 calls old · Before L2: check engram supersedes · Pre-commit: verify file re-reads.

| Signal | Action |
|--------|--------|
| Stale ref (A read, B edited, still ref A) | Re-read before using |
| Superseded decision (`mem_save` X, user Y) | Check engram → L1 + update |
| Echo chamber (re-stating own output) | Force YELLOW + fresh observation |
| Chunk >50 calls no re-read | Exclude from next summary |
| Repeated quote (same excerpt 2+) | Keep only freshest copy |

## Drift + Force-RED
**65% failures = drift.** Drift: re-reads same content, re-states question, references unsaid → force YELLOW + L1.
**Force-RED**: same point 2x · self-contradiction · "as I mentioned" referencing nothing
