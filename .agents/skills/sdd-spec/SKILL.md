---
name: sdd-spec
description: "Write detailed specifications with Given/When/Then scenarios using RFC 2119 requirements language (MUST/SHOULD/MAY)"
triggers: "Specs, Given/When/Then"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.3"
---

Trigger: Orchestrator launches specs.
## GATEOrchestrator loaded this? â†’ STOP, delegate to `sdd-spec` sub-agent.Executor sub-agent? â†’ proceed.
## DELTA FORMAT
```markdown
## ADDED |
### Requirement | RFC 2119 | GIVENâ†’WHENâ†’THEN
## MODIFIED |
### Requirement | (Previously: X) | updated scenarios
## REMOVED |
### Requirement | (Reason:)
```
## MODIFIED (critical)1. COPY ENTIRE req block (req + ALL scenarios) from main spec2. PASTE under MODIFIED â†’ EDIT3. ADD `(Previously: one-liner)`Why full block? Archive REPLACES â€” partial loses scenarios.
## NEW SPEC (no existing)Purpose â†’ Requirements (MUST/SHOULD/MAY) â†’ G/W/T scenarios
## RULES- G/W/T Â· RFC 2119: MUST/SHALL/SHOULD/MAY- Every req â‰¥1 scenario (happy+edge) Â· Testable Â· No impl- MODIFIED = FULL block Â· Budget: <650 words
