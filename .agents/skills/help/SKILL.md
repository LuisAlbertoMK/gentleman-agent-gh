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

---

> See [reference.md](docs/skills/help/reference.md) for extended details, examples, and detailed patterns.