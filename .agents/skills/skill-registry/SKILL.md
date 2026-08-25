---
name: skill-registry
description: "Build and maintain skill registry - scan skill dirs, deduplicate across sources, compact rules, persist to engram."
triggers: "Skill registry, catalog, update skills"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1197
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

---

> See [reference.md](docs/skills/skill-registry/reference.md) for extended details, examples, and detailed patterns.
