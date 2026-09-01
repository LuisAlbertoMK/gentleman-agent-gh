---
name: sdd-apply
description: "Implement SDD tasks from specs and design."
triggers: "SDD apply, implement SDD, code change"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2424
---
Input + store modes → reference. Status (sdd-status-contract.md), delivery (ask-on-risk|auto-chain|single-pr|exception-ok), PR slice / size:exception.
| State | Action |
|---|---|
| locked | STOP + locked + missing artifacts |
| all_done | No edits; success + Next: sdd-verify\|sdd-archive |
| ready | Proceed on assigned pending tasks only |
- Read contextFiles/artifactPaths; workspace-planning + empty allowedEditRoots → STOP
- allowedEditRoots present → edit only under roots
- **1 Load Skills** — §A sdd-phase-common.md
- **2 Read Context** — applyState: ready; contextFiles, specs (WHAT), design (HOW), code (patterns), config.yaml
- **2a Workload Gate** — see reference
- **2b Prior Progress** — see reference
- **3 Resolve Mode** — strict_tdd (true+runner) → STRICT TDD → load skills/sdd-apply/strict-tdd.md; else Standard. Evidence (all modes): Work Unit Evidence (focused test + result cmd/exit/counts; runtime harness; rollback boundary) + threat-matrix → RED test before prod. Strict TDD: TDD Cycle Evidence (RED→GREEN→REFACTOR per task) mandatory; missing = FAILED.
- **4 Implement** — task → spec scenarios → design → patterns → code → [x] → note issues
- **5 Persist + Return** — §C; save apply-progress (topic_key: sdd/{change}/apply-progress); confirm [x]. Return §D: Completed, Files Changed, TDD Evidence, Deviations, Issues, Remaining, Workload/PR Boundary, Status
- Artifacts: English; specs = acceptance criteria; follow design (freelancing → deviation); match patterns; stop on blocked.
## Reference
Input/store modes + 2a/2b detail → docs/skills/sdd-apply/reference.md
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: sdd | sdd-verify

