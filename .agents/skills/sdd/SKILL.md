---
name: sdd
description: "Unified SDD pipeline — 9 phases from init through archive. Use this skill when any SDD phase is needed."
triggers: "SDD pipeline, SDD phase, spec-driven development"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.0"
---

# SDD Pipeline — Spec-Driven Development

The SDD pipeline guides changes through 9 phases: Init → Explore → Propose → Spec → Design → Tasks → Apply → Verify → Archive.

## Pipeline Overview

```
[Init] → [Explore] → [Propose] → [Spec] → [Design] → [Tasks] → [Apply] ↔ [Verify] → [Archive]
                                                                       ↑         ↓
                                                                   [Loop on failures]
```

| # | Phase | Description | Load |
|---|-------|-------------|------|
| 00 | Init | Bootstrap project context, detect stack, build registry | `{file:sdd/phases/00-init.md}` |
| 01 | Explore | Investigate codebase, entry points, patterns, options | `{file:sdd/phases/01-explore.md}` |
| 02 | Propose | Define scope, capabilities, risks, rollback plan | `{file:sdd/phases/02-propose.md}` |
| 03 | Design | Technical design, decisions, data flow, file plan | `{file:sdd/phases/03-design.md}` |
| 04 | Spec | G/W/T specs with RFC 2119 requirements | `{file:sdd/phases/04-spec.md}` |
| 05 | Tasks | Break down into phased implementation tasks | `{file:sdd/phases/05-tasks.md}` |
| 06 | Apply | Implement spec→design→code per task | `{file:sdd/phases/06-apply.md}` |
| 07 | Verify | Validate compliance, tests pass, design match | `{file:sdd/phases/07-verify.md}` |
| 08 | Archive | Sync specs, move artifacts, create rollback snapshot | `{file:sdd/phases/08-archive.md}` |

## Phase Dependencies

Each phase depends on the output of its predecessor:
- **Apply** needs: Spec + Design + Tasks
- **Verify** needs: Spec + Design + Tasks + Apply output
- **Archive** needs: All prior phases complete

## Common Protocol

Every SDD phase shares a common protocol for skill loading, artifact persistence, and return envelopes.

`{file:sdd/references/sdd-phase-common.md}`

## Subagent Type Mapping

Each phase has a corresponding subagent type that loads its phase file:

| Subagent | Loads |
|----------|-------|
| sdd-init | `{file:sdd/phases/00-init.md}` |
| sdd-explore | `{file:sdd/phases/01-explore.md}` |
| sdd-propose | `{file:sdd/phases/02-propose.md}` |
| sdd-design | `{file:sdd/phases/03-design.md}` |
| sdd-spec | `{file:sdd/phases/04-spec.md}` |
| sdd-tasks | `{file:sdd/phases/05-tasks.md}` |
| sdd-apply | `{file:sdd/phases/06-apply.md}` |
| sdd-verify | `{file:sdd/phases/07-verify.md}` |
| sdd-archive | `{file:sdd/phases/08-archive.md}` |

## Usage

**Orchestrator**: Load this skill for the pipeline overview, then load the specific phase file for detailed instructions.
**Subagent**: Load your corresponding phase file directly via `{file:sdd/phases/{N}-{name}.md}`.

## Cross-References

- Individual wrapper skills: `sdd-init`, `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive` — each loads its phase from this shared structure.
- Common protocol originally at `_shared/sdd-phase-common.md` migrated here.
