---
name: help
description: "Explain Ralph Loop plugin and available commands"
triggers: "help, ralph help, commands, available commands, what can you do, /help"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2500
---

## When to Use
Explain Ralph Loop plugin and available commands

## Core Commands
- **/ralph-loop `<task>`**: Iterative loop. Auto-continues until `<promise>DONE</promise>`.
- **/cancel-ralph**: Cancel active loop.

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

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "explicar comandos sin SHORTCUTS.md" | comando descrito sin verificar SHORTCUTS.md file:line | validar cada comando contra SHORTCUTS.md + SKILL.md trigger file:line |
| "inventar shortcuts" | shortcut no existe en SHORTCUTS.md sugerido como real | grep SHORTCUTS.md file:line antes de listar cualquier shortcut |
| "asumir routing sin verificar T-level" | T1-T4 routing descrito sin cotejar help ## Routing | verificar T-level con help ## Routing + execution-mode file:line |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Cross-Refs: ralph-loop | cancel-ralph | opencode-model-router | context-watchdog | immune-system | session-resume | engram-protocol

---

> See [reference.md](docs/skills/help/reference.md) for extended details, examples, and detailed patterns.

