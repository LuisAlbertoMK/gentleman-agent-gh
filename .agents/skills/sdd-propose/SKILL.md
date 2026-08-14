---
description: "Create SDD change proposal with intent, scope, approach. Trigger: orchestrator launches proposal work."
triggers: "SDD propose, proposal, intent, approach, change proposal"
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP. Delegate to `sdd-propose` sub-agent. Executor: execute directly.

Change name, exploration analysis OR user description, store mode (`engram|openspec|hybrid|none`).

| Mode | Behavior |
|---|---|
| `engram` | Read `sdd/{change}/explore` + `sdd-init/{project}` (opt); save as `sdd/{change}/proposal` |
| `openspec` | Follow `openspec-convention.md` |
| `hybrid` | Both (Engram primary + filesystem) |
| `none` | Return only |
Never force `openspec/` unless requested or `hybrid`.

### 0: Interactive Proposal Shaping
Offer question round before finalizing (3-5 questions/round). Cover:
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
Summarize assumptions. Offer corrections or round 2. If blocked from asking, write `## Proposal question round` in result.

### 1: Load Skills → §A of `sdd-phase-common.md`
### 2: Create Directory
- openspec/hybrid: `openspec/changes/{change}/proposal.md`
- engram/none: skip
### 3: Read Specs (openspec/hybrid: `openspec/specs/`)
### 4: Write proposal.md
```markdown
# Proposal: {Change Title}

{Problem. Why now. User need or tech debt.}

### In Scope - {Deliverable}
### Out of Scope - {Excluded / deferred}

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `<name>`: <description>
### Modified Capabilities - `<name>`: <what changes>

{Technical approach. Reference exploration if available.}

| Area | Impact | Description |
|---|---|---|
| `path` | New/Mod/Removed | {What changes} |

| Risk | Likelihood | Mitigation |
|---|---|---|
| {Risk} | Low/Med/High | {Mitigation} |

{Specific revert steps.}

- {Deps if any}

- [ ] {Measurable outcome}
```
**Budget**: <450 words. Bullets/tables over prose. If no spec changes, write "None" in both Capabilities subsections.

### 5: Persist — §C of `sdd-phase-common.md`: artifact `proposal`, topic_key `sdd/{change}/proposal`, type `architecture`

### 6: Return
```markdown

**Change**: {name}
**Location**: `openspec/changes/{name}/proposal.md` | Engram `sdd/{name}/proposal` | inline
- **Intent**: {one-liner} | **Scope**: {N in, M deferred}
- **Approach**: {one-liner} | **Risk**: {Low/Med/High}
Ready for sdd-spec or sdd-design.
```

- `openspec` mode: always create `proposal.md`; Exists already: read → update
- Every proposal: rollback plan + success criteria; Concrete file paths in Affected Areas
