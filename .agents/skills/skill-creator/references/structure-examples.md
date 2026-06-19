# Skill Structure Examples

## Minimal Skill (single file)
```
skills/my-skill/
└── SKILL.md
```

## Standard Skill (with structure)
```
skills/my-skill/
├── SKILL.md
├── references/
│   └── examples.md
└── assets/
    └── template.md
```

## Composite Skill (multiple phases)
```
skills/sdd/
├── SKILL.md
├── references/
│   ├── sdd-flow.md
│   └── templates/
└── phases/
    ├── explore.md
    └── design.md
```

## Frontmatter Template
```markdown
---
name: my-skill
description: "One-line description"
triggers: "comma, separated, triggers"
license: MIT
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.0"
---
```
