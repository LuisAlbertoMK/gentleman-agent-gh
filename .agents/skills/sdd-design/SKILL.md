---
name: sdd-design
description: Create the SDD technical design and architecture approach. Trigger: orchestrator launches design for a change.
author: Gentle AI
version: 1.0.0-local
mode: primary
delegate_only: true
priority: standard
triggers: "SDD design, design phase, technical design, architecture design, sdd-design"
allow_comments: true
changelog: docs/ciclos/cycle28-20260815.md
---

# SDD — Design Phase

Creates the technical design and architecture approach for a change. Triggered by the orchestrator when moving from proposal to implementation.

## Protocol

Follow **Section A** (skill loading) + **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.

**Do NOT launch sub-agents** — this is an EXECUTOR phase. Do the design work yourself.

## Input Artifacts (load in parallel)

- `sdd/{change-name}/proposal` — the approved change proposal
- `sdd/{change-name}/exploration` — (optional) exploration artifacts if a discovery phase ran
- Project standards from orchestrator (if injected)

## What to Produce

### 1. Architecture Decision

- Document the chosen architecture approach (Clean, Hexagonal, Screaming Layers, etc.)
- Define bounded contexts, modules, and dependency flow
- Choose: ports-and-adapters, event-driven, CQRS, or monolithic-with-modules
- Justify the choice against alternatives considered

### 2. Data Design

- Schema changes needed (if any)
- Migration strategy — backward compatible vs. breaking
- Data validation layers and boundaries

### 3. API Design

- Endpoints/APIs affected
- Request/response shape (OpenAPI-style or schema)
- Error handling conventions for the change

### 4. Security & Compliance

- Trust boundaries crossed
- Authentication/authorization changes needed
- Secrets/credentials handling
- Privacy impact (GDPR/CPPA) if data touched

### 5. Testing Strategy

- Unit test plan — key edge cases to cover
- Integration test plan — boundaries between services/modules
- Risk-based coverage of the 7 risk factors:
  1. Cross-context boundary (shared mutable state)
  2. File I/O, network I/O
  3. Async or concurrent execution
  4. Complex branching / cyclomatic >60
  5. Non-testable code (singletons, global state, private methods)
  6. Performance-critical paths (caching, N+1, loops)
  7. Error path / exception handling

## Output Envelope

```markdown
**Status**: success | partial | blocked
**Summary**: [1-3 sentences of what was designed]
**Artifacts**: Engram `sdd/{change-name}/design` | `openspec/changes/{change-name}/design.md`
**Next**: sdd-spec or sdd-tasks
**Risks**: [risks discovered, or "None"]
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

## Constraints

- Output must be implementation-ready — the `sdd-tasks` phase should be able to consume it directly
- Do NOT write implementation code — only design
- Flag any unknowns as risks, do NOT make assumptions
