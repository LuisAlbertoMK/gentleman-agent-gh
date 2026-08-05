---
name: skill-registry
description: "Build and maintain skill registry - scan skill dirs, deduplicate across sources, compact rules, persist to engram."
triggers: "Skill registry, catalog"
---

## When to Use
Build and maintain skill registry — scan, dedupe, compact, persist. Trigger: "update skills", after install/remove skills.

## Steps
1. Scan: `~/.config/opencode/skills/*/`, `~/.claude/skills/`, project `.claude/.gemini/.agent/skills/` — skip `sdd-*`, `_shared`, `skill-registry`; dedupe: project-level wins
2. Compact rules: 5-15 lines, actionable, NO fluff
3. Conventions: `agents.md`/`CLAUDE.md`/`.cursorrules`/`GEMINI.md` → extract paths
4. Write: `.atl/skill-registry.md` + `mem_save`

## Output
```markdown
# Registry

| Skills | Trigger | Skill | Path |
| Compact Rules | | | |
| {name} | Rule1 | | |
| Conventions | File | Path | |
```

## Rules
- ALWAYS write `.atl/skill-registry.md`
- ALWAYS `mem_save` if available
- Compact rules: 5-15 lines each
- NO skills → write empty registry

## Example Registry
```
## Skills
| Trigger | Skill | Path |
| archive, revert | sdd-archive | .agents/skills/sdd-archive/SKILL.md |
| code review, 4R | code-review-agent | .agents/skills/code-review-agent/SKILL.md |
| commit | commit-crafter | .agents/skills/commit-crafter/SKILL.md |
```

## Deduplication Rules
- Project-level skills WIN over global (~/.config/opencode/)
- Same trigger on multiple skills → keep the more specific one
- Identical rules → merge, keep the shorter version
- Empty or skeleton skills (only frontmatter) → skip

## Refs
skill-graph · skill-testing · skill-improver · opencode-skill-creator · dreaming

## Anti-Patterns
Include sdd-* sub-skills in registry · Dedupe to global when project has override · Keep stale entries · Skip mem_save after update
