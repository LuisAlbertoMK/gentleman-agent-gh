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
## GATEOrchestrator loaded this? → STOP, delegate to `sdd-spec` sub-agent.Executor sub-agent? → proceed.
## DELTA FORMAT
```markdown
## ADDED |
### Requirement | RFC 2119 | GIVEN→WHEN→THEN
## MODIFIED |
### Requirement | (Previously: X) | updated scenarios
## REMOVED |
### Requirement | (Reason:)
```
## MODIFIED (critical)1. COPY ENTIRE req block (req + ALL scenarios) from main spec2. PASTE under MODIFIED → EDIT3. ADD `(Previously: one-liner)`Why full block? Archive REPLACES — partial loses scenarios.
## NEW SPEC (no existing)Purpose → Requirements (MUST/SHOULD/MAY) → G/W/T scenarios
## RULES- G/W/T · RFC 2119: MUST/SHALL/SHOULD/MAY- Every req ≥1 scenario (happy+edge) · Testable · No impl- MODIFIED = FULL block · Budget: <650 words
