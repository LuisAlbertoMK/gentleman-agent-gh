---
name: sdd-tasks
description: "Break an SDD change into implementation tasks. Trigger: orchestrator launches task planning for a change."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD tasks, task planning, implementation tasks, work breakdown, task breakdown"
  version: "2.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: Loaded via `skill()` → STOP. Delegate to `sdd-tasks` sub-agent. EXECUTORS only.

**Executor Override**: If you ARE `sdd-tasks` sub-agent → execute directly.

## Language Contract

SDD artifacts default to English. Spanish only if explicitly requested. Comments follow target context language.

## Purpose

Create `tasks.md` — actionable implementation steps organized by phase, from proposal + specs + design.

## Inputs

Change name, artifact store (`engram | openspec | hybrid | none`), delivery strategy (`ask-on-risk | auto-chain | single-pr | exception-ok`).

## Persistence

Follow `skills/_shared/sdd-phase-common.md` Sections B+C.

| Mode | Read | Save |
|------|------|------|
| engram | `sdd/{change-name}/proposal`, `/spec`, `/design` | `sdd/{change-name}/tasks` |
| openspec | `skills/_shared/openspec-convention.md` | Filesystem |
| hybrid | Engram primary, filesystem fallback | Both |
| none | — | Return only |

## Steps

### Step 1: Load Skills → Section A of `sdd-phase-common.md`

### Step 2: Analyze Design

Identify: files to create/modify/delete, dependency order, testing per component, every threat-matrix case + RED test (skip `N/A`).

### Step 3: Write tasks.md

**openspec/hybrid**: Create `openspec/changes/{change-name}/tasks.md`
**engram/none**: Compose in memory → persist in Step 4.

#### Task Format

Header with workload forecast table (changed lines, budget risk, chained PRs, split, strategy, chain strategy), suggested work units table (unit, goal, PR, test command, runtime harness, rollback boundary), then phase sections with `- [ ] N.N {file, change}` checklist items.

#### Task Rules

- **Specific**: "Create `auth/middleware.go` with JWT validation" not "Add auth"
- **Actionable**: "Add `ValidateToken()` to `AuthService`" not "Handle tokens"
- **Verifiable**: "Test: `POST /login` returns 401 without token" not "Make sure it works"
- **Small**: One file/logical unit, completable in ONE session
- Concrete file paths, ordered by dependency, per-phase numbering (1.1, 2.1)
- No vague tasks, apply `openspec/config.yaml` `rules.tasks`
- TDD: RED → GREEN → REFACTOR | Size budget: <530 words
- Threat-matrix: RED-test task before each production task (skip `N/A`)

#### Workload Forecast

Estimate if >400 changed lines (additions + deletions). Signals: file count, phases, integration, tests, docs, migrations.

If **High** or likely >400: `Chained PRs recommended: Yes`, split into work units → chained PRs. Each PR needs: start, finish, verification, scope, test command, runtime harness, rollback boundary.

**Ask user chain strategy**: stacked-to-main (merge to main, fast iteration), feature-branch-chain (PRs target previous PR, rollback control), size:exception (single PR + maintainer approval, generated/migration code).

Set `Decision needed` per strategy: `ask-on-risk`→Yes, `auto-chain`→No, `single-pr`→Yes, `exception-ok`→No

**Guard contract** (required plain-text lines):
```text
Decision needed before apply: Yes|No
Chained PRs recommended: Yes|No
Chain strategy: stacked-to-main|feature-branch-chain|size-exception|pending
400-line budget risk: Low|Medium|High
```

`feature-branch-chain`: PR#1→tracker, PR#2→PR#1, PR#3→PR#2. Wrong base = retarget before review.

### Phase Organization

Phase 1: Foundation — types, interfaces, DB, config, deps
Phase 2: Core — main logic, business rules
Phase 3: Integration — connect components, routes, UI
Phase 4: Testing — unit, integration, e2e; spec scenarios
Phase 5: Cleanup — docs, dead code, polish (if needed)

### Step 4: Persist Artifact (MANDATORY)

Section C of `sdd-phase-common.md`: artifact=`tasks`, topic_key=`sdd/{change-name}/tasks`, type=`architecture`

### Step 5: Return Summary

Return: change name, location, phase breakdown table, workload forecast (lines/budget risk/chained/strategy/decision/split), next step (ready for sdd-apply or ask about chained PRs).

