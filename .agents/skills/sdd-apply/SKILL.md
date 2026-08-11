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

> **ORCHESTRATOR GATE**: You are ORCHESTRATOR → STOP. Delegate to `sdd-apply` sub-agent.
> **Executor Override**: If you ARE the sub-agent, ignore gate. Execute directly.

## Input
Change name, task(s), artifact store mode (`engram | openspec | hybrid | none`), structured status (`sdd-status-contract.md`), delivery strategy (`ask-on-risk | auto-chain | single-pr | exception-ok`), PR slice or `size:exception`.

## Persistence
Per `sdd-phase-common.md` §B+C:
- **engram**: Read `sdd/{change-name}/proposal|spec|design|tasks`; mark via `mem_update`; save `apply-progress`.
- **openspec**: Read `openspec-convention.md`; mark `[x]` in `tasks.md`.
- **hybrid**: Both. **none**: Return progress only.

## Status Guard

| State | Action |
|---|---|
| `blocked` | STOP + return `blocked` + missing artifacts |
| `all_done` | No edits. Return `success` + `next: sdd-verify\|sdd-archive` |
| `ready` | Proceed on assigned pending tasks only |

- Read from `contextFiles`/`artifactPaths`, not fixed filenames.
- `workspace-planning` + empty `allowedEditRoots` → STOP (linked repos = read-only).
- `allowedEditRoots` present → edit only under those roots.

## Steps

### 1: Load Skills
Follow **Section A** from `skills/_shared/sdd-phase-common.md`.

### 2: Read Context
Confirm `applyState: ready`, read all `contextFiles`, specs (WHAT), design (HOW), existing code (patterns), `config.yaml` (conventions).

#### 2a: Enforce Review Workload
If `400-line budget risk: High` or `Chained PRs recommended: Yes` or `Decision needed: Yes` → confirm: `auto-chain` (follow `Chain strategy`: `stacked-to-main` or `feature-branch-chain`), `exception-ok` (only with maintainer acceptance), `single-pr` (only with `size:exception`). No decision → STOP + `blocked`.

#### 2b: Read Previous Apply-Progress
`mem_search("sdd/{change-name}/apply-progress")` → `mem_get_observation` → skip completed → start from first incomplete. On save: MERGE all prior + new. **CRITICAL**: If orchestrator says prior progress exists, MUST read it.

### 3: Resolve Mode
- **strict_tdd** (true + test runner) → STRICT TDD → load `skills/sdd-apply/strict-tdd.md`
- **Standard** (false / no runner) → proceed to Step 4
- Resolve via: engram `mem_search("sdd/{project}/testing-capabilities")` → openspec `config.yaml` → fallback project files.
- **Strict TDD**: MUST produce TDD Cycle Evidence (RED→GREEN→REFACTOR per task). Missing = FAILED.
- **All modes — Work Unit Evidence** (mandatory): Focused test + result (smallest command, exit, counts), Runtime harness + result (`N/A` only with reason), Rollback boundary (revertable without unrelated changes). Threat-matrix → RED test before production.

### 4: Implement
Read task → spec scenarios → design → existing patterns → write code → mark `[x]` → note issues.

### 5: Persist + Return
Follow **Section C** from `skills/_shared/sdd-phase-common.md`. Save `apply-progress` (topic_key: `sdd/{change-name}/apply-progress`). Re-read persisted tasks — confirm `[x]` visible. Return per **Section D**: Completed, Files Changed, TDD Evidence (strict), Deviations, Issues, Remaining, Workload/PR Boundary, Status.

## Rules
- Artifacts: English. Specs = acceptance criteria — read before coding. Follow design decisions (freelancing → note as deviation). Match project patterns. Consume/produce structured status; never infer from conversation.
- STOP on: `blocked`, unsafe `actionContext`, outside `allowedEditRoots`, or no workload decision.
- `openspec`: mark `[x]` as you go (internal todos ≠ completion). Chained/stacked → autonomous one deliverable. Never implement unassigned tasks. Follow loaded skills. Apply `rules.apply` from `config.yaml`.

