---
name: sdd-tasks
description: "Break SDD change into implementation tasks. Trigger: orchestrator launches task planning."
triggers: "SDD tasks, task planning, implementation tasks, work breakdown"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → STOP. Delegate to `sdd-tasks` sub-agent.

Change name, artifact store (`engram|openspec|hybrid|none`), delivery strategy (`ask-on-risk|auto-chain|single-pr|exception-ok`).

| Mode | Read | Save |
|---|---|---|
| engram | `sdd/{change}/proposal\|spec\|design` | `sdd/{change}/tasks` |
| openspec | `openspec-convention.md` | Filesystem |
| hybrid | Engram primary, fs fallback | Both |
| none | — | Return only |

1. **Load Skills** → §A of `sdd-phase-common.md`
2. **Analyze Design**: Identify files to create/modify/delete, dependency order, testing per component, every threat-matrix case + RED test (skip `N/A`).
3. **Write tasks.md**
   - openspec/hybrid: `openspec/changes/{change}/tasks.md`
   - engram/none: compose in memory → persist in Step 4

### Task Format
Header with workload forecast (changed lines, budget risk, chained PRs, split, strategy, chain strategy), suggested work units (unit, goal, PR, test cmd, runtime harness, rollback boundary), then phase sections with `- [ ] N.N {file, change}` checklists.

### Task Rules
- **Specific**: "Create `auth/middleware.go` with JWT validation" not "Add auth"
- **Actionable**: "Add `ValidateToken()` to `AuthService`" not "Handle tokens"
- **Verifiable**: "Test: `POST /login` returns 401 without token" not "Make sure it works"
- **Small**: One file/logical unit, completable in ONE session
- Concrete file paths, ordered by dependency, per-phase numbering (1.1, 2.1)
- No vague tasks; apply `openspec/config.yaml` `rules.tasks`
- TDD: RED → GREEN → REFACTOR | Size budget: <530 words
- Threat-matrix: RED-test task before each production task (skip `N/A`)

### Workload Forecast
Estimate if >400 changed lines. Signals: file count, phases, integration, tests, docs, migrations.
If **High** or likely >400:
- `Chained PRs recommended: Yes`
- Split into work units → chained PRs (each needs: start, finish, verification, scope, test cmd, runtime harness, rollback boundary)
- **Chain strategy**: `stacked-to-main` · `feature-branch-chain` · `size-exception`
- `Decision needed`: `ask-on-risk`→Yes, `auto-chain`→No, `single-pr`→Yes, `exception-ok`→No

**Guard contract** (required plain-text):
```text
Decision needed before apply: Yes|No
Chained PRs recommended: Yes|No
Chain strategy: stacked-to-main|feature-branch-chain|size-exception|pending
400-line budget risk: Low|Medium|High
```
`feature-branch-chain`: PR#1→tracker, PR#2→PR#1, PR#3→PR#2. Wrong base = retarget before review.

### Phase Organization
1. Foundation — types, interfaces, DB, config, deps
2. Core — main logic, business rules
3. Integration — connect components, routes, UI
4. Testing — unit, integration, e2e; spec scenarios
5. Cleanup — docs, dead code, polish

4. **Persist** — §C of `sdd-
