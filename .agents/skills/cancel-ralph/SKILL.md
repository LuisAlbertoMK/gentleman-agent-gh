---
name: cancel-ralph
description: Cancel active Ralph Loop
triggers: "cancel ralph, stop loop, cancel loop, ralph stop, end loop"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2454
---

## When to Use
Cancel active Ralph Loop

# Cancel Ralph

Stop an active Ralph Loop before completion.

## Overview

Invoke this skill when a `ralph-loop` is running but should stop early — task scope changed, parameters wrong, loop stuck, or higher priority work.

## Rules

1. **Check first**: verify loop is active before attempting cancellation
2. **Read iteration**: report which iteration was reached on cancel
3. **Clean state**: remove the loop state file completely
4. **Notify**: inform user of cancellation + last iteration

## Anti-Patterns

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Force-killing without reading iteration | User loses progress context | Read iteration before deleting |
| Cancelling when no loop active | Wasted operation | Always check with `test -f` first |
| Leaving stale state file | Next loop start may pick up old state | Always `rm -f` the file |
| Aborting without telling user | Confusing, breaks trust | Always explain what was cancelled |
| Cancelling during a write operation | Partial state corruption | Wait for iteration boundary or checkpoint |
| Deleting without verifying it's YOUR loop | Could kill another agent's loop | Check loop metadata (task ID, owner) first |

## When to Use

- Task requirements changed mid-loop
- Wrong parameters passed to the loop
- Loop appears stuck (repeating same step)
- Higher priority task needs the context slot

Note: Prefer completing tasks properly with `<promise>DONE</promise>` when possible.

---

> See [reference.md](docs/skills/cancel-ralph/reference.md) for extended details, examples, and detailed patterns.

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
ralph-loop · recovery-protocol

