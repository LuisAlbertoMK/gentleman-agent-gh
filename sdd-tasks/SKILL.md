---
name: sdd-tasks
description: >
  Break change into implementation task checklist.
  Trigger: Orchestrator launches you to create/update task breakdown for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
TASK BREAKDOWN sub-agent. Take proposal + specs + design → produce `tasks.md` with concrete, actionable steps.

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read proposal + spec + design (all required). Save `sdd/{change}/tasks`
- **openspec**: Follow `_shared/openspec-convention.md`
- **hybrid**: BOTH
- **none**: Return result only

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Analyze Design
From design: files to create/modify/delete, dependency order, testing requirements.

### 3: Write tasks.md
openspec/hybrid → `openspec/changes/{change}/tasks.md`
engram/none → Compose in memory, persist in Step 4.

```markdown
# Tasks: {Title}

## Phase 1: Foundation / Infrastructure
- [ ] 1.1 {Concrete: what file, what change}
- [ ] 1.2 {Concrete action}

## Phase 2: Core Implementation
- [ ] 2.1 {Concrete action}
- [ ] 2.2 {Concrete action}

## Phase 3: Integration / Wiring
- [ ] 3.1 {Connect components, routes, UI}

## Phase 4: Testing
- [ ] 4.1 {Unit tests for ...}
- [ ] 4.2 {Integration tests for ...}

## Phase 5: Cleanup (if needed)
- [ ] 5.1 {Update docs, remove dead code}
```

### Task Writing Rules
| Criteria | ✅ | ❌ |
|----------|---|---|
| Specific | "Create auth/middleware.go with JWT validation" | "Add auth" |
| Actionable | "Add ValidateToken() to AuthService" | "Handle tokens" |
| Verifiable | "Test: POST /login returns 401 without token" | "Make sure it works" |
| Small | One file / logical unit | "Implement the feature" |

### Phase Order
```
Phase 1: Foundation — Types, interfaces, DB changes, config (dependencies first)
Phase 2: Core — Business logic, core behavior
Phase 3: Integration — Connect components, routes, wiring
Phase 4: Testing — Unit, integration, e2e. Reference spec scenarios
Phase 5: Cleanup — Docs, dead code, polish
```

### 4: Persist (MANDATORY)
artifact: `tasks` | topic_key: `sdd/{change}/tasks` | type: `architecture`

### 5: Return Summary
```
## Tasks Created
**Change**: {name} | **Location**: {path/engram/inline}
| Phase | Tasks | Focus |
| Phase 1 | {N} | {name} |
| Total | {N} | |

### Implementation Order
{Brief order + why}

### Next
Ready for implementation (sdd-apply).
```

## Rules
- Concrete file paths in tasks
- Ordered by dependency — Phase 1 independent of Phase 2
- Testing tasks reference spec scenarios
- Each task completable in ONE session (split if too big)
- Hierarchical numbering: 1.1, 1.2, 2.1...
- NO vague tasks ("implement feature", "add tests")
- TDD project → RED task (failing test) → GREEN (make pass) → REFACTOR
- Size budget: <530 words. Tasks: 1-2 lines max. Checklist format.
- Return envelope per `_shared/sdd-phase-common.md` Section D.
