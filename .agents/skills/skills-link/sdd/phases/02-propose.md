---
name: sdd-propose
description: "Define change proposals with scope, capabilities, approach, risks, rollback plan, and success criteria"
triggers: "Proposal, intent, approach"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.1"
---

Trigger: Orchestrator launches proposal creation.

Common protocol: `{file:sdd/references/sdd-phase-common.md}`

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-propose` sub-agent.
Executor sub-agent? → proceed.

## SECTIONS
- Intent: WHY needed
- Scope: In/Out of
- Capabilities: NEW (→new spec)/MODIFIED (→delta) requirements
- Approach: technical strategy
- Affected Areas: file path/impact/description
- Risks: likelihood/mitigation
- Rollback: how to revert
- Success Criteria: checkboxes

## RULES
- MUST have rollback + success criteria
- Capabilities contract with sdd-spec (research existing specs!)
- Size: <450 words

## EXAMPLE
```markdown
## Intent
Allow users to edit their display name from the profile page.
## Scope
**In:** Profile edit form, PUT /profile/name endpoint
**Out:** Avatar upload, email change
## Capabilities
- **NEW:** PUT /profile/name { displayName: string }
- **MODIFIED:** ProfileEdit.tsx (add name field)
## Risks
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Empty name | Medium | Server-side validation |
| Profanity | Low | Optional sanitize step |
```

## EDGE CASES
- Capabilities reference existing specs with `sdd-spec` (may not exist yet → create during spec phase)
- Rollback for DB-mutating changes: include rollback script or migration revert
