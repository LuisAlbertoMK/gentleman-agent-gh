---
name: sdd-apply
description: "Implement SDD tasks from specs and design."
triggers: "SDD apply, implement SDD, code change"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: ORCHESTRATOR → STOP, delegate to sdd-apply sub-agent. Executor: execute directly.

Input: change name, task(s), store (engram|openspec|hybrid|none), status (sdd-status-contract.md), delivery (ask-on-risk|auto-chain|single-pr|exception-ok), PR slice / size:exception.
- **engram**: read sdd/{change}/proposal|spec|design|tasks; mem_update; save apply-progress
- **openspec**: openspec-convention.md; mark [x] in tasks.md
- **hybrid**: both. **none**: progress only.

| State | Action |
|---|---|
| locked | STOP + locked + missing artifacts |
| all_done | No edits; success + Next: sdd-verify\|sdd-archive |
| ready | Proceed on assigned pending tasks only |

- Read contextFiles/artifactPaths; workspace-planning + empty allowedEditRoots → STOP
- allowedEditRoots present → edit only under roots
- **1 Load Skills** — §A sdd-phase-common.md
- **2 Read Context** — applyState: ready; contextFiles, specs (WHAT), design (HOW), code (patterns), config.yaml
- **2a Workload Gate** — 400-line risk High / Chained PRs Yes / Decision needed Yes → confirm auto-chain (stacked-to-main|feature-branch-chain), exception-ok, single-pr (only size:exception); none → STOP + locked
- **2b Prior Progress** — mem_search("sdd/{change}/apply-progress") → mem_get_observation → skip done → first incomplete; MERGE prior + new. CRITICAL: progress exists → MUST read.
- **3 Resolve Mode** — strict_tdd (true+runner) → STRICT TDD → load skills/sdd-apply/strict-tdd.md; else Standard. Resolve: engram mem_search("sdd/{project}/testing-capabilities") → openspec config.yaml → project files. Strict TDD: TDD Cycle Evidence (RED→GREEN→REFACTOR per task) mandatory; missing = FAILED. All modes — Work Unit Evidence: focused test + result (cmd, exit, counts); runtime harness + result (N/A with reason); rollback boundary (revertable, no unrelated); threat-matrix → RED test before prod.
- **4 Implement** — task → spec scenarios → design → patterns → code → [x] → note issues
- **5 Persist + Return** — §C; save apply-progress (topic_key: sdd/{change}/apply-progress); confirm [x]. Return §D: Completed, Files Changed, TDD Evidence, Deviations, Issues, Remaining, Workload/PR Boundary, Status
- Artifacts: English; specs = acceptance criteria; follow design (freelancing → deviation); match patterns; stop on blocked.

## Examples
1. `sdd-apply auth/login --mode=engram` → reads tasks, impl 3 files → [x] → Tasks:3/3 Ready. 2. Rollback: fail → `git checkout HEAD~1 -- file` → re-mark [ ] → Issues → Blocked.

## Testing Patterns
1. Diff↔spec: every change maps to spec scenario ID; unmatched = deviation. 2. Work Unit Evidence: test cmd exit=0 counts>0; harness pass; rollback clean. 3. Strict TDD: RED→GREEN→REFACTOR per task; missing phase = FAILED; threat-matrix RED before prod.