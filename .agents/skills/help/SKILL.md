---
name: help
description: Explain Ralph Loop plugin and available commands
triggers: "help, ralph help, commands, available commands, what can you do, /help"
license: MIT
metadata:
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial tracked version"
---

# Ralph Loop Help

The Ralph Loop plugin provides auto-continuation for complex tasks in opencode.

## Available Commands

### `/ralph-loop <task>`
Start an iterative development loop that automatically continues until the task is complete.

Example:
```
/ralph-loop Build a REST API with authentication
```

The AI will work on your task and automatically continue until completion.

### `/cancel-ralph`
Cancel an active Ralph Loop before it completes.

Example:
```
/cancel-ralph
```

## How It Works

1. **Start**: `/ralph-loop` creates a state file at `.opencode/ralph-loop.local.md`
2. **Loop**: When the AI goes idle, the plugin checks if `<promise>DONE</promise>` was output
3. **Continue**: If not found, it injects "Continue from where you left off"
4. **Stop**: Loop continues until DONE is found or max iterations (100) reached
5. **Cleanup**: State file is deleted when complete

## Completion Signal

When the task is fully complete, the AI outputs:

```
<promise>DONE</promise>
```

This signals the loop to stop. The AI should ONLY output this when the task is truly complete.

## State File

Located at `.opencode/ralph-loop.local.md` (add to `.gitignore`):

```markdown
---
active: true
iteration: 3
maxIterations: 100
sessionId: ses_abc123
---

Your original task prompt
```

## Credits

- Inspired by [Anthropic's Ralph Wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) plugin for Claude Code
- Standalone extraction from [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

## How Routing Works

Tasks are routed by the orchestrator using two models:

**Quick heuristic** (orchestrator prompt — for fast classification):

| Tier | Scope | Action | Example |
|------|-------|--------|---------|
| **T1** (GREEN) | 1 file, known pattern | `gentleman-quick` | Typo fix, config tweak |
| **T2** (YELLOW) | 2-4 files, some ambiguity | `gentleman-deep` (bugfix) or `gentleman-codex` (new code) | Auth middleware, schema change |
| **T3** (ORANGE) | 5+ files, architecture change | Decompose into parallel units (orchestrator manages) | Refactor module, add feature with DB+API+UI |
| **T4** (RED) | Schema, auth, or API contract change | STOP — ask user to confirm before proceeding | Breaking API change, migration |

**Domain routing** (`opencode-model-router` skill — authoritative): Security → `gentleman-security`, Infra → `gentleman-infra`, Frontend → `gentleman-frontend`, etc. Domain overrides file-count classification. The router skill has the final say.

## Common Tasks

| Task | How |
|------|-----|
| **First-time setup** | Read `QUICKSTART.md` at repo root, then run `scripts/health-check-system.ps1` |
| **Health checks** | `scripts/health-check-system.ps1` — tests MCP servers, scripts, dependencies |
| **Circuit breaker state** | Read `.learnings/mcp-circuit-state.json` — states: CLOSED (healthy), OPEN (blocked 60s), HALF_OPEN (testing) |
| **Manual dreaming** | `!dream` — weekly or after milestones. `!dream quick` for a fast scan |
| **Session close** | `!close` — runs BITACORA log, git status, protected files gate, then `mem_session_summary` |
| **Pattern extraction** | `scripts/session-miner.ps1 -Mode scan -Json` — mines error patterns from session history |

## When Things Go Wrong

| Problem | First step | Full fix |
|---------|------------|----------|
| **MCP timeout / connection refused** | Check circuit breaker: `.learnings/mcp-circuit-state.json` | If OPEN → wait 60s. Persistent → `scripts/health-check-system.ps1`. Use retry/backoff via `scripts/lib/mcp-resilience.ps1` |
| **Context overflow (>80%)** | `/compact` or `mem_session_summary` + new session | Monitor with `context-watchdog` skill; compress at YELLOW (40%) proactively |
| **Agent failure (subagent returns wrong output)** | Check output contract, retry with narrower scope | 2x consecutive failure → STOP delegation, report to user, try different agent or manual |
| **Agent forgets earlier instructions** | `engram_mem_context` to recover session history | Always call `mem_session_summary` before compaction to preserve state |
| **Repeated error (same 3x)** | `auto-pattern-detector.ps1` proposes anti-pattern | Immune-system: detect → diagnose → document → immunize in AGENTS.md |
| **Script parse error (Unicode)** | Replace `—` with `--`, `→` with `->` | Use only ASCII in `.ps1` files |

Full troubleshooting: `docs/operations/RUNBOOK.md`.

## Refs
ralph-loop · cancel-ralph · opencode-model-router · context-watchdog · immune-system · session-resume · engram-protocol · runbook

## Anti-Patterns
Over-document well-known commands · Duplicate ralph-loop/SKILL.md · List every shortcut inline · Update without checking actual plugin behavior · Duplicate RUNBOOK content verbatim
