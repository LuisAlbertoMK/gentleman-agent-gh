---
name: sdd-apply
description: "Implement SDD tasks from specs and design. Trigger: orchestrator launches apply for change tasks."
triggers: "SDD apply, implement SDD, code change, SDD implementation, apply tasks"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: ORCHESTRATOR → STOP, delegate to `sdd-apply` sub-agent. Executor: execute directly.

Change name, task(s), store (`engram|openspec|hybrid|none`), status (`sdd-status-contract.md`), delivery (`ask-on-risk|auto-chain|single-pr|exception-ok`), PR slice / `size:exception`.

- **engram**: read `sdd/{change}/proposal\|spec\|design\|tasks`; mark via `mem_update`; save `apply-progress`
- **openspec**: `openspec-convention.md`; mark `[x]` in `tasks.md`
- **hybrid**: both. **none**: progress only.

| State | Action |
|---|---|
| `blocked` | STOP + return `blocked` + missing artifacts |
| `all_done` | No edits; return `success` + `next: sdd-verify\|sdd-archive` |
| `ready` | Proceed on assigned pending tasks only |
- Read from `contextFiles`/`artifactPaths`, not fixed filenames.
- `workspace-planning` + empty `allowedEditRoots` → STOP (read-only).
- `allowedEditRoots` present → edit only under roots.

### 1: Load Skills — §A of `sdd-phase-common.md`
### 2: Read Context — `applyState: ready`; read `contextFiles`, specs (WHAT), design (HOW), code (patterns), `config.yaml` (conventions)
#### 2a: Enforce Review Workload
`400-line budget risk: High` / `Chained PRs recommended: Yes` / `Decision needed: Yes` → confirm `auto-chain` (`Chain strategy`: `stacked-to-main`|`feature-branch-chain`), `exception-ok` (maintainer acceptance), `single-pr` (only `size:exception`); none → STOP + `blocked`
#### 2b: Read Previous Apply-Progress
`mem_search("sdd/{change}/apply-progress")` → `mem_get_observation` → skip completed → first incomplete; save: MERGE prior + new. CRITICAL: orchestrator says prior progress exists → MUST read.

### 3: Resolve Mode
- `strict_tdd` (true+runner) → STRICT TDD → load `skills/sdd-apply/strict-tdd.md`; else Standard → Step 4
- Resolve: engram `mem_search("sdd/{project}/testing-capabilities")` → openspec `config.yaml` → project files
- Strict TDD: MUST produce TDD Cycle Evidence (RED→GREEN→REFACTOR per task); missing = FAILED
- All modes — Work Unit Evidence (mandatory): focused test + result (smallest cmd, exit, counts); runtime harness + result (`N/A` only with reason); rollback boundary (revertable, no unrelated changes); threat-matrix → RED test before production

### 4: Implement — task → spec scenarios → design → patterns → code → mark `[x]` → note issues

### 5: Persist + Return — §C of `sdd-phase-common.md`; save `apply-progress` (topic_key: `sdd/{change}/apply-progress`); re-read tasks, confirm `[x]`. Return per §D: Completed, Files Changed, TDD Evidence (strict), Deviations, Issues, Remaining, Workload/PR Boundary, Status

- Artifacts: English; specs = acceptance criteria, read before coding; follow design (freelancing → deviation); match patterns; s
