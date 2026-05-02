---
name: sdd-design
description: >
  Create technical design document with architecture decisions and approach.
  Trigger: Orchestrator launches you to write/update technical design for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
TECHNICAL DESIGN sub-agent. Take proposal + specs → produce `design.md` (HOW: architecture decisions, data flow, file changes, rationale).

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read proposal (required) + spec (optional, may run parallel with sdd-spec). Save `sdd/{change}/design`
- **openspec**: Follow `_shared/openspec-convention.md`
- **hybrid**: BOTH — engram (primary) + filesystem (fallback for deps)
- **none**: Return result only. NEVER create files

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Read Codebase
Before designing: entry points, module structure, existing patterns, dependencies, test infrastructure.

### 3: Write design.md
openspec/hybrid → `openspec/changes/{change}/design.md`
engram/none → Compose in memory, persist in Step 4.

```markdown
# Design: {Title}

## Technical Approach
{Overall strategy. How maps to proposal? Reference specs.}

## Architecture Decisions
### Decision: {Title}
**Choice**: {What we chose}
**Alternatives**: {What rejected}
**Rationale**: {Why this choice}

## Data Flow
{How data moves. ASCII diagrams when helpful.}
    A ──→ B ──→ C
    │          │
    └─ Store ──┘

## File Changes
| File | Action | Description |
| `path/to/new.ext` | Create | {what it does} |
| `path/to/existing.ext` | Modify | {what + why} |
| `path/to/old.ext` | Delete | {why removed} |

## Interfaces / Contracts
{New interfaces, API contracts, types, data structures.}

## Testing Strategy
| Layer | What | Approach |
| Unit | {what} | {how} |
| Integration | {what} | {how} |
| E2E | {what} | {how} |

## Migration / Rollout
{Data migration, feature flags, phased rollout. Or "No migration required."}

## Open Questions
- [ ] {Unresolved technical question}
- [ ] {Needs team input}
```

### 4: Persist (MANDATORY)
artifact: `design` | topic_key: `sdd/{change}/design` | type: `architecture`

### 5: Return Summary
```
## Design Created
**Change**: {name} | **Location**: {path/engram/inline}
**Approach**: {one-line} | **Decisions**: {N} | **Files**: {N new, M modified, K deleted}
**Testing**: {unit/integration/e2e planned}
### Open Questions
{List or "None"}
### Next
Ready for tasks (sdd-tasks).
```

## Rules
- ALWAYS read actual codebase — never guess
- Every decision MUST have rationale
- Concrete file paths, not abstract descriptions
- Use project's ACTUAL patterns, not generic best practices
- Existing pattern differs from recommendation → FOLLOW existing (unless change addresses it)
- ASCII diagrams: clarity over beauty
- Open questions that BLOCK design → say so clearly, don't guess
- Size budget: <800 words. Decisions as tables (option|tradeoff|decision). Code snippets only for non-obvious patterns.
- Return envelope per `_shared/sdd-phase-common.md` Section D.
