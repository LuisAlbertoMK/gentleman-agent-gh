---
name: skill-testing
description: "Test and verify skill quality — syntax, coverage, integration, and token budget assessment before production use"
triggers: "Test/verify skill, coverage"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: initial tracked version"
---

Trigger: After creating/modifying skill, before production use.
## WhenAfter new/edited skill · Pre-critical-task verification · Periodic active skill checks
## Framework`Test → Verify → Score → Approve/Reject`
## Test Types1. **Syntax**: frontmatter complete · Headers correct · Assets exist · Triggers unique2. **Coverage**: primary use case · edge cases · templates · anti-patterns3. **Integration**: Load via trigger → Apply → Verify output4. **Tokens**: Avg prompt < X · Longest template < Y · Decision tree legible
## Checklist by Type| Type | Check ||------|-------|| Prompt | Frontmatter · Framework · Templates · Anti-patterns · Examples · Triggers || Workflow | Sequential steps · Decisions · Error handling · Commands · Test cases || Template | Structure · Placeholders · Examples · Variations |
## Scoring| Criteria | Weight ||----------|--------|| Syntax | 20% || Coverage | 30% || Integration | 30% || Usability | 20% |**Thresholds**: 9-10: ✅ Production | 7-8: ⚠ Needs work | <7: ❌ Reject
## Default Tests (ALL skills)1. Syntax: frontmatter parses2. Structure: required sections exist3. Links: assets exist (if referenced)4. Triggers: clear and unique5. Format: valid markdown**Prompt skills (+):** Token budget OK · ≥3 templates · Anti-patterns · Decision tree**Workflow skills (+):** Sequential steps · Error handling · Executable commands · ≥1 example
## Report Template
```markdown
## Skill Test Report | {name} | {version}| Test | Status || Syntax | ✅/❌ |
### Verdict: ✅ APPROVED / ⚠ NEEDS WORK / ❌ REJECTED
```

## Refs
skill-registry · opencode-skill-creator · skill-improver · quality-gate · karpathy-loop

## Anti-Patterns
Test only syntax, skip integration · Never verify triggers · Ship with <7 score · Skip token budget check · Test without real prompts

## Example: Test Report
```markdown
## Skill Test Report | server-commands | 1.0
| Test | Status |
| Frontmatter valid | ✅ |
| Required sections | ✅ |
| Triggers unique | ✅ |
| Token budget (<500 tokens) | ✅ (~180) |
| Integration (load + apply) | ✅ |
### Verdict: ✅ APPROVED (9.2/10)
```
