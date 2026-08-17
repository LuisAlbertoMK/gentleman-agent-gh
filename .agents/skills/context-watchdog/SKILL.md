---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
changelog: docs/ciclos/cycle28-20260815.md
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

## Examples
Trigger: "compress" / context explosion — start L1, never wait for RED (Rules 1-2):
```bash
# 1. ctx_stats → map % to Budgets+Zones table
# 2. <40% GREEN: L1 every ~8 msgs | 40-60% YELLOW: L1+L2, drop verbose
# 3. 60-80% ORANGE: L2 raw + L3 L1s, compact at 70% | >80% RED: mem_save → session_summary → new session
# 4. Same point restated 2x → force RED immediately (Drift)
```
Expected: `ctx_stats` reports % → zone row dictates action → compress at 70% max, never at RED

## Testing
1. Zone math: run `ctx_stats` at session start → map current % to the Budgets+Zones table → chosen action must match that zone's row.
2. L1 savings: after ≥8 messages, L1-summarize the oldest block → `ctx_stats` before/after must land in the 60-70% savings band (Compression Levels table).
3. Force-RED drill: restate the same point twice → watchdog must flag drift and force RED (`mem_save` → `session_summary` → new session) within 2 turns.

## Anti-Patterns
- Compress at RED instead of ORANGE — the window is already thrashing; recovery cost exceeds savings. Rule 1: compress at 60%, never 80%.
- Jump straight to L3 skipping L1 — destroys the L1→L2→L3 chain; L2 preserves decisions with Engram IDs. Rule 2: always start L1.
- Summarize stale content instead of pruning — 30-40% waste is stale, not excess (DCP); re-summarizing stale blocks compounds drift instead of cutting it.
