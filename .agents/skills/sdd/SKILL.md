---
name: sdd
description: "Unified SDD pipeline — 9 phases from init through archive. Use sdd-quick for LOW-risk 3-phase fast path."
triggers: "SDD pipeline, SDD phase, spec-driven development"
---

## When to Use
Unified SDD pipeline — 9 phases from init through archive. U


# SDD Pipeline

**Fast path for LOW-risk changes:** `{file:sdd-quick/SKILL.md}` — 3 phases instead of 9.

```
[Init] → [Explore] → [Propose] → [Spec] → [Design] → [Tasks] → [Apply] ↔ [Verify] → [Archive]
                                                       ↓ (LOW-risk shortcut)
                                              [Propose] → [Apply] ↔ [Verify]
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

## Choosing Your Path

| Factor | Fast (sdd-quick) | Full (9-phase) |
|--------|-----------------|----------------|
| Files changed | 1-3 | 4+ |
| Schema change | No | Yes |
| Auth/API change | No | Yes |
| New dependency | No | Yes |
| Risk level | LOW | MED/HIGH |
| Known codebase | Yes | No |

**Gate check**: If ANY answer is "No" below → full pipeline.
```
Known codebase? ← Schema unchanged? ← No new deps? ← LOW risk? ← <4 files?
```
When unsure: start full, skip phases after `[Explore]` if scope confirms fast path.

## Orchestrator Routing
```
phase=init    → sdd-init
phase=explore → sdd-explore
phase=propose → sdd-propose
Fast path?    → switch to sdd-quick after Propose
```
Each phase writes to `sdd/registry/{change-id}/{phase}.md`.

## Delivery-Harness Integration
| SDD Phase | Harness Unit |
|-----------|-------------|
| Explore + Design | Work Unit 1 (analysis) |
| Tasks | Work Unit 2 (task split) |
| Apply | Work Unit 3-N (parallel impl) |
| Verify | Gate → archive |

Use `delivery-harness` when SDD task list exceeds 5 apply steps.

## Refs
execution-mode · quality-gate · triple-verify · delivery-harness · project-mapper

## Anti-Patterns
Skip phases in THOROUGH mode · Archive without verification · Design before scope · Spec without edge cases · Apply before verify
