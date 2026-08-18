---
name: customize-opencode
description: "Use ONLY when the user is editing or creating opencode's own configuration: opencode.json, opencode.jsonc, files under .opencode/, or files under ~/.config/opencode/. Also use when creating or fixing opencode agents, subagents, skills, plugins, MCP servers, or permission rules. Do not use for the user's own application code, or for any project that is not configuring opencode itself."
triggers: "opencode.json, opencode.jsonc, .opencode/, ~/.config/opencode/, opencode agent, opencode subagent, opencode skill, opencode plugin, opencode MCP, opencode permission, opencode config"
changelog: docs/ciclos/cycle28-20260816.md
---
## When to Use

Configuring **opencode itself** — not user application code. Scope includes:
- `opencode.json` / `opencode.jsonc` (project or global)
- `.opencode/` directory (project-local config)
- `~/.config/opencode/` (global user config)
- Agents, subagents, skills, plugins, MCP servers, permission rules
- Theme, keybindings, model routing, tool permissions

**SCOPE GUARD**: If the task is about user's application code (React, Python, Go, etc.) → STOP. Wrong skill. Use code-generation, quick-executor, or appropriate domain skill.

## WORKFLOW

1. **DISCOVER**: Locate the config file(s). Priority: project `opencode.json` → `.opencode/` → global `~/.config/opencode/opencode.json`
2. **READ** target file. Validate JSON/JSONC syntax. Not exists → create from template.
3. **PLAN** minimal change. Risk check: modifying `permissions` or `modelRouter` → HIGH risk. Adding agent/skill → MEDIUM. Theme/keybindings → LOW.
4. **EDIT** in one atomic operation. Preserve comments in JSONC. Maintain alphabetical ordering where applicable.
5. **VERIFY**: 
   - Syntax: `node --check opencode.json` (JSON) or `npx jsonc-parser opencode.jsonc` (JSONC)
   - Schema: `opencode validate` (if available) or manual schema check
   - Runtime: `opencode doctor` to confirm config loads without errors
6. **REPORT**: One line summary with file, change type, risk level.

## FAILURE MODES

- JSON/JSONC parse error → `git checkout -- <file>`, report exact line/column
- `opencode doctor` fails → STOP, escalate with error output
- Schema validation fails → STOP, cite schema violation
- Unclear requirements → STOP, 1 clarifying question

## RISK HEURISTIC

| Change Type | Risk | Requires Review |
|-------------|------|-----------------|
| Theme, keybindings, UI prefs | LOW | No |
| Add/remove skill, agent, plugin | MEDIUM | Yes (test load) |
| Modify permissions, modelRouter | HIGH | Yes (dry-run + test) |
| MCP server config | HIGH | Yes (connection test) |
| Global `~/.config/opencode/` | HIGH | Yes (affects all projects) |

## STANDALONE MODE

If invoked directly (not via orchestrator): report issues as findings, do not escalate. Apply fixes if clear and verified.

## OUTPUT FORMAT

```
Changed [file] ([change-type]). Risk: [LOW|MEDIUM|HIGH]. Verified: [pass/fail].
```

## REFS

opencode-skill-creator · opencode-model-router · security-scanner (for permission rules) · command-wrapper (for MCP server commands)
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/customize-opencode/reference.md

---
