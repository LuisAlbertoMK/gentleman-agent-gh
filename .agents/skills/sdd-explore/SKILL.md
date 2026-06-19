---
name: sdd-explore
description: "Investigate codebase to understand requirements, entry points, patterns, and dependencies before design decisions"
triggers: "Explore codebase, pre-design"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches exploration.
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-explore` sub-agent.Executor sub-agent? → proceed.
## STEPS1.Understand req: feature? bug? refactor? domain?2.Investigate: entry points, related func, existing tests, patterns, deps3.Analyze options: pros/cons/complexity table4.Persist (named change only)5.Return structured analysis
## EXAMPLE OUTPUT
```markdown
## Requirements
- Feature: user profile editing
- Domain: src/routes/profile/, src/store/user/
## Investigation
| Area | Findings |
|------|----------|
| Entry points | src/routes/profile/edit.tsx (GET+PUT handlers) |
| Existing tests | tests/routes/profile/edit.test.ts (60% coverage) |
| Patterns | Form + validation → PUT handler → store update |
## Options
| Option | Complexity |
|--------|------------|
| Inline form in route | Small |
| Shared ProfileForm component | Medium (reusable) |
## Recommendation
Shared ProfileForm — reusable across account pages.
```
## EDGE CASES
- Auth-only endpoints: verify session before exploring
- Missing tests: flag as risk in analysis
- No clear entry point: search by route pattern, not by filename
