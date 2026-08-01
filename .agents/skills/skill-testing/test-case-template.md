# Test Case Templates — skill-testing

## Basic Test Case

```markdown
## TC-[number]: [nombre]

### Skill
[nombre]

### Trigger
[condición]

### Input
[test input]

### Expected
[output esperado]

### Actual
[output real]

### Result
✅ PASS | ❌ FAIL

### Fix (if FAIL)
[qué cambiar]
```

## Coverage Matrix Template

```markdown
## Coverage: [skill name]

| Requirement | Covered | Test | Notes |
|-------------|---------|------|-------|
| [req 1] | ✅ | TC-1 | |
| [req 2] | ❌ | - | Missing |
| [req 3] | ✅ | TC-2 | |
```

## Report Template

```markdown
# Skill Test Report

## Metadata
- Skill: [name]
- Version: [vX.Y]
- Date: [ISO]
- Tester: [agent name]

## Results Summary
| Test | Status | Score |
|------|--------|-------|
| Syntax | ✅ | 10/10 |
| Coverage | ⚠️ | 7/10 |
| Integration | ✅ | 9/10 |
| Usability | ✅ | 8/10 |
| **TOTAL** | | **8.5/10** |

## Issues
### Critical
- [issue]

### Warnings
- [warning]

## Verdict
⚠️ NEEDS IMPROVEMENT

## Required Changes
1. [change 1]
2. [change 2]

## Next Steps
[acción]
```
