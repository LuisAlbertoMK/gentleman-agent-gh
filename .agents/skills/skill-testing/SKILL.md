---
name: skill-testing
description: >  skill-testing skill
triggers: "Test/verify skill, coverage"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: After creating/modifying skill, before production use.
## WhenAfter new/edited skill Â· Pre-critical-task verification Â· Periodic active skill checks
## Framework`Test â†’ Verify â†’ Score â†’ Approve/Reject`
## Test Types1. **Syntax**: frontmatter complete Â· Headers correct Â· Assets exist Â· Triggers unique2. **Coverage**: primary use case Â· edge cases Â· templates Â· anti-patterns3. **Integration**: Load via trigger â†’ Apply â†’ Verify output4. **Tokens**: Avg prompt < X Â· Longest template < Y Â· Decision tree legible
## Checklist by Type| Type | Check ||------|-------|| Prompt | Frontmatter Â· Framework Â· Templates Â· Anti-patterns Â· Examples Â· Triggers || Workflow | Sequential steps Â· Decisions Â· Error handling Â· Commands Â· Test cases || Template | Structure Â· Placeholders Â· Examples Â· Variations |
## Scoring| Criteria | Weight ||----------|--------|| Syntax | 20% || Coverage | 30% || Integration | 30% || Usability | 20% |**Thresholds**: 9-10: âœ… Production | 7-8: âš ï¸ Needs work | <7: âŒ Reject
## Default Tests (ALL skills)1. Syntax: frontmatter parses2. Structure: required sections exist3. Links: assets exist (if referenced)4. Triggers: clear and unique5. Format: valid markdown**Prompt skills (+):** Token budget OK Â· â‰¥3 templates Â· Anti-patterns Â· Decision tree**Workflow skills (+):** Sequential steps Â· Error handling Â· Executable commands Â· â‰¥1 example
## Report Template
```markdown
## Skill Test Report | {name} | {version}| Test | Status || Syntax | âœ…/âŒ |
### Verdict: âœ… APPROVED / âš ï¸ NEEDS WORK / âŒ REJECTED
```
