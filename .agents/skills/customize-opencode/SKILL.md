---
name: customize-opencode
description: "Use ONLY when the user is editing or creating opencode's own configuration: opencode.json, opencode.jsonc, files under .opencode/, or files under ~/.config/opencode/. Also use when creating or fixing opencode agents, subagents, skills, plugins, MCP servers, or permission rules. Do not use for the user's own application code, or for any project that is not configuring opencode itself."
triggers: "opencode.json, opencode.jsonc, .opencode/, ~/.config/opencode/, opencode agent, opencode subagent, opencode skill, opencode plugin, opencode MCP, opencode permission, opencode config"
changelog: docs/ciclos/cycle28-20260816.md
token_budget: 2442
---
## When to Use
Configuring **opencode itself** — not user application code. Scope: `opencode.json`/`.jsonc` (project|global), `.opencode/`, `~/.config/opencode/`, agents/subagents/skills/plugins/MCP servers/permission rules, theme/keybindings/model routing/tool permissions.
**SCOPE GUARD**: User's application code (React, Python, Go…) → STOP. Use code-generation, quick-executor, or domain skill.
## WORKFLOW
1. **DISCOVER**: project `opencode.json` → `.opencode/` → global `~/.config/opencode/opencode.json`.
2. **READ** target file. Validate JSON/JSONC. Not exists → create from template.
3. **PLAN** minimal change. Risk: `permissions`/`modelRouter` → HIGH. Agent/skill → MEDIUM. Theme/keybindings → LOW.
4. **EDIT** one atomic op. Preserve JSONC comments. Alphabetical ordering where applicable.
5. **VERIFY**: `node --check` (JSON) / `npx jsonc-parser` (JSONC) / `opencode validate` / `opencode doctor`.
6. **REPORT**: one line: file, change type, risk level.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
opencode-skill-creator · opencode-model-router · security-scanner · command-wrapper
## Reference
RISK HEURISTIC table + examples → docs/skills/customize-opencode/reference.md

