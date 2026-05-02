---
name: skill-registry
description: >
  Create/update skill registry. Scans skills + conventions, writes .atl/skill-registry.md, saves to engram.
  Trigger: "update skills", "skill registry", "actualizar skills", "update registry", after install/remove.
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Purpose
Generate registry with **compact rules** (5-15 line summaries) injected into sub-agent prompts. Sub-agents do NOT read SKILL.md files — they receive compact rules pre-resolved.

## When
After install/remove skills · New project setup · User asks · Part of `sdd-init`

## Steps

### 1: Scan User Skills
Glob `*/SKILL.md` across:
**User-level:** `~/.claude/skills/` · `~/.config/opencode/skills/` · `~/.gemini/skills/` · `~/.cursor/skills/` · `~/.copilot/skills/` · parent dir
**Project-level:** `{root}/.claude/skills/` · `{root}/.gemini/skills/` · `{root}/.agent/skills/` · `{root}/skills/`

**Skip:** `sdd-*`, `_shared`, `skill-registry`
**Deduplicate:** project-level wins. Read frontmatter + critical patterns (<200 lines: full file; >200: frontmatter + rules only).

### 1b: Generate Compact Rules
Per skill, 5-15 lines: actionable rules, key patterns, breaking changes/gotchas. NO purpose/motivation, full examples, install steps.

```markdown
### {skill-name}
- Rule 1
- Rule 2
```
Example:
```markdown
### react-19
- No useMemo/useCallback — React Compiler handles memoization
- use() hook for promises/context, replaces useEffect for data fetching
- Server Components default, 'use client' only for interactivity
- ref is regular prop — no forwardRef
```

### 2: Scan Project Conventions
Check: `agents.md`/`AGENTS.md` · `CLAUDE.md` · `.cursorrules` · `GEMINI.md` · `copilot-instructions.md`
Index files → READ + extract all referenced paths. Record index + references.

### 3: Write Registry
```markdown
# Skill Registry
**Delegator use only.** Sub-agents receive compact rules in launch prompt. See `_shared/skill-resolver.md`.

## User Skills
| Trigger | Skill | Path |
| {trigger} | {name} | {path} |

## Compact Rules
Pre-digested rules. Delegators inject as `## Project Standards (auto-resolved)`.

### {skill-1}
- Rule 1
- Rule 2

## Project Conventions
| File | Path | Notes |
| {index} | {path} | Index — references below |
| {ref} | {path} | Referenced by {index} |
```

### 4: Persist
**A. Always:** `.atl/skill-registry.md` (create `.atl/` if needed)
**B. If engram:** `mem_save(title: "skill-registry", topic_key: same, type: "config", project: "{project}")`

### 5: Return Summary
```
## Skill Registry Updated
**Project**: {name} | **Location**: .atl/skill-registry.md | **Engram**: {saved/not}

### Skills Found
| Skill | Trigger |
| {name} | {trigger} |

### Conventions Found
| File | Path |
```

## Rules
- ALWAYS write `.atl/skill-registry.md` regardless of mode
- ALWAYS save to engram if `mem_save` available
- SKIP `sdd-*`, `_shared`, `skill-registry`
- Compact rules: 5-15 lines per skill, concise + actionable
- Include ALL convention index files found
- No skills/conventions → write empty registry
- Add `.atl/` to `.gitignore` if not listed
