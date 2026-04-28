---
name: skill-registry
description: >
  Create/regenerate skill registry. Triggers: "update skills", "skill registry", "actualizar skills".
---

## Purpose
Generate catalog de skills con **compact rules** (5-15 líneas) para inject en sub-agent prompts.

## When
- After install/remove skills
- New project setup
- User pide update
- Part of sdd-init

## Steps

### 1. Scan Skills
Glob `*/SKILL.md` in:
```
~/.config/opencode/skills/      # OpenCode (USAR)
~/.claude/skills/           # Claude Code
~/.gemini/skills/          # Gemini CLI
~/.cursor/skills/          # Cursor
{project}/.claude/skills/   # Project
```

Skip: `sdd-*`, `_shared`, `skill-registry`

### 2. Read SKILL.md
- name (frontmatter)
- trigger (description)
- compact rules (Critical Patterns / Rules)

### 3. Build Table
| Trigger | Skill | Path |
|---------|-------|------|
| "go test" | go-testing | ~/.config/opencode/skills/go-testing/SKILL.md |
| ... | ... | ... |

### 4. Write `.atl/skill-registry.md`
Plus: mem_save si available

## Output Format
```markdown
# Skill Registry

| Trigger | Skill | Path |
|---------|-------|------|
| trigger | name | path |

## Compact Rules

### {skill}
- Rule 1
- Rule 2
```

* skill-registry v2.0 — Karpathy Optimized *