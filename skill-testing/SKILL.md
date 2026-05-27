---
name: skill-testing
description: >
  Test/verify created skills.
  Trigger: After creating/modifying skill, before production use.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
After skill created/modified · Pre-critical-task · Periodic checks

## Framework
```
Test → Verify → Score → Approve/Reject
```

## Test Types
| Type | What | Example |
|------|------|---------|
| Syntax | Frontmatter, headers, triggers | `name:` present? headers match? |
| Coverage | Use cases, edge cases, anti-patterns | All states handled? |
| Integration | Load → apply → verify output | Trigger matches? output correct? |
| Tokens | Within budget | Avg prompt <N, longest <M |

## Checklist
### Prompt Skill
Frontmatter? □ Method documented? □ Templates per case? □ Anti-patterns? □ Examples? □ Resources? □ Triggers clear?

### Workflow Skill
Steps sequential? □ Decisions documented? □ Error handling? □ Example commands? □

### Template Skill
Complete structure? □ Clear placeholders? □ Usage examples? □ Variations? □

## Test Case Template
```
## Test Case: [name]
**Skill**: [n] | **Trigger**: [c]
**Input**: [i] | **Expected**: [e] | **Actual**: [a]
**Result**: ✅/❌ | **Notes**: [obs]
```

## Scoring
| Criteria | Weight |
|----------|--------|
| Syntax | 20% |
| Coverage | 30% |
| Integration | 30% |
| Usability | 20% |

Thresholds: 9-10 ✅ Production · 7-8 ⚠️ Needs work · <7 ❌ Reject

## Default Cases
### Universal
1. Syntax parsing 2. Required sections 3. Linked assets exist 4. Triggers unique 5. Valid markdown

### Prompt skills (+)
6. Token budget 7. ≥3 templates 8. Anti-patterns 9. Decision tree

### Workflow skills (+)
6. Sequential steps 7. Error handling 8. Executable commands 9. ≥1 example

## Report Template
```
## Skill Test Report
**Skill**: [n] | **Date**: [d] | **Version**: [v]
### Results | Test | Status | Notes |
### Verdict: ✅ APPROVED / ⚠️ NEEDS WORK / ❌ REJECTED
```
