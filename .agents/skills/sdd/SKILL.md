---
name: sdd
description: "Unified SDD pipeline — 9 phases from init through archive."
triggers: "SDD pipeline, SDD phase, spec-driven development"
license: MIT
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.0"
---

# SDD Pipeline

```
[Init] → [Explore] → [Propose] → [Spec] → [Design] → [Tasks] → [Apply] ↔ [Verify] → [Archive]
```

| Phase | Description | Subagent |
|-------|-------------|----------|
| Init | Bootstrap project context | sdd-init |
| Explore | Investigate codebase, entry points | sdd-explore |
| Propose | Scope, risks, rollback plan | sdd-propose |
| Design | Architecture, data flow, file plan | sdd-design |
| Spec | G/W/T specs with RFC 2119 | sdd-spec |
| Tasks | Phased implementation tasks | sdd-tasks |
| Apply | Implement per task spec | sdd-apply |
| Verify | Compliance + test validation | sdd-verify |
| Archive | Rollback snapshot, spec sync | sdd-archive |

## Protocol
All phases share: `{file:sdd/references/sdd-phase-common.md}`

## Usage
**Orchestrator**: Load this skill for overview → load specific phase for details.
**Subagent**: Load phase file via `{file:sdd/phases/{N}-{name}.md}`.

Individual wrapper skills (`sdd-init`, `sdd-explore`, etc.) each load their phase from this shared structure.
Common protocol migrated from `_shared/sdd-phase-common.md`.
