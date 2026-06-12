---
name: skill-registry
description: > Create/update skill registry. Scan skills+conventions, write .atl/skill-registry.md.
  Trigger: "update skills", after install/remove skills.
license: MIT
metadata: author: gentleman-vMK, version: "1.0"
---

## STEPS
1. Scan: ~/.config/opencode/skills/*/, ~/.claude/skills/, project .claude/.gemini/.agent/skills/
   Skip: sdd-*, _shared, skill-registry
   Dedupe: project-level wins
2. Compact rules: 5-15 lines, actionable, NO fluff
3. Conventions: agents.md/CLAUDE.md/.cursorrules/GEMINI.md → extract paths
4. Write: .atl/skill-registry.md + mem_save

## OUTPUT
```markdown
# Registry
## Skills | Trigger | Skill | Path |
## Compact Rules | ### {name} - Rule1 |
## Conventions | File | Path |
```

## RULES
- ALWAYS write .atl/skill-registry.md
- ALWAYS mem_save if available
- Compact rules: 5-15 lines each
- NO skills → write empty registry