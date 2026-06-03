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

## MODIFIED WORKFLOW (critical)
1. LOCATE req in main spec → COPY ENTIRE BLOCK (req + ALL scenarios)
2. PASTE under MODIFIED → EDIT for new behavior
3. ADD `(Previously: one-liner)`
Why copy-full? Archive step REPLACES the block — partial loses scenarios.

## NEW SPEC (no existing spec)
Full spec: Purpose → Requirements (MUST/SHOULD/MAY) → G/W/T scenarios

## RULES
- G/W/T per scenario · RFC 2119: MUST/SHALL/SHOULD/MAY
- Every req ≥1 scenario (happy+edge) · Testable · No impl details
- MODIFIED = FULL block (not partial)
- Size budget: <650 words, prefer tables over narrative
