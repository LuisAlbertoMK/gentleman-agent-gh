---
name: skill-creator
description: >
  Create new AI agent skills following the Agent Skills spec.
  Trigger: User asks to create skill, add agent instructions, document patterns.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
Pattern repeated + AI needs guidance · Project-specific conventions · Complex workflows · Decision trees needed

**Don't create:** Docs exist (reference instead) · Trivial pattern · One-off task

## Structure
```
skills/{name}/
├── SKILL.md          # Required
├── assets/           # Templates, schemas, examples
└── references/       # Local doc links
```

## SKILL.md Template
```markdown
---
name: {name}
description: >
  {One-line}. Trigger: {when}.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## When
{when}

## Critical Patterns
{Must-know rules}

## Components
{Minimal examples}

## Resources
- **Assets**: [assets/](assets/)
- **Docs**: [references/](references/)
```

## Naming
| Pattern | Example |
|---------|---------|
| `{tech}` | `pytest`, `typescript` |
| `{project}-{component}` | `myapp-api` |
| `{action}-{target}` | `skill-creator` |

## Content Rules
**DO:** Critical patterns first · Tables for decisions · Minimal examples · Commands section
**DON'T:** Keywords · Duplicate docs · Verbose explanations · Web URLs

## Register
Add to AGENTS.md:
```
| `{name}` | {desc} | [SKILL.md](skills/{name}/SKILL.md) |
```

## Checklist
Before creating: skill doesn't exist? reusable? name follows convention? frontmatter complete? critical patterns clear? examples minimal? commands exist? AGENTS.md updated?
