# Skill Template

Reference template for creating new OpenCode skills. Copy this structure.

## Required Sections

```markdown
---
name: skill-name
description: "One-line description — what it does, not how"
triggers: "keyword1, keyword2, keyword3, !shortcut"
license: Apache-2.0
metadata:
  tags: [category1, category2]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial creation"
  dependencies: []  # other skills this requires
---

## When to Use
- Concrete trigger scenarios (3-5 bullets)
- "When the user asks about X"
- "Triggered by Y pattern"

## Core Rules
1. **Rule name**: Description (imperative, actionable)
2. **Rule name**: Description
3. Keep to 3-7 rules. More = noise.

## Anti-Patterns
- What NOT to do (1-line each, 3-5 items)
- "Skip validation" · "Ignore errors" · "Hardcode values"

## Example
One worked example showing correct usage.
Include code snippet if applicable.

## Refs
Links to related skills, external docs, or standards.
```

## Checklist Before Shipping

- [ ] Frontmatter valid (YAML parseable)
- [ ] Triggers are unique (no overlap with other skills)
- [ ] Description is one line, <120 chars
- [ ] At least one concrete example
- [ ] Token budget <500 tokens (~2KB)
- [ ] No dead references (cross-ref check passes)
- [ ] Test with 2-3 real prompts

## Quality Levels

| Level | Lines | Tokens | When |
|-------|-------|--------|------|
| Minimal | 15-25 | ~100 | Simple reference card |
| Standard | 30-50 | ~200 | Most skills |
| Detailed | 50-80 | ~350 | Complex workflows |
| Maximum | 80-100 | ~500 | Full pipeline orchestration |

## Anti-Patterns to Avoid

- **Tutorial prose**: "First, you need to..." → Use imperative: "Do X"
- **Missing examples**: Every skill needs at least one worked example
- **Over-abstraction**: Don't create a skill for something a one-liner handles
- **Stale triggers**: Triggers that don't match real user requests
- **Missing anti-patterns**: What NOT to do is as important as what to do
