---
name: cancel-ralph
description: Cancel active Ralph Loop
triggers: "cancel ralph, stop loop, cancel loop, ralph stop, end loop"
---

# Cancel Ralph

Stop an active Ralph Loop before completion.

## Overview

Invoke this skill when a `ralph-loop` is running but should stop early — task scope changed, parameters wrong, loop stuck, or higher priority work.

## Rules

1. **Check first**: verify loop is active before attempting cancellation
2. **Read iteration**: report which iteration was reached on cancel
3. **Clean state**: remove the loop state file completely
4. **Notify**: inform user of cancellation + last iteration

## How to Use

```bash
# 1. Check if loop is active
test -f .opencode/ralph-loop.local.md && echo "Active" || echo "No active loop"

# 2. Read current iteration
grep '^iteration:' .opencode/ralph-loop.local.md

# 3. Delete state file
rm -f .opencode/ralph-loop.local.md

# 4. Output confirmation
echo "Ralph loop cancelled at iteration $(grep '^iteration:' .opencode/ralph-loop.local.md 2>/dev/null || echo 'unknown')"
```

## Anti-Patterns

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Force-killing without reading iteration | User loses progress context | Read iteration before deleting |
| Cancelling when no loop active | Wasted operation | Always check with `test -f` first |
| Leaving stale state file | Next loop start may pick up old state | Always `rm -f` the file |
| Aborting without telling user | Confusing, breaks trust | Always explain what was cancelled |

## When to Use

- Task requirements changed mid-loop
- Wrong parameters passed to the loop
- Loop appears stuck (repeating same step)
- Higher priority task needs the context slot

Note: Prefer completing tasks properly with `<promise>DONE</promise>` when possible.

## Refs

- [ralph-loop](../ralph-loop/SKILL.md) — starting and managing Ralph Loops
- [recovery-protocol](../recovery-protocol/SKILL.md) — what to do when things go wrong
