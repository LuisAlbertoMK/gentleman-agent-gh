---
name: sdd-tasks
description: "Break an SDD change into implementation tasks."
delegate_only: true
---

> **GATE**: Loaded via `skill()` -> STOP. Delegate to `sdd-tasks` sub-agent. Executor -> run directly.

## Purpose
Create `tasks.md` - actionable implementation steps by phase, from proposal + specs + design.

## Inputs
Change name, artifact store (`engram|openspec|hybrid|none`), delivery strategy (`ask-on-risk|auto-chain|single-pr|exception-ok`).

## Persistence (sdd-phase-common B+C)
| Mode | Read | Save |
|---|---|---|
| engram | `sdd/{change}/proposal`, `/spec`, `/design` | `sdd/{change}/tasks` |
| openspec | `openspec-convention.md` | filesystem |
| hybrid | Engram primary, FS fallback | Both |
| none | - | Return only |

## Steps
1. Load skills (Section A).
2. **Analyze design**: files create/modify/delete, dependency order, testing per component, every threat-matrix case + RED test (skip N/A).
3. **Write tasks.md** (openspec/hybrid file; engram/none in memory): header workload forecast (changed lines, budget risk, chained PRs, split, strategy, chain strategy) + suggested work units (unit, goal, PR, test command, runtime harness, rollback boundary) + phase sections with `- [ ] N.N {file, change}`.

**Task rules**: Specific ("Create `auth/middleware.go` with JWT validation"); Actionable ("Add `ValidateToken()` to `AuthService`"); Verifiable ("Test: POST /login returns 401 without token"); Small (one file/logical unit, ONE session). Concrete paths, dependency-ordered, per-phase numbering (1.1, 2.1...). No vague tasks; `rules.tasks` from config.yaml; TDD RED->GREEN->REFACTOR; <530 words; threat-matrix RED test before each production task (skip N/A).

**Workload forecast**: >400 changed lines (additions+deletions). Signals: file count, phases, integration, tests, docs, migrations. High/expected -> `Chained PRs recommended: Yes`, split into work units -> chained PRs (each: start, finish, verification, scope, test command, runtime harness, rollback boundary). Chain strategy: `stacked-to-main` (merge to main, fast) | `feature-branch-chain` (PRs target previous PR, rollback control) | `size-exception` (single PR + maintainer approval, generated/migration). `Decision needed`: ask-on-risk->Yes | auto-chain->No | single-pr->Yes | exception-ok->No.

Guard contract (plain-text lines): Decision needed before apply; Chained PRs recommended; Chain strategy; 400-line budget risk.

`feature-branch-chain`: PR#1->tracker, PR#2->PR#1, PR#3->PR#2. Wrong base = retarget before review.

**Phases**: 1 Foundation (types, interfaces, DB, config, deps) | 2 Core (main logic, business rules) | 3 Integration (components, routes, UI) | 4 Testing (unit, integration, e2e; spec scenarios) | 5 Cleanup (docs, dead code, polish).

4. **Persist (MANDATORY)**: Section C; artifact `tasks`, key `sdd/{change}/tasks`, type `architecture`.
5. **Return**: change, location, phase breakdown table, workload forecast, next (sdd-apply or ask about chained PRs).
