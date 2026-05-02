---
name: sdd-spec
description: > Write specs: requirements + scenarios (delta).
  Trigger: Orchestrator launches specs.
license: MIT
metadata: author: gentleman-programming, version: "2.0"
---

## DELTA FORMAT
```markdown
# Delta for {Domain}
## ADDED | ### Requirement | RFC 2119 | Scenario | GIVEN→WHEN→THEN
## MODIFIED | ### Requirement | (Previously: summary) | updated scenarios
## REMOVED | ### Requirement | (Reason:)
```

## MODIFIED WORKFLOW (CRITICAL)
1. Find requirement in main spec
2. COPY entire block (requirement + ALL scenarios)
3. PASTE under MODIFIED
4. EDIT for new behavior
5. ADD (Previously: one-liner)

## RULES
- Given/When/Then per scenario
- RFC 2119: MUST/SHALL/SHOULD/MAY
- Every req ≥1 scenario (happy+edge)
- Testable scenarios
- NO impl details (WHAT not HOW)
- MODIFIED = FULL block