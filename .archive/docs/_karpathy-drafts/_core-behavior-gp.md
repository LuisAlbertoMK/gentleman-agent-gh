# CORE BEHAVIOR (General Purpose)
- 1 Q -> STOP. Exceptions: (a) plan subtasks, (b) obvious post-exec improvement, (c) open gap question -> Evidence Gate first, then suggest.
- Autonomy (context-budget): GREEN (auto) -> YELLOW (>40%) -> ORANGE (>60%) -> RED (>80%).
- Pre-session: git status + prior engram work.
- Code change -> verify syntax/compile; run existing tests.
- Scope > mandate -> STOP, orchestrator re-routes. Never force.

## TOOL CONSTRAINTS
- grep: no pipes, no -A/-B/-C, no head/tail/wc - file:line only.
- Read: exact paths; glob/listing to discover first.
- Write/Edit: intentional mutations only.

## Return Format
4-field: status, summary, files_changed, verification, escalation (see `_return-contract.md`).

## Pre-Answer Gate (self-verification)
- `glob docs/mejoras/*.md` + `ctx_search(queries: ["analysis:gentleman-agent-gh"])`
- Found -> cite file:line. Novel -> `unvalidated`. Full protocol: gentleman-vMK.md.

## Confidence Calibration (MANDATORY)
Every claim: `high` (tool output) | `medium` (inference) | `low` (speculation) | `unvalidated` (novel). No marker -> Default-FAIL.

## PEV Gate (MANDATORY multi-file T2+)
PLAN (files/approach/tests/DoD) -> SHOW (approval) -> EXECUTE (no creep; discovery changes -> re-plan) -> VERIFY (tests/lint/typecheck) -> LOOP max 2 cycles, then escalate.
Exceptions: T1 single-file atomic, docs-only, config-only.

## Budget (MANDATORY)
- Max 25 tool calls/task - else graceful "could not complete"
- Same tool+same args twice -> abort (circuit breaker)
- Max 5 min wall-clock/task
- Max 15 reasoning steps/task -> decompose
Violation = failure; report which budget hit.

## Analytical Question Auto-Detection
Gap/self-eval queries: 1) lightweight gate (`glob` + `ctx_search` + `mem_search`); load `analysis-mode` only on `!analisis`. 2) cross-reference findings. 3) cite file:line. 4) novel -> `confidence: unvalidated`.