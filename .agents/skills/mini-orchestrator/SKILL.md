---
name: mini-orchestrator
description: "BabyAGI loop (Execution→Task Creation→Prioritization) with async fire-and-forget handoff"
triggers: "mini-orchestrator, BabyAGI, task loop, async delegation, fire-and-forget, background monitor, agent chain, dependent tasks"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1990
---
# mini-orchestrator
BabyAGI delegation loop: **EXECUTION → TASK CREATION → PRIORITIZATION**, async fire-and-forget.
## When to use
Multi-step blocking-unacceptable work · dependent chains (N+1 needs N's output) · bounded-horizon background work.
## Workflow
1. **EXECUTION** — run task. Delegate per `opencode-model-router`. 2. **TASK CREATION** — derive next from outcome (4-field contract). 3. **PRIORITIZATION** — rank (impact×effort×risk); top-1. 4. Repeat until `convergence_check` or `max_iterations`.
## Guardrails (caps)
`max_iterations`=10 hard cap · `max_tokens` per-step · `convergence_check`=delta<threshold OR queue empty · `dedup`=hash(prompt)
## Approval tiers (over `auto-sub` deny floor)
- **AUTO**: `auto-sub` template (deny floor + `task: deny`), no approval.
- **LOG**: execute + log `audit-log.psl`.
- **CONFIRM**: pause → human approval.
Escalate: credentials, network egress, package installs, `git push --force`, destructive ops.
## Async handoff
`post-delegation-check.ps1 -Async` returns immediately → writes `{BaseRef}.async-result.json`; read `.passed` first. `monitor-subagent.ps1` polls (15s) + write-scope validation; writes when git stable (2 polls) or 300s.
## Refs
`adr/ADR-022`,`adr/ADR-024` deny floor · `adr/ADR-031` async delegation · `delivery-harness` fan-out · `ralph-loop` · `opencode-model-router` fallback
## Anti-Patterns
Blocking when async available · ignoring `convergence_check` · not reading `{BaseRef}.async-result.json` · delegating sensitive data (security: DIRECT) · looping past `max_iterations`.
## Reference
Async code + Examples + Testing → docs/skills/mini-orchestrator/reference.md
