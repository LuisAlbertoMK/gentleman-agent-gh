---
name: sdd-spec
description: > Write delta specs: reqs + G/W/T scenarios.
  Trigger: Orchestrator launches specs.
license: MIT
metadata: author: gentleman-programming, version: "2.2"
---

## DELTA FORMAT
```markdown
## ADDED | ### Requirement | RFC 2119 | GIVEN→WHEN→THEN
## MODIFIED | ### Requirement | (Previously: X) | updated scenarios
## REMOVED | ### Requirement | (Reason:)
```

## MODIFIED
1. Find req in main spec → COPY ENTIRE BLOCK
2. PASTE under MODIFIED → EDIT for new behavior
3. ADD `(Previously: one-liner)`

## RULES
- G/W/T per scenario · RFC 2119: MUST/SHALL/SHOULD/MAY
- Every req ≥1 scenario (happy+edge) · Testable · No impl details
- MODIFIED = FULL block (not delta)
