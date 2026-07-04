---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.2"
  changelog: "2.2: aligned zones with review-rules.jsonc (added ORANGE, GREEN<40%)"
---
## WHEN: Win>60% · Hallucinations/repetition · "context/compress/break" · Same file 3+ edits · ~8 msgs
## TOKEN BUDGET: Sonnet4/GPT-4o/Haiku4 200K → YELLOW>120K RED>160K · Gemini 2.5 Pro 1M → >600K >800K
## RECURSIVE COMPRESSION
**L1** (~8msgs/~15calls): Oldest block≥8 → summary. -60-70%.
**L2** (~20msgs/3+L1s): Key decisions 1-2 lines + engram-obs-id. -40-50%.
**L3** (YELLOW+): 1-liner + "Ref: engram-obs-{id}". -80-90%. Still YELLOW → mem_save + break.
## ZONES (aligned with review-rules.jsonc)
**GREEN (<40%)**: Normal · L1 every ~8 msgs
**YELLOW (40-60%)**: L1+L2 compression · selective drop
**ORANGE (60-80%)**: Force L2 raw + L3 L1s · drop disclaimers · karpathy-loop · engram IDs
**RED (>80%)**: mem_save state · session_summary · new session + 3-line handoff · ultra-lean
## SIGNALS: Repeat 2x · "as I mentioned" wrong · Self-contradiction · "ya te dije" → FORCE RED
## SAME-FILE LIMIT: 3+ edits → stop, summarize, commit, re-read fresh
## DECISION TREE: Tokens% < Turns#> → Action<40% <8→Normal | <40% ≥8→L1 | 40-60%≥20→L1+L2 | 60-80%→L2+L3 | >80%→mem_save+break
TALE: Each skill load ~200 tokens. After 25 tool calls (checkpoint), recalc budget.
## CHECKPOINT: Every 25 tool calls → `mem_save(topic_key=checkpoint/session-state, type=checkpoint)` with state, done, next, decisions
## CROSS-REFS: Schedule AGENTS.md B | Lean: lean-context | Tokens: karpathy-loop | State: code-memory
