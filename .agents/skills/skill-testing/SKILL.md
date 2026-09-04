---
name: skill-testing
description: "Test and verify skill quality — syntax, coverage, integration, and token budget assessment before production use"
triggers: "Test/verify skill, coverage"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2600
---
Trigger: After creating/modifying skill, before production use.
## When to Use
After new/edited skill · pre-critical-task verification · periodic active skill checks.
## Framework
`Test → Verify → Score → Approve/Reject`
## Test Types
1. **Syntax**: frontmatter complete · Headers correct · Assets exist · Triggers unique
2. **Coverage**: primary use case · edge cases · templates · anti-patterns
3. **Integration**: Load via trigger → Apply → Verify output
4. **Tokens**: Avg prompt < X · Longest template < Y · Decision tree legible
## Scoring
| Criteria | Weight |
|----------|--------|
| Syntax | 20% |
| Coverage | 30% |
| Integration | 30% |
| Usability | 20% |
**Thresholds**: 9-10: ✅ Production | 7-8: ⚠ Needs work | <7: ❌ Reject
## Default Tests (ALL skills)
1. Syntax: frontmatter parses 2. Structure: required sections exist 3. Links: assets exist (if referenced) 4. Triggers: clear and unique 5. Format: valid markdown
## Report Template
```markdown
## Skill Test Report | {name} | {version}| Test | Status || Syntax | ✅/❌ |
### Verdict: ✅ APPROVED / ⚠ NEEDS WORK / ❌ REJECTED
```
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "saltarse integration test si syntax-pass" | Syntax ✅ pero Integration no corrida | Framework Test 3: Load→Apply→Verify output obligatorio |
| "aceptar cobertura sin casos edge" | Coverage alto sin edge/templates | Scoring Coverage 30% incluye primary+edge+templates |
| "token budget es detalle de implementación" | Pattern 3: budget ignorado/template >Y | Tokens check avg <X / longest <Y + decision tree legible |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
skill-registry · opencode-skill-creator · skill-improver · quality-gate · karpathy-loop · skill-graph
## Reference
Checklist by type (Prompt/Workflow/Template) + per-type extras → docs/skills/skill-testing/reference.md
---

