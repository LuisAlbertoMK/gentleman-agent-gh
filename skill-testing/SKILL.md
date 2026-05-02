---
name: skill-testing
description: >
  Test/verify created skills.
  Trigger: After creating/modifying skill, before production use.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
After new skill created · After skill modified · Pre-critical-task verification · Periodic active skill checks

## Framework
```
Test → Verify → Score → Approve/Reject
```

## Test Types
**1. Syntax:** frontmatter complete · Header structure correct · Assets exist · Triggers unique/clear
**2. Coverage:** primary use case · domain edge cases · basic templates · anti-patterns documented
**3. Integration:** Load skill via trigger → Apply to test case → Verify correct output
**4. Tokens:** Avg prompt < X tokens · Longest template < Y tokens · Decision tree legible

## Checklist by Type
### Prompt Skill
□ Frontmatter complete □ Method/framework documented □ Templates per use case
□ Anti-patterns □ Concrete examples □ Resources linked □ Triggers clear

### Workflow Skill
□ Sequential steps clear □ Decisions documented □ Error handling
□ Example commands □ Test cases

### Template Skill
□ Complete structure □ Clear placeholders □ Usage examples □ Variations documented

## Test Case Template
```markdown
## Test Case: [name]
**Skill**: [name] | **Trigger**: [condition]
**Input**: [test input]
**Expected**: [expected output]
**Actual**: [real output]
**Result**: ✅ PASS / ❌ FAIL
**Notes**: [observations]
```

## Scoring
| Criteria | Weight | Score |
|----------|--------|-------|
| Syntax | 20% | X/10 |
| Coverage | 30% | X/10 |
| Integration | 30% | X/10 |
| Usability | 20% | X/10 |
| **TOTAL** | 100% | X/10 |

**Thresholds:** 9-10: ✅ Production | 7-8: ⚠️ Needs improvement | <7: ❌ Do not use

## Default Test Cases
### All skills
1. Syntax: frontmatter parsing
2. Structure: required sections exist
3. Links: referenced assets exist
4. Triggers: clear and unique
5. Format: valid markdown

### Prompt skills (+)
6. Token budget: templates under limit
7. Templates: ≥3 examples
8. Anti-patterns: documented
9. Decision tree: if applicable

### Workflow skills (+)
6. Steps: sequential and clear
7. Errors: handled explicitly
8. Commands: executable
9. Examples: ≥1

## Report Template
```markdown
## Skill Test Report
**Skill**: [name] | **Date**: [ISO] | **Version**: [v1.X]
### Results
| Test | Status | Notes |
| Syntax | ✅ | |
### Coverage Matrix
| Required | Covered | Missing |
| [item] | ✅/❌ | [if missing] |
### Recommendations
- [rec 1]
### Verdict
✅ APPROVED / ⚠️ NEEDS WORK / ❌ REJECTED
```
