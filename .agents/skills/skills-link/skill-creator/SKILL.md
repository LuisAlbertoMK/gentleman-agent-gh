---
name: skill-creator
description: "Create new AI agent skills following Agent Skills spec -- auto-bootstrap unknown tasks, define structure, register in AGENTS.md"
triggers: "Create AI skill"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.1->1.2 (Karpathy compress: 2551->1700B)"
---

## When
Pattern repeated + AI needs guidance | Project conventions | Complex workflows | Decision trees | Pre-Flight Gate (unknown task)
**Don't create:** Docs exist | Trivial | One-off

## Auto-Bootstrap (unknown task)
1. Research domain (websearch, context7)
2. Create minimal skill: name, description, key patterns
3. Register in AGENTS.md trigger table
4. Proceed with original task
5. Refine with real experience (gotchas, edge cases)

## Structure
`skills/{name}/SKILL.md` (required) | `assets/` (templates) | `references/` (local docs)

## SKILL.md template
```markdown
---
name: {name}
description: "{1-liner}"
triggers: "{trigger words}"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---
## When
{trigger scenario}
## Critical Patterns
{essential rules}
## Components
{minimal examples}
## Resources
```

## Naming
| Pattern | Example |
|---------|---------|
| `{tech}` | `pytest`, `typescript` |
| `{project}-{component}` | `myapp-api` |
| `{action}-{target}` | `skill-creator` |

## Content Rules
**DO:** Critical patterns first | Tables for decisions | Minimal examples | Commands
**DON'T:** Keywords | Duplicate docs | Verbose explanations | Web URLs

## Register in AGENTS.md
`| {name} | {desc} | [SKILL.md](skills/{name}/SKILL.md) |`

## Edge cases
- Name collision -> `-2` suffix, note in AGENTS.md
- Empty `references/` -> omit dir entirely
- Triggers must match real user language -- test with real queries
- Experimental -> `# experimental` note, skip registration
