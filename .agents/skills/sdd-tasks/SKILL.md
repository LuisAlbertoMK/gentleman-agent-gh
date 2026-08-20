---
name: sdd-tasks
description: "Break SDD change into implementation tasks. Trigger: orchestrator launches task planning."
triggers: "SDD tasks, task planning, implementation tasks, work breakdown"
changelog: docs/ciclos/cycle28-20260815.md
---
Input: change name, artifact store (`engram|openspec|hybrid|none`), delivery strategy (`ask-on-risk|auto-chain|single-pr|exception-ok`).
| Mode | Read | Save |
|---|---|---|
| engram | `sdd/{change}/proposal\|spec\|design` | `sdd/{change}/tasks` |
| openspec | `openspec-convention.md` | Filesystem |
| hybrid | Engram primary, fs fallback | Both |
| none | — | Return only |
1. **Load Skills** → §A `sdd-phase-common.md`
2. **Analyze Design**: files to create/modify/delete, dependency order, testing per component, every threat-matrix case + RED test (skip `N/A`).
3. **Write tasks.md**: openspec/hybrid → `openspec/changes/{change}/tasks.md`; engram/none → in memory → persist Step 4.
### Phase Organization
1. Foundation — types, interfaces, DB, config, deps. 2. Core — main logic, business rules. 3. Integration — components, routes, UI. 4. Testing — unit, integration, e2e. 5. Cleanup — docs, dead code.
4. **Persist** — §C `sdd-phase-common.md`
## CONSTRAINTS
Implementation-ready (sdd-apply consumes directly) · No implementation code — breakdown only · Flag unknowns, don't assume · tasks.md ≤ 530 words (excl. templates) · 1h max (escalate if exceeded) · RED test task before every production task (threat-matrix ≥80%) · Work units independently verifiable (test cmd + harness + rollback).
## Reference
Task Rules + Workload Forecast + Guard contract → docs/skills/sdd-tasks/reference.md