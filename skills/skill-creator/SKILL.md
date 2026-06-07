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
Pattern repeated + AI needs guidance · Project-specific conventions · Complex workflows · Decision trees needed · **Pre-Flight Gate** (unknown task type — auto-bootstrap)

**Don't create:** Docs exist (reference instead) · Trivial pattern · One-off task

## Auto-Bootstrap Mode (Pre-Flight Gate trigger)
When the task type is unknown (no matching skill in Skill Router):
1. Research the domain quickly (websearch, context7)
2. Create minimal skill with: name, description, key patterns from research
3. Register in AGENTS.md trigger table
4. THEN proceed with the original task
5. After task: refine skill with real experience (gotchas, edge cases)

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
