# Cancel Ralph — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/cancel-ralph/SKILL.md) for the core cancellation workflow and rules.

---

## Examples (5)

### Example 1: Basic cancellation
```bash
# User decides the loop task is no longer needed
test -f .opencode/ralph-loop.local.md && echo "Active" || echo "No active loop"
grep '^iteration:' .opencode/ralph-loop.local.md
# Output: iteration: 7
rm -f .opencode/ralph-loop.local.md
echo "Ralph loop cancelled at iteration 7 — task was: refactor auth module"
```

### Example 2: Scope change mid-loop
```bash
# Requirements shifted — user wants different approach
test -f .opencode/ralph-loop.local.md && cat .opencode/ralph-loop.local.md | head -5
# Shows: task: "add validation to all endpoints"
# New requirement: "skip validation, add rate limiting instead"
rm -f .opencode/ralph-loop.local.md
echo "Cancelled iteration 3 — scope changed: validation → rate limiting"
```

### Example 3: Stuck loop detection
```bash
# Loop has been on same iteration for 3+ checks
iteration_before=$(grep '^iteration:' .opencode/ralph-loop.local.md)
sleep 30
iteration_after=$(grep '^iteration:' .opencode/ralph-loop.local.md)
if [ "$iteration_before" = "$iteration_after" ]; then
  rm -f .opencode/ralph-loop.local.md
  echo "Ralph loop cancelled — stuck at iteration $iteration_before for 30s"
fi
```

### Example 4: Higher priority interrupt
```bash
# Production issue requires immediate attention
test -f .opencode/ralph-loop.local.md && grep '^task:' .opencode/ralph-loop.local.md
# Output: task: "optimize bundle size"
rm -f .opencode/ralph-loop.local.md
echo "Cancelled — production hotfix takes priority. Loop was at iteration 12 on bundle optimization"
```

### Example 5: Parameter error recovery
```bash
# Loop started with wrong target branch
grep '^params:' .opencode/ralph-loop.local.md
# Output: params: {branch: "main", depth: 100}
# Should have been: branch: "feature/auth"
rm -f .opencode/ralph-loop.local.md
echo "Cancelled at iteration 1 — wrong branch parameter (main vs feature/auth)"
```

---

## Testing Patterns (3)

### Pattern 1: Idempotent cancellation
```bash
# Safe to run multiple times — no error on already-cancelled
for i in {1..3}; do
  test -f .opencode/ralph-loop.local.md && rm -f .opencode/ralph-loop.local.md
  echo "Attempt $i: $(test -f .opencode/ralph-loop.local.md && echo 'still exists' || echo 'cleaned')"
done
# Expected: first attempt cleans, subsequent show 'cleaned'
```

### Pattern 2: State file integrity check
```bash
# Verify state file structure before reading
if test -f .opencode/ralph-loop.local.md; then
  required_fields=("iteration" "task" "started_at")
  for field in "${required_fields[@]}"; do
    grep -q "^$field:" .opencode/ralph-loop.local.md || echo "MISSING: $field"
  done
  grep '^iteration:' .opencode/ralph-loop.local.md
else
  echo "No loop to cancel"
fi
```

### Pattern 3: Concurrent cancellation safety
```bash
# Simulate two agents trying to cancel simultaneously
# Agent 1:
( test -f .opencode/ralph-loop.local.md && rm -f .opencode/ralph-loop.local.md && echo "Agent 1 cancelled" ) &
# Agent 2:
( sleep 0.1; test -f .opencode/ralph-loop.local.md && rm -f .opencode/ralph-loop.local.md && echo "Agent 2 cancelled" ) &
wait
# Expected: exactly one "cancelled" message, no errors
```

---

## Edge Cases (4)

| Edge Case | Behavior | Handling |
|---|---|---|
| Loop file exists but empty/corrupt | `grep` returns nothing | Treat as "unknown iteration", still delete file |
| Multiple `.opencode/ralph-loop.local.md` files (nested dirs) | Ambiguous which loop | Use `find .opencode -name 'ralph-loop.local.md' -type f` to list all |
| Loop file owned by different user/process | Permission denied on `rm` | Check with `ls -l`, use `sudo` if authorized, else escalate |
| Cancellation during active file write by loop | Race condition, partial state | Use `flock` or atomic `mv` pattern: write to `.tmp` then `mv` |

---

## Anti-Patterns (Extended)

| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Force-killing without reading iteration | User loses progress context | Read iteration before deleting |
| Cancelling when no loop active | Wasted operation | Always check with `test -f` first |
| Leaving stale state file | Next loop start may pick up old state | Always `rm -f` the file |
| Aborting without telling user | Confusing, breaks trust | Always explain what was cancelled |
| Cancelling during a write operation | Partial state corruption | Wait for iteration boundary or checkpoint |
| Deleting without verifying it's YOUR loop | Could kill another agent's loop | Check loop metadata (task ID, owner) first |

---

## When to Use

- Task requirements changed mid-loop
- Wrong parameters passed to the loop
- Loop appears stuck (repeating same step)
- Higher priority task needs the context slot

Note: Prefer completing tasks properly with `<promise>DONE</promise>` when possible.

## Refs
ralph-loop · recovery-protocol

## Externalized Sections (ADR-007 compression)
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
