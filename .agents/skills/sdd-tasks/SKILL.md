---
name: sdd-tasks
description: "Break SDD change into implementation tasks. Trigger: orchestrator launches task planning."
triggers: "SDD tasks, task planning, implementation tasks, work breakdown"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → STOP. Delegate to `sdd-tasks` sub-agent.

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

### Task Format
Header: workload forecast (lines, budget risk, chained PRs, strategy, chain strategy) + work units (unit, goal, PR, test cmd, harness, rollback) + phase sections `- [ ] N.N {file, change}`.

### Task Rules
- **Specific**: "Create `auth/middleware.go` with JWT validation" not "Add auth"
- **Actionable**: "Add `ValidateToken()` to `AuthService`" not "Handle tokens"
- **Verifiable**: "Test: `POST /login` returns 401 without token" not "Make sure it works"
- **Small**: one file/logical unit, ONE session
- Concrete paths, dependency-ordered, per-phase numbering (1.1, 2.1); apply `openspec/config.yaml` `rules.tasks`
- TDD: RED→GREEN→REFACTOR | Size: <530 words
- Threat-matrix: RED-test task before each production task (skip `N/A`)

### Workload Forecast
>400 changed lines (signals: files, phases, integration, tests, docs, migrations) → `Chained PRs recommended: Yes`; split into work units (start, finish, verification, scope, test cmd, harness, rollback). Chain strategy: `stacked-to-main`|`feature-branch-chain`|`size-exception`. Decision: `ask-on-risk`→Yes, `auto-chain`→No, `single-pr`→Yes, `exception-ok`→No.

**Guard contract** (required plain-text):
```text
Decision needed before apply: Yes|No
Chained PRs recommended: Yes|No
Chain strategy: stacked-to-main|feature-branch-chain|size-exception|pending
400-line budget risk: Low|Medium|High
```

### Phase Organization
1. Foundation — types, interfaces, DB, config, deps. 2. Core — main logic, business rules. 3. Integration — components, routes, UI. 4. Testing — unit, integration, e2e. 5. Cleanup — docs, dead code.

4. **Persist** — §C `sdd-phase-common.md`

## CONSTRAINTS
Implementation-ready (sdd-apply consumes directly) · No implementation code — breakdown only · Flag unknowns, don't assume · tasks.md ≤ 530 words (excl. templates) · 1h max (escalate if exceeded) · RED test task before every production task (threat-matrix ≥80%) · Work units independently verifiable (test cmd + harness + rollback).