---
name: sdd-design
description: "Create technical design documents with architecture decisions, data flow diagrams, file change plans, and testing approach"
triggers: "Technical design, HOW"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches design.
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-design` sub-agent.Executor sub-agent? → proceed.
## SECTIONS- Technical Approach: strategy→proposal- Decisions: choice/alternatives/rationale- Data Flow: ASCII diagram- File Changes: path/action/description- Interfaces: new APIs/types- Testing: layer→what→approach- Migration: data/feature flags/rollout (or "none")- Open Questions: unresolved
## RULES- Read actual code, not guess- Every decision rationale- Use project ACTUAL patterns- ASCII: clarity>beauty
## EXAMPLE DECISIONS TABLE
| Decision | Chosen | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| State management | Zustand | Redux, Context | Minimal boilerplate, TS-native |
| API client | fetch wrapper | axios, react-query | Zero deps, already in codebase |
| Routing | React Router v7 | TanStack Router | Existing + well-documented |
## ASCII DIAGRAM EXAMPLE
```
[Client] → POST /api/profile
             ↓
        [Middleware] → validate JWT
             ↓
        [Handler] → update profile
             ↓
        [Database] → UPDATE users SET ...
             ↓
        [Response] → { success: true }
```
## EDGE CASES
- "Open Questions" section is MANDATORY, not optional — unresolved items block the pipeline
- Migration section: "none" is explicit, not implied
