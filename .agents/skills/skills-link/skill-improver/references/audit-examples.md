# Skill Audit Example

## Audit Report Snippet
```markdown
## skill-digestion (3.2KB, 1 file)
- [INFO] Frontmatter: OK
- [INFO] Triggers: match usage
- [WARN] Body <30 lines → expand with examples
- Action: add examples in references/

## skill-improver (merged from skill-refresher, 1 file)  
- [INFO] Frontmatter: OK
- [WARN] Body <30 lines → expand
- Action: add health signal examples
```

## Conversion: Tutorial → Rules

### Before (tutorial prose)
```
When you want to create a skill, first you should check if it
already exists. Then think about what triggers would work best.
Make sure the name follows the naming convention.
```

### After (actionable rules)
```
- Check skill doesn't exist before creating
- Triggers must match actual user language
- Name follows {tech}|{project}-{component}|{action}-{target} pattern
```

## Deprecation Check
| Signal | Action |
|--------|--------|
| Not loaded in 90d | Flag deprecated |
| Loaded but never applied | Narrow triggers |
| Superseded by another skill | Merge or replace |
