---
name: context-watchdog
description: "Monitor context window usage — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection, session break recommendations"
triggers: "Context >100K tokens, context explosion, compress, compression schedule"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
  changelog: "1.1->2.0: added Recursive Summary Compression L1/L2/L3 hierarchy"
---

## When
Context growing | Window >60% | Hallucinations/repetition | User: "context/compress/session break" | Same file 3+ edits | Every ~8 msgs per schedule

## Token Budget
| Model | Window | YELLOW (>60%) | RED (>80%) |
|-------|--------|---------------|------------|
| Sonnet 4 / GPT-4o / Haiku 4 | 200K | >120K | >160K |
| Gemini 2.5 Pro | 1M | >600K | >800K |

## Recursive Summary Compression (proactive — no wait for YELLOW)

### L1 — Raw -> Summary (~8 msgs / ~15 tool calls)
Oldest block >=8 msgs, context <60%. Capture decisions/paths/errors/gotchas. -60-70% of block. Cold path first.

### L2 — Summary -> Compact (~20 msgs / 3+ L1 blocks)
Key decisions only, 1-2 lines/topic, Engram ID for recovery. -40-50% of L1 blocks. Critical content -> "Ref: engram-obs-{id}".

### L3 — Compact -> Reference (YELLOW+)
One-liner/topic -> "Ref: engram-obs-{id}". -80-90%. Still YELLOW after L3? Force mem_save + session break.

## Zones
**GREEN (<60%)**: Normal + L1 every ~8 msgs.
**YELLOW (60-80%)**: Force L2 on raw + L3 on L1/L2. Drop disclaimers/echoing. Use karpathy-prompt. Reference Engram ID. Still YELLOW? mem_save + break.
**RED (>80%)**: mem_save state. mem_session_summary. New session + 3-line handoff. Ultra-lean only.

## Signals: Hallucination/Repetition
Repeat 2x | "as I mentioned" + wrong info | Self-contradiction | User: "ya te dije" -> FORCE RED.

## Same-file Edit Limit
3+ consecutive edits -> stop, summarize, commit, re-read fresh.

## Decision Tree
<40% AND <8 msgs -> NORMAL
<60% AND >=8 msgs -> L1 oldest raw
40-60% AND >=20 msgs -> L1 + L2 eligible L1
60-80% (YELLOW) -> L2 raw + L3 eligible -> ultra-lean
>80% (RED) -> mem_save + summary + break

## Commands
compress(topic: "<topic>", content: [{startId: "mNNNN", endId: "mNNNN", summary: "..."}])
compress(topic: "<topic>", content: [{startId: "bN", endId: "bN", summary: "..."}])
mem_save(title="Session state {task}", content="**What**: ...")
mem_session_summary(content="## Goal\n...")

## Cross-Refs
Schedule: AGENTS.md section B | Lean: lean-context | Token cutting: karpathy-loop | State: code-memory
