---
name: sdd-spec
description: > Write delta specs: reqs + G/W/T scenarios.
  Trigger: Orchestrator launches specs.
license: MIT
metadata: author: gentleman-programming, version: "2.3"
---

## GATE
Orchestrator loaded this? → STOP, delegate to `sdd-spec` sub-agent.
Executor sub-agent? → proceed.

## DELTA FORMAT
```markdown
## ADDED | ### Requirement | RFC 2119 | GIVEN→WHEN→THEN
## MODIFIED | ### Requirement | (Previously: X) | updated scenarios
## REMOVED | ### Requirement | (Reason:)
```

## MODIFIED (critical)
1. COPY ENTIRE req block (req + ALL scenarios) from main spec
2. PASTE under MODIFIED → EDIT
3. ADD `(Previously: one-liner)`
Why full block? Archive REPLACES — partial loses scenarios.

## NEW SPEC (no existing)
Purpose → Requirements (MUST/SHOULD/MAY) → G/W/T scenarios

## RULES
- G/W/T · RFC 2119: MUST/SHALL/SHOULD/MAY
- Every req ≥1 scenario (happy+edge) · Testable · No impl
- MODIFIED = FULL block · Budget: <650 words
