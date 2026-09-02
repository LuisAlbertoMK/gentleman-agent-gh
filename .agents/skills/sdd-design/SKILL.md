---
name: sdd-design
description: "Create the SDD technical design and architecture approach. Trigger: orchestrator launches design for a change."
delegate_only: true
triggers: "SDD design, design phase, technical design, architecture design, sdd-design"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2408
---
# SDD — Design Phase
Creates the technical design and architecture approach for a change. Triggered by the orchestrator when moving from proposal to implementation.
## Protocol
Follow **Section A** (skill loading) + **Section C** (persistence) from `skills/_shared/sdd-phase-common.md`.
**Do NOT launch sub-agents** — EXECUTOR phase. Do the design yourself.
## What to Produce
### 1. Architecture Decision
Chosen architecture (Clean/Hex/Screaming) · bounded contexts, modules, dependency flow · ports-and-adapters, event-driven, CQRS, or monolith-modules · justify vs alternatives.
### 2. Data Design
Schema changes · migration strategy (compat vs breaking) · validation layers/boundaries.
### 3. API Design
Affected endpoints · request/response shape (OpenAPI/schema) · error conventions.
### 4. Security & Compliance
Trust boundaries · auth/authz changes · secrets handling · privacy impact (GDPR/CPPA) if data touched.
### 5. Testing Strategy
Unit plan (key edge cases) · integration plan (boundaries) · risk-based coverage of 7 risk factors:
1. Cross-context boundary (shared mutable state)
2. File I/O, network I/O
3. Async or concurrent execution
4. Complex branching / cyclomatic >60
5. Non-testable code (singletons, global state, private methods)
6. Performance-critical paths (caching, N+1, loops)
7. Error path / exception handling
---
> See [reference.md](docs/skills/sdd-design/reference.md) for extended details, examples, and patterns.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: sdd | sdd-propose

