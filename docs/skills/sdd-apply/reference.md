# sdd-apply - Reference Materials

> **Externalized from** .agents/skills/sdd-apply/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
1. `sdd-apply auth/login --mode=engram` → reads tasks, impl 3 files → [x] → Tasks:3/3 Ready. 2. Rollback: fail → `git checkout HEAD~1 -- file` → re-mark [ ] → Issues → Blocked.


## Testing Patterns
1. Diff↔spec: every change maps to spec scenario ID; unmatched = deviation. 2. Work Unit Evidence: test cmd exit=0 counts>0; harness pass; rollback clean. 3. Strict TDD: RED→GREEN→REFACTOR per task; missing phase = FAILED; threat-matrix RED before prod.

## 2b Prior Progress
`mem_search("sdd/{change}/apply-progress")` → `mem_get_observation` → skip done → first incomplete; MERGE prior + new. CRITICAL: progress exists → MUST read.

## Input & Store Modes
Input: change name, task(s), store (engram|openspec|hybrid|none), status (sdd-status-contract.md), delivery (ask-on-risk|auto-chain|single-pr|exception-ok), PR slice / size:exception.
- **engram**: read sdd/{change}/proposal|spec|design|tasks; mem_update; save apply-progress
- **openspec**: openspec-convention.md; mark [x] in tasks.md
- **hybrid**: both. **none**: progress only.

## 2a Workload Gate
400-line risk High / Chained PRs Yes / Decision needed Yes → confirm auto-chain (stacked-to-main|feature-branch-chain), exception-ok, single-pr (only size:exception); none → STOP + locked.

