---
name: sdd-propose
description: "Create SDD change proposal with intent, scope, approach. Trigger: orchestrator launches proposal work."
triggers: "SDD propose, proposal, intent, approach, change proposal"
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP. Delegate to `sdd-propose` sub-agent. Executor: execute directly.

Input: change name, exploration analysis OR user description, store mode (`engram|openspec|hybrid|none`).

| Mode | Behavior |
|---|---|
| `engram` | Read `sdd/{change}/explore` + `sdd-init/{project}` (opt); save as `sdd/{change}/proposal` |
| `openspec` | Follow `openspec-convention.md` |
| `hybrid` | Both (Engram primary + filesystem) |
| `none` | Return only |

Never force `openspec/` unless requested or `hybrid`.

### 0: Shaping
Question round before finalizing (3-5/round): business problem, target users, business rules, product outcome, current-state gap, impact, edge cases, decision gaps, scope boundaries, business risk. Summarize assumptions; offer corrections or round 2. Blocked → `## Proposal question round` in result.

### 1: Load Skills → §A `sdd-phase-common.md`
### 2: Create Directory
openspec/hybrid: `openspec/changes/{change}/proposal.md` · engram/none: skip
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
| `path` | New/Mod/Removed | {What changes} |
| Risk | Likelihood | Mitigation |
| {Risk} | Low/Med/High | {Mitigation} |
{Specific revert steps.}
- {Deps if any}
- [ ] {Measurable outcome}
```
**Budget**: <450 words; bullets/tables > prose. No spec changes → "None" in both Capabilities.

### 5: Persist — §C: artifact `proposal`, topic_key `sdd/{change}/proposal`, type `architecture`
### 6: Return
```markdown
**Change**: {name}
**Location**: `openspec/changes/{name}/proposal.md` | Engram `sdd/{name}/proposal` | inline
- **Intent**: {one-liner} | **Scope**: {N in, M deferred}
- **Approach**: {one-liner} | **Risk**: {Low/Med/High}
Ready for sdd-spec or sdd-design.
```
`openspec` mode: always create `proposal.md`; exists → read → update. Every proposal: rollback plan + success criteria; concrete paths in Affected Areas.

## Anti-Patterns
- **Over-specification**: no pseudo-code/signatures/algorithms — proposal owns what/why, sdd-spec owns how
- **Vague scope**: In/Out must list concrete paths — "Improve auth" unverifiable vs "JWT issuer, refresh flow, rate limiting"