---
name: cancel-ralph
description: Cancel active Ralph Loop
triggers: "cancel ralph, stop loop, cancel loop, ralph stop, end loop"
changelog: docs/ciclos/cycle28-20260815.md
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

## Refs
ralph-loop · recovery-protocol