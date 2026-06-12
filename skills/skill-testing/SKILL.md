---
name: skill-testing
description: >
  skill-testing skill
triggers: "Test/verify skill, coverage"
  Trigger: After creating/modifying skill, before production use.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## When
After new/edited skill · Pre-critical-task verification · Periodic active skill checks

## Framework
`Test → Verify → Score → Approve/Reject`

## Test Types
1. **Syntax**: frontmatter complete · Headers correct · Assets exist · Triggers unique
2. **Coverage**: primary use case · edge cases · templates · anti-patterns
3. **Integration**: Load via trigger → Apply → Verify output
4. **Tokens**: Avg prompt < X · Longest template < Y · Decision tree legible

## Checklist by Type
| Type | Check |
|------|-------|
| Prompt | Frontmatter · Framework · Templates · Anti-patterns · Examples · Triggers |
| Workflow | Sequential steps · Decisions · Error handling · Commands · Test cases |
| Template | Structure · Placeholders · Examples · Variations |

## Scoring
| Criteria | Weight |
|----------|--------|
| Syntax | 20% |
| Coverage | 30% |
| Integration | 30% |
| Usability | 20% |

**Thresholds**: 9-10: ✅ Production | 7-8: ⚠️ Needs work | <7: ❌ Reject

## Default Tests (ALL skills)
1. Syntax: frontmatter parses
2. Structure: required sections exist
3. Links: assets exist (if referenced)
4. Triggers: clear and unique
5. Format: valid markdown

**Prompt skills (+):** Token budget OK · ≥3 templates · Anti-patterns · Decision tree
**Workflow skills (+):** Sequential steps · Error handling · Executable commands · ≥1 example

## Report Template
```markdown
## Skill Test Report | {name} | {version}
| Test | Status |
| Syntax | ✅/❌ |
### Verdict: ✅ APPROVED / ⚠️ NEEDS WORK / ❌ REJECTED
```

