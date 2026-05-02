---
name: skill-creator
description: >
  Create new AI agent skills following the Agent Skills spec.
  Trigger: User asks to create skill, add agent instructions, document patterns.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
Pattern repeated + AI needs guidance · Project-specific conventions · Complex workflows · Decision trees needed

**Don't create:** Documentation exists (reference instead) · Trivial pattern · One-off task

## Structure
```
skills/{skill-name}/
├── SKILL.md          # Required
├── assets/           # Optional: templates, schemas, examples
└── references/       # Optional: links to local docs
```

## SKILL.md Template
```markdown
---
name: {skill-name}
description: >
  {One-line what it does}. Trigger: {When to load}.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use
{When to use}

## Critical Patterns
{Most important rules — what AI MUST know}

## Code Examples
{Minimal, focused}

## Commands
```bash
{Common commands}
```

## Resources
- **Templates**: [assets/](assets/) for {description}
- **Docs**: [references/](references/) for local docs
```

## Naming
| Type | Pattern | Examples |
|------|---------|----------|
| Generic | `{technology}` | `pytest`, `typescript` |
| Project-specific | `{project}-{component}` | `myapp-api` |
| Testing | `{project}-test-{component}` | `myapp-test-sdk` |
| Workflow | `{action}-{target}` | `skill-creator` |

## Frontmatter
| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens |
| `description` | Yes | What + Trigger |
| `license` | Yes | `Apache-2.0` |
| `metadata.author` | Yes | `gentleman-programming` |
| `metadata.version` | Yes | Semver as string |

## Content Guidelines
**DO:** Critical patterns first · Tables for decision trees · Minimal examples · Commands section
**DON'T:** Keywords section · Duplicate docs · Lengthy explanations · Troubleshooting · Web URLs in references

## assets/ vs references/
Templates/schemas/configs → assets/ · Link to existing docs → references/ (local paths only)

## Register
Add to `AGENTS.md`:
```markdown
| `{skill-name}` | {Description} | [SKILL.md](skills/{skill-name}/SKILL.md) |
```

## Checklist
- [ ] Skill doesn't already exist
- [ ] Pattern is reusable (not one-off)
- [ ] Name follows conventions
- [ ] Frontmatter complete (description includes triggers)
- [ ] Critical patterns clear
- [ ] Examples minimal
- [ ] Commands section exists
- [ ] Added to AGENTS.md
