---
name: skill-creator
description: "Create new AI agent skills following Agent Skills spec � auto-bootstrap unknown tasks, define structure, register in AGENTS.md"
triggers: "Create AI skill"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
---

Create new AI agent skills following the Agent Skills spec.Trigger: User asks to create skill, add agent instructions, document patterns.
## WhenPattern repeated + AI needs guidance · Project-specific conventions · Complex workflows · Decision trees needed · **Pre-Flight Gate** (unknown task type — auto-bootstrap)**Don't create:** Docs exist (reference instead) · Trivial pattern · One-off task
## Auto-Bootstrap Mode (Pre-Flight Gate trigger)When the task type is unknown (no matching skill in Skill Router):1. Research the domain quickly (websearch, context7)2. Create minimal skill with: name, description, key patterns from research3. Register in AGENTS.md trigger table4. THEN proceed with the original task5. After task: refine skill with real experience (gotchas, edge cases)
## Structure
```skills/{name}/├── SKILL.md          # Required├── assets/           # Templates, schemas, examples└── references/       # Local doc links```
## SKILL.md Template
```markdown---name: {name}description: >  skill-creator skilltriggers: "Create AI skill"  {One-line}. Trigger: {when}.license: Apache-2.0metadata: author: gentleman-vMK, version: "1.0"---
## When{when}
## Critical Patterns{Must-know rules}
## Components{Minimal examples}
## Resources- **Assets**: [assets/](assets/)- **Docs**: [references/](references/)
```
## Naming| Pattern | Example ||---------|---------|| `{tech}` | `pytest`, `typescript` || `{project}-{component}` | `myapp-api` || `{action}-{target}` | `skill-creator` |
## Content Rules**DO:** Critical patterns first · Tables for decisions · Minimal examples · Commands section**DON'T:** Keywords · Duplicate docs · Verbose explanations · Web URLs
## RegisterAdd to AGENTS.md:
```| `{name}` | {desc} | [SKILL.md](skills/{name}/SKILL.md) |```
## ChecklistBefore creating: skill doesn't exist? reusable? name follows convention? frontmatter complete? critical patterns clear? examples minimal? commands exist? AGENTS.md updated?
