---
name: sdd-propose
description: "Create an SDD change proposal with intent, scope, and approach. Trigger: orchestrator launches proposal work for a change."
license: MIT
metadata:
  author: gentleman-programming
version: 1.0.0-local
triggers: "SDD propose, proposal, intent, approach, change proposal, SDD proposal"
  version: "2.0"
  delegate_only: true
---

> **ORCHESTRATOR GATE**: Loaded via `skill()`? You are ORCHESTRATOR — STOP. Delegate to `sdd-propose` sub-agent.
> **Executor Override**: If you ARE the sub-agent, ignore gate. Execute below. Do NOT delegate.

## Contract

Artifacts default to English. Spanish only if explicitly requested.

## Inputs

- Change name, exploration analysis OR user description, store mode (`engram | openspec | hybrid | none`)

## Persistence

Follow **Sections B+C** from `skills/_shared/sdd-phase-common.md`.

| Mode | Behavior |
|------|----------|
| `engram` | Read `sdd/{change-name}/explore` + `sdd-init/{project}` (opt). Save as `sdd/{change-name}/proposal`. |
| `openspec` | Follow `skills/_shared/openspec-convention.md`. |
| `hybrid` | Both — Engram (primary) + filesystem. |
| `none` | Return only. No files. |

Never force `openspec/` unless user requested or mode=`hybrid`.

## Steps

### 0: Interactive Proposal Shaping
Offer question round before finalizing (3-5 questions per round). Cover:
1. Business problem — why now
2. Target users — who, workflow, urgency
3. Business rules — policies, permissions, compliance
4. Product outcome — what becomes possible
5. Current-state gap — what's wrong/missing
6. Impact — teams, data, UX, support
7. Edge cases — empty states, failures, migrations
8. Decision gaps — unknowns risking ambiguity
9. Scope boundaries — v1 vs deferred vs unchanged
10. Business risk — worst downside if wrong

Summarize assumptions after answers. Offer corrections or round 2. Skip harness questions unless user raises them. If blocked from asking, write `## Proposal question round` in result.

### 1: Load Skills
Follow **Section A** from `skills/_shared/sdd-phase-common.md`.

### 2: Create Directory
- `openspec`/`hybrid`: create `openspec/changes/{change-name}/proposal.md`
- `engram`/`none`: skip

### 3: Read Specs
- `openspec`/`hybrid`: read relevant specs from `openspec/specs/`
- `engram`/`none`: skip

### 4: Write proposal.md

```markdown
# Proposal: {Change Title}

## Intent
{Problem. Why now. User need or tech debt.}

## Scope
### In Scope
- {Deliverable}

### Out of Scope
- {Excluded / deferred}

## Capabilities
> Contract with sdd-spec. Research `openspec/specs/` first.

### New Capabilities
<!-- Each → `openspec/specs/<name>/spec.md`. Kebab-case. Empty if none. -->
- `<name>`: <description>

### Modified Capabilities
<!-- Existing specs with changing REQUIREMENTS. Needs delta spec. Empty if none. -->
- `<name>`: <what changes>

## Approach
{Technical approach. Reference exploration if available.}

## Affected Areas
| Area | Impact | Description |
|------|--------|-------------|
| `path` | New/Mod/Removed | {What changes} |

## Risks
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| {Risk} | Low/Med/High | {Mitigation} |

## Rollback Plan
{Specific revert steps.}

## Dependencies
- {Deps if any}

## Success Criteria
- [ ] {Measurable outcome}
```

**Budget**: <450 words. Bullets/tables over prose. If no spec changes, write "None" in both Capabilities subsections.

### 5: Persist (MANDATORY)
Follow **Section C** from `skills/_shared/sdd-phase-common.md`.
- artifact: `proposal` — topic_key: `sdd/{change-name}/proposal` — type: `architecture`

### 6: Return
```markdown
## Proposal Created
**Change**: {name}
**Location**: `openspec/changes/{name}/proposal.md` | Engram `sdd/{name}/proposal` | inline
- **Intent**: {one-liner} | **Scope**: {N in, M deferred}
- **Approach**: {one-liner} | **Risk**: {Low/Med/High}
Ready for sdd-spec or sdd-design.
```

## Rules
- `openspec` mode: always create `proposal.md`
- Exists already: read → update
- Every proposal: rollback plan + success criteria
- Concrete file paths in Affected Areas
- Apply `rules.proposal` from `openspec/config.yaml`
- Always fill Capabilities section — contract with sdd-spec
- Return envelope per **Section D** from `skills/_shared/sdd-phase-common.md`

