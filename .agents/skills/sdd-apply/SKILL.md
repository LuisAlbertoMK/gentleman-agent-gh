---
name: sdd-apply
description: "Implement SDD tasks from specs and design."
triggers: "SDD apply, implement SDD, code change"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: ORCHESTRATOR → STOP, delegate to sdd-apply sub-agent. Executor: execute directly.

Change name, task(s), store (ngram|openspec|hybrid|none), status (sdd-status-contract.md), delivery (sk-on-risk|auto-chain|single-pr|exception-ok), PR slice / size:exception.
- **engram**: read sdd/{change}/proposal\|spec\|design\|tasks; mem_update; save pply-progress
- **openspec**: openspec-convention.md; mark [x] in 	asks.md
- **hybrid**: both. **none**: progress only.

| State | Action |
|---|---|
| locked | STOP + locked + missing artifacts |
| ll_done | No edits; success + 
ext: sdd-verify\|sdd-archive |
| eady | Proceed on assigned pending tasks only |

- Read contextFiles/rtifactPaths; workspace-planning + empty llowedEditRoots → STOP
- llowedEditRoots present → edit only under roots
- **1 Load Skills** — §A sdd-phase-common.md
- **2 Read Context** — pplyState: ready; contextFiles, specs (WHAT), design (HOW), code (patterns), config.yaml
- **2a Workload Gate** — 400-line risk: High / Chained PRs: Yes / Decision needed: Yes → confirm uto-chain (stacked-to-main|eature-branch-chain), xception-ok, single-pr (only size:exception); none → STOP + locked
- **2b Prior Progress** — mem_search("sdd/{change}/apply-progress") → mem_get_observation → skip done → first incomplete; MERGE prior + new. CRITICAL: progress exists → MUST read.
- **3 Resolve Mode** — strict_tdd (true+runner) → STRICT TDD → load skills/sdd-apply/strict-tdd.md; else Standard. Resolve: engram mem_search("sdd/{project}/testing-capabilities") → openspec config.yaml → project files. Strict TDD: TDD Cycle Evidence (RED→GREEN→REFACTOR per task) mandatory; missing = FAILED. All modes — Work Unit Evidence: focused test + result (cmd, exit, counts); runtime harness + result (N/A with reason); rollback boundary (revertable, no unrelated); threat-matrix → RED test before prod.
- **4 Implement** — task → spec scenarios → design → patterns → code → [x] → note issues
- **5 Persist + Return** — §C sdd-phase-common.md; save pply-progress (topic_key: sdd/{change}/apply-progress); confirm [x]. Return §D: Completed, Files Changed, TDD Evidence, Deviations, Issues, Remaining, Workload/PR Boundary, Status
- Artifacts: English; specs = acceptance criteria; follow design (freelancing → deviation); match patterns; stop on blocked.

## Examples (5)
1. **Standard**: sdd-apply auth/login --mode=engram → reads tasks, impl 3 files → [x] → Tasks:3/3 Ready
2. **Strict TDD**: sdd-apply payments/checkout --strict-tdd → per task: RED test → impl → REFACTOR → TDD Evidence
3. **Rollback**: task fails → git checkout HEAD~1 -- file → re-mark [ ] → save Issues → Blocked
4. **Spec→code**: task "Add JWT validate" → reads spec scenario → impl alidateToken():Claims per pattern → matching test
5. **Chained PR**: 400-line risk:High → splits per 	asks.md phases → uto-chain:stacked-to-main → PR#1 types, PR#2 core, PR#3 integration

## Testing Patterns (3)
1. **Diff↔spec**: git diff HEAD~1 -- src/ → every change maps to spec scenario ID; unmatched = deviation
2. **Work Unit Evidence**: task test cmd → exit=0, counts>0; runtime harness → pass; rollback boundary clean (git diff --name-only task files only)
3. **Strict TDD**: RED→GREEN→REFACTOR per task logged; missing phase = FAILED; threat-matrix RED test before prod code

## Edge Cases (4)
1. **Merge conflicts**: partial → MERGE: keep [x], re-run conflicted from clean base, note Issues
2. **Partial failure**: task 2/5 fails → save up to task 1 → Blocked by task 2 → orchestrator resumes
3. **Order violation**: 	asks.md Phase 1→2→3; violation = deviation + STOP
4. **Missing artifacts**: spec/design not found → locked + missing:["spec","design"]; do NOT proceed

## Anti-Patterns (2)
1. **Freelancing design**: impl beyond spec → Deviations grows, verify fails → STOP at first deviation
2. **Skipping Work Unit Evidence**: no focused test / harness / rollback boundary → FAILED regardless of code
