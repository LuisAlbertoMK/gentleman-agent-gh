---
name: skill-registry
description: "Build and maintain skill registry — scan skill directories, deduplicate across sources, compact rules, and persist to engram"
triggers: "Skill registry, catalog"
license: MIT
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.0"
---

Trigger: "update skills", after install/remove skills.
## STEPS1. Scan: ~/.config/opencode/skills/*/, ~/.claude/skills/, project .claude/.gemini/.agent/skills/   Skip: sdd-*, _shared, skill-registry   Dedupe: project-level wins2. Compact rules: 5-15 lines, actionable, NO fluff3. Conventions: agents.md/CLAUDE.md/.cursorrules/GEMINI.md → extract paths4. Write: .atl/skill-registry.md + mem_save
## OUTPUT
```markdown# Registry
## Skills | Trigger | Skill | Path |
## Compact Rules |
### {name} - Rule1 |
## Conventions | File | Path |
```
## RULES- ALWAYS write .atl/skill-registry.md- ALWAYS mem_save if available- Compact rules: 5-15 lines each- NO skills → write empty registry
## EXAMPLE REGISTRY
```
## Skills
| Trigger | Skill | Path |
| archive, revert | sdd-archive | .agents/skills/sdd-archive/SKILL.md |
| code review, 4R | code-review-agent | .agents/skills/code-review-agent/SKILL.md |
| commit | commit-crafter | .agents/skills/commit-crafter/SKILL.md |
```
## DEDUPLICATION RULES
- Project-level skills WIN over global (~/.config/opencode/)
- Same trigger on multiple skills → keep the more specific one
- Identical rules → merge, keep the shorter version
- Empty or skeleton skills (only frontmatter) → skip
