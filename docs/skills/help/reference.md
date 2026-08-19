# Help — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/help/SKILL.md) for the core commands, routing, and troubleshooting.

---

## Examples (5)

### Example 1: Basic Loop Start
```
/ralph-loop "Refactor the auth middleware to use JWT instead of sessions"
```
Starts an iterative loop that will continue until the task is complete and `<promise>DONE</promise>` is signaled.

### Example 2: Loop with Custom Iterations
```
/ralph-loop "Add comprehensive unit tests for the payment service" --max-iterations 50
```
Limits the loop to 50 iterations instead of the default 100.

### Example 3: Check Loop Status
```
/ralph-loop status
```
Displays current iteration, task prompt, and state file contents.

### Example 4: Cancel Active Loop
```
/cancel-ralph
```
Immediately stops any running Ralph Loop and cleans up the state file.

### Example 5: Resume After Compaction
```
/ralph-loop "Continue from where you left off"
```
Resumes the previous task after a context compaction by reading the state file.

---

## Testing Patterns (3)

### Pattern 1: Smoke Test - Loop Initialization
```bash
# Verify state file creation
/ralph-loop "echo hello"
# Check: .opencode/ralph-loop.local.md exists with active:true
# Cleanup: /cancel-ralph
```

### Pattern 2: Integration Test - Full Cycle
```bash
# Run a complete loop cycle
/ralph-loop "Create a simple test file at /tmp/ralph-test.txt with content 'done'" --max-iterations 5
# Verify: file exists with correct content
# Verify: state file cleaned up (active:false or deleted)
```

### Pattern 3: Edge Case Test - Max Iterations
```bash
# Test loop termination at max iterations
/ralph-loop "This task will never complete" --max-iterations 3
# Verify: loop stops after 3 iterations
# Verify: no infinite loop, graceful exit
```

---

## Edge Cases (4)

### Edge Case 1: Concurrent Loops
Only one Ralph Loop can run per session. Starting a second loop while one is active will either queue or reject depending on plugin version. Always `/cancel-ralph` first.

### Edge Case 2: State File Corruption
If `.opencode/ralph-loop.local.md` is manually edited or corrupted, the plugin may fail to parse. Delete the file and restart the loop.

### Edge Case 3: Compaction During Loop
If `/compact` runs mid-loop, the loop state persists in the file but agent context is lost. Resume with "Continue from where you left off" to recover.

### Edge Case 4: Network/Plugin Failure
If the plugin crashes or loses connection, the state file remains. On restart, the plugin detects `active:true` and offers to resume or cancel.

---

## Anti-Patterns (2)

### Anti-Pattern 1: Over-Documenting Known Commands
Listing every shortcut, alias, or command variant in the skill file. The skill should reference the canonical source (SHORTCUTS.md, plugin help) not duplicate it.

### Anti-Pattern 2: Updating Without Verifying Plugin Behavior
Changing the skill documentation without running the actual commands to verify behavior. Always test `/ralph-loop` and `/cancel-ralph` before updating docs.