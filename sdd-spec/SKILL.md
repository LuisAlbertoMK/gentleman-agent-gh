---
name: sdd-spec
description: >
  Write specs from proposal. Triggers: "sdd spec", "create specs".
---

## From proposal.md

## Spec Structure
```markdown
# Spec: {change}

## Requisitos
- {req 1}
- {req 2}

## Scenarios
### {scenario 1}
- Given: {ctx}
- When: {action}
- Then: {result}

### {scenario 2}
- Given: {ctx}
- When: {action}
- Then: {result}

## Edge Cases
- {case}: {handling}

## Acceptance Criteria
- [ ] {crit 1}
- [ ] {crit 2}
```

## Output
- Save: `sdd/{change}/spec`
- mem_save: title "sdd-spec/{change}"

* sdd-spec v2.0 — Karpathy Optimized *