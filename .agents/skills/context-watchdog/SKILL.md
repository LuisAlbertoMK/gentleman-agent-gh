---
name: context-watchdog
description: "Monitor context window — Recursive Summary Compression (L1/L2/L3), YELLOW/RED zones, hallucination detection"
triggers: "Context explosion, compress, compression schedule, session break"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: karpathy compress"
---
## When: Window>60% · Hallucinations/repetition · "context/compress/break" · Same file 3+ edits · ~8 msgs
## Token Budget: Sonnet4/GPT-4o/Haiku4 200K win → YELLOW>120K RED>160K · Gemini 2.5 Pro 1M → >600K >800K
## Recursive Compression (proactive)
- **L1** (~8 msgs/~15 calls): Oldest block≥8 msgs → summary. -60-70%.
- **L2** (~20 msgs/3+ L1s): Key decisions 1-2 lines + engram-obs-id. -40-50% of L1s.
- **L3** (YELLOW+): 1-liner + "Ref: engram-obs-{id}". -80-90%. Still YELLOW? mem_save + break.
## Zones
**GREEN (<60%)**: Normal · L1 every ~8 msgs
**YELLOW (60-80%)**: Force L2 raw + L3 L1s · drop disclaimers · karpathy-prompt · engram IDs. Still YELLOW? mem_save+break
**RED (>80%)**: mem_save state · session_summary · new session + 3-line handoff · ultra-lean
## Signals: Repeat 2x · "as I mentioned" wrong · Self-contradiction · "ya te dije" → FORCE RED
## Same-file Edit Limit: 3+ → stop, summarize, commit, re-read fresh
## Decision Tree
<40% <8 msgs→Normal | <60% ≥8→L1 | 40-60% ≥20→L1+L2 | ≥60%→L2+L3→ultra-lean | >80%→mem_save+break
## Checkpoint: Every 25 tool calls → auto-save state snapshot
Trigger: After every ~25 tool calls (count from `context-watchdog` self-check, or when you see "checkpoint" in agent-protocol B self-check)
Action: `mem_save(topic_key=checkpoint/session-state, type=checkpoint)` with current task state, what's done, what's next, key decisions.
Why: Survives compaction — replay last checkpoint + mem_context instead of starting blind.
## Cross-Refs: Schedule in AGENTS.md B | Lean: lean-context | Tokens: karpathy-loop | State: code-memory
## COMPRESSION EXAMPLE
```
L1: ~8 msgs → full summary block (−60-70%)
L2: ~20 msgs → 1-2 line decisions + engram IDs (−40-50%)
L3: YELLOW>60% → 1-liner + "Ref: engram-obs-{id}" (−80-90%)
```
## HALLUCINATION DETECTION
- Repeats same info twice → suspect compression overdue
- "As I mentioned" + wrong → FORCE RED, mem_save + break
- Self-contradiction between early and late context → flag immediately
- Same file edited 3+ times without commit → stop, summarize, commit, re-read
