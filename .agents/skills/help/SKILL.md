---
name: help
description: "Explain Ralph Loop plugin and available commands"
triggers: "help, ralph help, commands, available commands, what can you do, /help"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Explain Ralph Loop plugin and available commands

## Core Commands
- **/ralph-loop `<task>`**: Iterative loop. Auto-continues until `<promise>DONE</promise>`.
- **/cancel-ralph**: Cancel active loop.

## How It Works
1. Start → state `.opencode/ralph-loop.local.md`
2. Loop: plugin checks `<promise>DONE</promise>` on idle
3. Continue: "Continue from where you left off"
4. Stop: DONE or max 100 iterations
5. Cleanup: delete state file

**Signal**: `<promise>DONE</promise>` only when truly complete.
**State**: `.opencode/ralph-loop.local.md` (`.gitignore` it): `active:true iteration:3 maxIterations:100 sessionId:ses_abc123` + task prompt

## Routing
- **T1** (GREEN, 1 file, known) → `gentleman-quick`
- **T2** (YELLOW, 2-4 files, ambiguous) → `gentleman-deep` / `gentleman-codex`
- **T3** (ORANGE, 5+ files, arch) → parallel units
- **T4** (RED, schema/auth/API contract) → STOP, ask user
- **Domain** (opencode-model-router): Security → `gentleman-security`, Infra → `gentleman-infra`, Frontend → `gentleman-frontend`. Domain overrides file-count.

## Common Tasks
- First-time: `QUICKSTART.md` → `scripts/health-check-system.ps1`
- Health: `scripts/health-check-system.ps1`
- Circuit breaker: `.learnings/mcp-circuit-state.json` (CLOSED/OPEN 60s/HALF_OPEN)
- Dream: `!dream` / `!dream quick`
- Close: `!close` (BITACORA + git + protected + `mem_session_summary`)
- Patterns: `scripts/session-miner.ps1 -Mode scan -Json`

## Troubleshooting
- **MCP timeout**: `.learnings/mcp-circuit-state.json` → OPEN wait 60s → `scripts/health-check-system.ps1` → `scripts/lib/mcp-resilience.ps1`
- **Context overflow >80%**: `/compact` / `mem_session_summary` + new session. context-watchdog compress at YELLOW (40%)
- **Agent failure**: check contract → retry narrower → 2x fail → STOP → report
- **Forgets**: `engram_mem_context` → always `mem_session_summary` before compaction
- **Error 3x**: `auto-pattern-detector.ps1` → immune-system → AGENTS.md
- **Script parse**: replace `—` → `--`, `→` → `->`. ASCII only in `.ps1`
- **Full**: `docs/operations/RUNBOOK.md`

## Cross-Refs: ralph-loop | cancel-ralph | opencode-model-router | context-watchdog | immune-system | session-resume | engram-protocol


## Examples

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

## Testing Patterns

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

## Edge Cases

### Edge Case 1: Concurrent Loops
Only one Ralph Loop can run per session. Starting a second loop while one is active will either queue or reject depending on plugin version. Always `/cancel-ralph` first.

### Edge Case 2: State File Corruption
If `.opencode/ralph-loop.local.md` is manually edited or corrupted, the plugin may fail to parse. Delete the file and restart the loop.

### Edge Case 3: Compaction During Loop
If `/compact` runs mid-loop, the loop state persists in the file but agent context is lost. Resume with "Continue from where you left off" to recover.

### Edge Case 4: Network/Plugin Failure
If the plugin crashes or loses connection, the state file remains. On restart, the plugin detects `active:true` and offers to resume or cancel.

## Anti-Patterns

### Anti-Pattern 1: Over-Documenting Known Commands
Listing every shortcut, alias, or command variant in the skill file. The skill should reference the canonical source (SHORTCUTS.md, plugin help) not duplicate it.

### Anti-Pattern 2: Updating Without Verifying Plugin Behavior
Changing the skill documentation without running the actual commands to verify behavior. Always test `/ralph-loop` and `/cancel-ralph` before updating docs.
