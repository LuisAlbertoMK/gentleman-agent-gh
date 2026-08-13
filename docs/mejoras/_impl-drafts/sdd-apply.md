---
name: sdd-apply
description: "Implement SDD tasks from specs and design. Trigger: orchestrator launches apply for one or more change tasks."
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD apply, implement SDD, code change, SDD implementation, apply tasks"
  version: "3.0"
  delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-apply` sub-agent. Executor -> run directly.

## Input
Change, task(s), artifact store (`engram|openspec|hybrid|none`), status (`sdd-status-contract.md`), delivery (`ask-on-risk|auto-chain|single-pr|exception-ok`), PR slice or `size:exception`.

## Persistence (sdd-phase-common B+C)
- engram: read `sdd/{change}/proposal|spec|design|tasks`; mark via `mem_update`; save `apply-progress`
- openspec: `openspec-convention.md`; mark `[x]` in `tasks.md`
- hybrid: both · none: return progress only

## Status Guard
| State | Action |
|---|---|
| blocked | STOP + return `blocked` + missing artifacts |
| all_done | No edits; return `success` + `next: sdd-verify/sdd-archive` |
| ready | Proceed on assigned pending tasks only |

Use `contextFiles`/`artifactPaths`. `workspace-planning` + empty roots -> STOP (repos read-only); roots -> edit only under them.

## Steps
1. Load skills (Section A).
2. **Read context**: confirm `applyState: ready`; read contextFiles, specs (WHAT), design (HOW), existing code, config conventions.
2a. **Review workload**: `400-line budget risk: High` OR `Chained PRs recommended: Yes` OR `Decision needed: Yes` -> confirm `auto-chain` (Chain strategy), `exception-ok` (maintainer only), `single-pr` (`size:exception` only); else STOP + `blocked`.
2b. **Previous progress**: `mem_search("sdd/{change}/apply-progress")` -> `mem_get_observation` -> skip completed -> first incomplete. Save: MERGE prior + new. CRITICAL: orchestrator-said-exists -> MUST read.
3. **Resolve mode**: `strict_tdd` (true + runner) -> load `strict-tdd.md`; else step 4. Resolve: engram `testing-capabilities` -> openspec `config.yaml` -> fallback. Strict: TDD Cycle Evidence per task (RED->GREEN->REFACTOR) REQUIRED; missing = FAILED. ALL modes - Work Unit Evidence: test+result (cmd, exit, counts), harness+result (N/A w/ reason), rollback boundary (no unrelated changes). Threat-matrix -> RED test before production.
4. **Implement**: read task -> spec scenarios -> design -> patterns -> write code -> mark `[x]` -> note issues.
5. **Persist + return**: Section C; save `apply-progress` (key `sdd/{change}/apply-progress`); confirm `[x]`. Section D: Completed, Files Changed, TDD Evidence (strict), Deviations, Issues, Remaining, PR Boundary, Status.

## Rules
- English artifacts. Specs = acceptance criteria - read before coding
- Follow design decisions; freelancing -> note as deviation. Match project patterns
- Structured status only; never infer from conversation
- STOP: blocked, unsafe actionContext, outside allowedEditRoots, no workload decision
- openspec: mark `[x]` as you go (internal todos != completion)
- `rules.apply` from config.yaml; follow loaded skills