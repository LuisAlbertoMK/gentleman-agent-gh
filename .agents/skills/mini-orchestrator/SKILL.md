---
name: mini-orchestrator
description: "BabyAGI-style loop (Execution→Task Creation→Prioritization) with async fire-and-forget handoff"
author: Gentle AI
version: 1.2.0
mode: primary
delegate_only: false
priority: standard
triggers: "mini-orchestrator, BabyAGI, task loop, async delegation, fire-and-forget, background monitor, agent chain, dependent tasks"
changelog: docs/ciclos/cycle28-20260815.md
---

# mini-orchestrator

BabyAGI delegation loop: **EXECUTION → TASK CREATION → PRIORITIZATION**, async fire-and-forget.

## When to use
Blocking-unacceptable multi-step work · dependent chains (N+1 needs N's output) · bounded-horizon background work.

## Workflow
1. **EXECUTION** — run task. Delegate per `opencode-model-router` (routing + security gate). 2. **TASK CREATION** — derive next tasks from outcome (4-field contract). 3. **PRIORITIZATION** — rank (impact×effort×risk); pick top-1. 4. Repeat until `convergence_check` or `max_iterations`.

## Guardrails (caps)
| Cap | Default | Purpose |
|---|---|---|
| `max_iterations` | 10 | Hard cap — exhaust → stop |
| `max_tokens` | per-step | Per-task cap; delegate rest to subagent |
| `convergence_check` | result-delta < threshold OR queue empty | Stop on convergence |
| `dedup` | task id = hash(prompt) | Skip executed/queued tasks |

## Approval tiers (over `auto-sub` deny floor)
- **AUTO**: `auto-sub` template (deny floor + `task: deny`), no approval, zero `ask`.
- **LOG**: execute + log to `audit-log.psl`.
- **CONFIRM**: pause → human approval required.
Escalate on: credentials, network egress, package installs, `git push --force`, destructive ops.

## Async handoff (fire-and-forget)
```powershell
scripts\post-delegation-check.ps1 -BaseRef HEAD -AllowedPaths "src/*" -Async
# returns immediately; writes {BaseRef}.async-result.json
$r = Get-Content HEAD.async-result.json -Raw | ConvertFrom-Json
if (-not $r.passed) { # FAIL — review before proceeding }
```
`monitor-subagent.ps1` polls (15s) check-subagent-output + validate-write-scope; writes when git stable (2 identical polls) or 300s.

## Refs
`adr/ADR-022`,`adr/ADR-024` deny floor · `adr/ADR-031` async delegation · `delivery-harness` fan-out · `ralph-loop` single-task · `opencode-model-router` targets/fallback

## Examples
"mini-orchestrator: audit security + apply fixes, max 6 iterations" → `babyagi-loop.ps1 -InitialTask "security audit" -MaxIterations 6` → T1→security-sub (fire-and-forget) → New-TasksFromResult → Sort-TaskQueue → Invoke-TaskAsync → convergence → monitor polls 15s until stable/300s.

## Testing
`Invoke-Pester tests\babyagi-loop.Tests.ps1` → 9/9; `tests\post-delegation-async.Tests.ps1` → 5/5; Async smoke: `post-delegation-check.ps1 -Async` → immediate return; `(Get-Content HEAD.async-result.json | ConvertFrom-Json).passed`.

## Anti-Patterns
Blocking when async available · ignoring `convergence_check` · not reading `{BaseRef}.async-result.json` · delegating sensitive data (security: DIRECT) · looping past `max_iterations`.