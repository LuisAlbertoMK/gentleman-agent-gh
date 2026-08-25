# sdd-tasks — Reference Materials

> **Externalized from** .agents/skills/sdd-tasks/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains task-format detail, workload forecast, and the guard contract.

## Task Format
Header: workload forecast (lines, budget risk, chained PRs, strategy, chain strategy) + work units (unit, goal, PR, test cmd, harness, rollback) + phase sections `- [ ] N.N {file, change}`.

## Workload Forecast
>400 changed lines (signals: files, phases, integration, tests, docs, migrations) → `Chained PRs recommended: Yes`; split into work units (start, finish, verification, scope, test cmd, harness, rollback). Chain strategy: `stacked-to-main`|`feature-branch-chain`|`size-exception`. Decision: `ask-on-risk`→Yes, `auto-chain`→No, `single-pr`→Yes, `exception-ok`→No.

## Guard Contract (required plain-text)
```text
Decision needed before apply: Yes|No
Chained PRs recommended: Yes|No
Chain strategy: stacked-to-main|feature-branch-chain|size-exception|pending
400-line budget risk: Low|Medium|High
```

## Task Rules
- **Specific**: "Create `auth/middleware.go` with JWT validation" not "Add auth"
- **Actionable**: "Add `ValidateToken()` to `AuthService`" not "Handle tokens"
- **Verifiable**: "Test: `POST /login` returns 401 without token" not "Make sure it works"
- **Small**: one file/logical unit, ONE session
- Concrete paths, dependency-ordered, per-phase numbering (1.1, 2.1); apply `openspec/config.yaml` `rules.tasks`
- TDD: RED→GREEN→REFACTOR | Size: <530 words
- Threat-matrix: RED-test task before each production task (skip `N/A`)
