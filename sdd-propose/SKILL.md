---
name: sdd-propose
description: >
  Create change proposal with intent, scope, and approach.
  Trigger: Orchestrator launches you to create/update proposal for a change.
license: MIT
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Purpose
PROPOSAL sub-agent. Produce structured `proposal.md` inside change folder.

## Persistence Contract
Per `_shared/sdd-phase-common.md` Sections B+C.
- **engram**: Read explore/init (optional). Save `sdd/{change}/proposal`
- **openspec**: Follow `_shared/openspec-convention.md`
- **hybrid**: BOTH — engram + filesystem
- **none**: Return result only. NEVER create `openspec/` dirs

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Create Change Directory
openspec/hybrid → `openspec/changes/{change}/proposal.md`
engram/none → Skip.

### 3: Read Existing Specs
openspec/hybrid: read relevant specs from `openspec/specs/`. engram: already retrieved. none: skip.

### 4: Write proposal.md
```markdown
# Proposal: {Title}
## Intent
{Problem + why needed}

## Scope
### In Scope
- {Deliverable 1}
- {Deliverable 2}
### Out of Scope
- {Explicitly NOT doing}
- {Deferred future work}

## Capabilities
> Contract with sdd-spec. Research openspec/specs/ before filling.
### New Capabilities
- `<capability-name>`: <what it covers>
### Modified Capabilities
- `<existing-capability>`: <what requirement changes>

## Approach
{High-level technical approach}

## Affected Areas
| Area | Impact | Description |
| `path/to/area` | New/Modified/Removed | {what changes} |

## Risks
| Risk | Likelihood | Mitigation |
| {Risk} | Low/Med/High | {How to mitigate} |

## Rollback Plan
{How to revert if things go wrong}

## Dependencies
- {External prerequisite, if any}

## Success Criteria
- [ ] {How to know it succeeded}
- [ ] {Measurable outcome}
```

### 5: Persist (MANDATORY)
artifact: `proposal` | topic_key: `sdd/{change}/proposal` | type: `architecture`

### 6: Return Summary
```
## Proposal Created
**Change**: {name} | **Location**: {path/engram/inline}
**Intent**: {one-line} | **Scope**: {N in, M deferred} | **Risk**: {Low/Med/High}
### Next
Ready for specs (sdd-spec) or design (sdd-design).
```

## Rules
- openspec: ALWAYS create `proposal.md`
- Existing proposal → READ first, UPDATE
- CONCISE — thinking tool, not novel
- MUST have rollback plan + success criteria
- Concrete file paths in "Affected Areas"
- **ALWAYS fill Capabilities** — contract with sdd-spec. Research `openspec/specs/` first.
- New → becomes `openspec/specs/<name>/spec.md`
- Modified → needs delta spec
- No spec-level changes → write "None" under both
- Size budget: <450 words. Bullets/tables over prose.
- Return envelope per `_shared/sdd-phase-common.md` Section D.
