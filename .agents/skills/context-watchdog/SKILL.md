---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "3.0"
  changelog: "3.0: Karpathy compressed (4.5→2.8KB) · 2.4: prior"
---
<!-- karpathy-compressed: 2026-07-10 -->

# Context Watchdog

## Rules
1. **Act early**: Trigger compression at ORANGE (60%), never wait for RED (80%)
2. **L1 first**: Always start at L1 (saves 60-70%) before escalating
3. **Drift check**: First drift signal → force YELLOW + L1 immediately
4. **Same-file cap**: 3+ consecutive edits → STOP, summarize, commit, re-read fresh
5. **Checkpoint**: Every 25 tool calls → `mem_save(topic_key=checkpoint/session-state)`
6. **Don't repeat**: Same point 2x or hallucination → force RED, break session

**Trigger conditions**: Win% > 60% · Hallucinations/repetition · User says "compress"/"break" · Same file 3+ edits · ~8 messages without compression

## Token Budgets

| Model | Total | YELLOW (40%) | ORANGE (60%) | RED (80%) |
|-------|-------|-------------|-------------|-----------|
| Sonnet4/GPT-4o/Haiku4 | 200K | >120K | >140K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >700K | >800K |

Each skill load ~200 tokens. Recompute budget every 25 tool calls.

## Compression Levels

| Level | Trigger | Action | Savings |
|-------|---------|--------|---------|
| **L1** | ~8 msgs / ~15 tool calls | Oldest block ≥8 msgs → one-page summary | 60-70% |
| **L2** | ~20 msgs / ≥3 L1s | Key decisions → 1-2 lines + Engram obs ID | 40-50% |
| **L3** | YELLOW+ | 1-liner/topic + `Ref: engram-obs-{id}`. Still YELLOW → mem_save + break | 80-90% |

## Zones

| Zone | Usage | Action |
|------|-------|--------|
| GREEN | <40% | Normal, L1 every ~8 messages |
| YELLOW | 40-60% | L1+L2, selective drop of verbose sections |
| ORANGE | 60-80% | L2 on raw + L3 on L1s, drop disclaimers, karpathy-loop, engram IDs. **Compact at 70%** |
| RED | >80% | `mem_save` state → `session_summary` → new session + 3-line handoff |

## Drift Detection

**Signals**: User re-reads same content, re-states same question, `"como te dije"`, `"as I mentioned"` referencing something that wasn't said.
**Action**: Force YELLOW, trigger L1 immediately. **65% of failures are drift, not exhaustion.**

## Decision Tree

```
Tokens% < Turns# → Action
<40%       <8    → Normal
<40%       ≥8    → L1 compression
40-60%     ≥20   → L1 + L2 compression
60-80%     any   → L2 + L3 + compaction at 70%
>80%       any   → mem_save + session break
```

## Stale Content Detection (DCP)

**30-40% waste = stale content, not excess.** Prune protocol at L1: scan >25 calls ago · Before L2: check engram supersedes · Pre-commit: verify file re-reads after edit.

| Signal | Action |
|--------|--------|
| Stale ref (file A read, B edited, still ref A) | "Re-read before using" |
| Superseded decision (`mem_save` X, user said Y) | Check engram → L1 + update |
| Echo chamber (re-stating own output) | Force YELLOW + fresh observation |
| Chunk >50 calls without re-read | Exclude from next summary |
| Repeated quote (same excerpt 2+) | Keep only freshest copy |

## Signals That Force RED

- Repeating same point 2+ times
- `"as I mentioned"` referencing something that never happened
- Self-contradiction across messages
- User says `"ya te dije"` / `"como te dije"` incorrectly

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Waiting for RED before acting | Compact at 70% (ORANGE) |
| Ignoring drift signals | Force YELLOW + L1 on first drift |
| Editing same file 5+ times without summary | Summarize + commit after 3 edits |
| Skipping L1, going straight to L2 | Always start at L1 |
| Not saving state before RED break | `mem_save` before breaking |
