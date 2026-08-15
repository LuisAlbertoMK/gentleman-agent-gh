---
name: mini-orchestrator
description: "BabyAGI-style loop (Execution→Task Creation→Prioritization) with async fire-and-forget handoff"
author: Gentle AI
version: 1.1.0
mode: primary
delegate_only: false
priority: standard
triggers: "mini-orchestrator, BabyAGI, task loop, async delegation, fire-and-forget, background monitor, agent chain, dependent tasks"
---

# mini-orchestrator

BabyAGI-style delegation loop for multi-step subagent work: **EXECUTION → TASK CREATION → PRIORITIZATION**, with an async fire-and-forget handoff so the orchestrator never blocks.

## When to use

- Long-running multi-step work where blocking is unacceptable
- Chains of dependent subagent tasks (task N+1 depends on N's output)
- Background improvement/refactor/analysis with a bounded horizon

## Workflow

1. **EXECUTION** — run current task. Delegate per `opencode-model-router` (routing table + security gate).
2. **TASK CREATION** — analyze result; derive next tasks from outcome. Use 4-field return contract as source.
3. **PRIORITIZATION** — rank new tasks (impact × effort × risk); pick top-1 as next step.
4. Repeat until `convergence_check` passes or `max_iterations` reached.

## Guardrails (hard caps)

| Cap | Default | Purpose |
|---|---|---|
| `max_iterations` | 10 | Hard loop cap — exhaust → stop, do NOT continue |
| `max_tokens` | per-step budget | Per-task cap; delegate rest to subagent |
| `convergence_check` | result-delta < threshold OR queue empty | Stop on convergence; never loop on identical output |
| `dedup` | task id = hash(prompt) | Skip already-executed/queued tasks |

## Tiered approval (over `auto-sub` deny floor)

- **AUTO**: execute without approval — `auto-sub` template (deny floor + `task: deny`). Zero `ask`.
- **LOG**: execute + log to `audit-log.psl`.
- **CONFIRM**: pause → human approval required.

Escalate when touching: credentials, network egress, package installs, `git push --force`, or any destructive op.

## Async handoff (fire-and-forget)

```powershell
scripts\post-delegation-check.ps1 -BaseRef HEAD -AllowedPaths "src/*" -Async
# returns immediately; monitor writes {BaseRef}.async-result.json
$r = Get-Content HEAD.async-result.json -Raw | ConvertFrom-Json
if (-not $r.passed) { # FAIL — review before proceeding }
```

`monitor-subagent.ps1` polls (15s default) running check-subagent-output + validate-write-scope. Writes result when git status stable (2 identical polls) or 300s deadline.

## Refs

- `adr/ADR-022`, `adr/ADR-024` — auto-sub deny floor
- `adr/ADR-031` — async delegation decision record
- `delivery-harness` — multi-agent orchestration (fan-out, not loops)
- `ralph-loop` — auto-continue for a SINGLE task
- `opencode-model-router` — delegation targets + fallback chain

## Anti-Patterns

- Blocking on a subagent when async handoff is available
- Ignoring `convergence_check` → unbounded loops
- Trusting delegation without reading `{BaseRef}.async-result.json`
- Delegating sensitive data to subagents (security gate: DIRECT)
- Looping past `max_iterations`
