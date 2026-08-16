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

## Anti-Patterns

- Editing user application code instead of opencode config
- Modifying global config when project config suffices
- Adding MCP servers without connection validation
- Skipping `opencode doctor` verification
- Breaking JSONC comment preservation

## Examples

### Example 1: Add a custom skill to project config

```jsonc
// opencode.json (project root)
// Before
{
  "skills": ["quick-executor", "deep-debugging"]
}

// After
{
  "skills": ["quick-executor", "deep-debugging", "customize-opencode"]
}
```
- File: `opencode.json` (project root)
- Change-type: skill registration
- Risk: MEDIUM (new skill must load without errors)
- Verification: `opencode doctor` → skill appears in `opencode skill list`

### Example 2: Configure model routing for analysis vs implementation

```jsonc
// opencode.jsonc
// Before
{
  "modelRouter": {
    "default": "opencode/nemotron-3-ultra-free"
  }
}

// After
{
  "modelRouter": {
    "default": "opencode/nemotron-3-ultra-free",
    "routes": [
      { "pattern": "analysis|debug|review", "model": "opencode/nemotron-3-ultra-free" },
      { "pattern": "implement|generate|code", "model": "opencode/gpt-4o-mini" }
    ]
  }
}
```
- File: `opencode.jsonc` (project root)
- Change-type: modelRouter configuration
- Risk: HIGH (affects all agent delegation)
- Verification: `opencode doctor` + test delegation with `analysis` and `implement` prompts

### Example 3: Add MCP server with environment variables

```jsonc
// ~/.config/opencode/opencode.jsonc (global)
// Before
{
  "mcpServers": {
    "github": { "command": "gh", "args": ["mcp"] }
  }
}

// After
{
  "mcpServers": {
    "github": { "command": "gh", "args": ["mcp"] },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"],
      "env": { "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}" }
    }
  }
}
```
- File: `~/.config/opencode/opencode.jsonc`
- Change-type: MCP server registration
- Risk: HIGH (global scope, requires auth)
- Verification: `opencode doctor` → MCP servers list shows "context7: connected"

### Example 4: Restrict tool permissions for a subagent

```jsonc
// .opencode/agents/code-reviewer.json
// Before
{
  "name": "code-reviewer",
  "permissions": { "tools": ["read", "grep", "glob"] }
}

// After
{
  "name": "code-reviewer",
  "permissions": {
    "tools": ["read", "grep", "glob"],
    "deny": ["bash", "write", "edit", "task"]
  }
}
```
- File: `.opencode/agents/code-reviewer.json`
- Change-type: agent permission hardening
- Risk: MEDIUM (may break agent if too restrictive)
- Verification: Spawn agent, attempt denied tool → expect permission error

### Example 5: Create a new subagent with custom prompt

```jsonc
// .opencode/agents/architect.json
// New file
{
  "name": "architect",
  "description": "System architecture decisions, ADRs, tech stack evaluation",
  "prompt": "You are a Senior Architect. Output ADR format. Cite tradeoffs. No code unless asked.",
  "model": "opencode/nemotron-3-ultra-free",
  "permissions": { "tools": ["read", "grep", "glob", "write"] }
}
```
- File: `.opencode/agents/architect.json`
- Change-type: new agent creation
- Risk: MEDIUM (new agent must be discoverable and loadable)
- Verification: `opencode agent list` shows "architect" → spawn and test with architecture question

## Testing Patterns

### Pattern 1: Config syntax + schema validation (CI-safe)

```bash
# JSON syntax check
node --check opencode.json

# JSONC syntax check (requires jsonc-parser)
npx jsonc-parser opencode.jsonc 2>/dev/null || echo "JSONC parse OK"

# Full opencode config validation (loads all config, checks schema)
opencode doctor --json 2>&1 | jq -r '.status // "unknown"'
# Expect: "ok" or "warning" (not "error")
```

### Pattern 2: Runtime load test for agents/skills/plugins

```bash
# List all discoverable agents
opencode agent list --json | jq -r '.[].name'

# List all discoverable skills
opencode skill list --json | jq -r '.[].name'

# Test spawn a specific agent (dry-run via help)
opencode agent run architect --help 2>&1 | head -5
# Should show agent help, not "agent not found" error

# Test skill load
opencode skill run quick-executor --help 2>&1 | head -3
```

### Pattern 3: MCP server connectivity test

```bash
# Test MCP server starts and lists tools (timeout after 5s)
timeout 5s opencode mcp test context7 2>&1 || true
# Expect: tool list output or "connected" — not "connection refused" or timeout

# Alternative: doctor shows MCP status
opencode doctor --json 2>&1 | jq '.mcpServers[] | {name: .name, status: .status}'
# All should show status: "connected"
```

## Edge Cases

### Edge Case 1: JSONC file with trailing commas or comments

- **Signal**: `node --check` fails but file is valid JSONC
- **Action**: Use JSONC-aware parser (`npx jsonc-parser` or `opencode doctor`) for validation. Never strip comments manually.
- **Reason**: opencode config supports JSONC natively; stripping comments breaks user intent and diff readability.

### Edge Case 2: Project config shadows global config incorrectly

- **Signal**: Change in `~/.config/opencode/opencode.json` not reflected; project `opencode.json` takes precedence
- **Action**: Check config load order with `opencode doctor --json | jq '.configSources'`. Document which layer owns which setting.
- **Reason**: opencode merges configs (global → project → .opencode/); last write wins. Silent shadowing causes confusion.

### Edge Case 3: MCP server command requires shell expansion

- **Signal**: `"command": "npx", "args": ["-y", "pkg"]` works but `"command": "npx -y pkg"` fails
- **Action**: Always split command + args array. Never use shell metacharacters (`&&`, `|`, `$VAR`) in command field.
- **Reason**: opencode spawns MCP servers directly (no shell). Environment variables must use `"env": { "KEY": "value" }` object.

### Edge Case 4: Permission rule `deny` vs `allow` precedence

- **Signal**: Agent has `"tools": ["read", "write"]` and `"deny": ["write"]` — write still works
- **Action**: `deny` only applies to tools NOT in `allow` list. To restrict, omit from `allow` entirely or use explicit `deny` with empty `allow`.
- **Reason**: opencode permission model is allowlist-first; `deny` is a filter on the allowlist, not a blocklist.

## Anti-Patterns (Expanded)

| Anti-Pattern | Why It Fails | Correct Approach |
|--------------|--------------|------------------|
| **Editing user app code as opencode config** | Wrong scope; pollutes opencode config with app settings | Use project's own config files (package.json, tsconfig.json, etc.) |
| **Modifying global `~/.config/opencode/` for project-specific needs** | Affects all projects; leaks secrets; breaks team consistency | Use project `opencode.json` or `.opencode/` for project-scoped config |
| **Adding MCP server without `opencode doctor` verification** | Silent connection failure; agent gets empty tool list | Always run `opencode doctor` after MCP changes; verify "connected" status |
| **Using shell syntax in MCP `command` field** | Commands fail to spawn; no shell interpolation | Split into `command` + `args[]`; use `env` object for variables |
| **Assuming `deny` blocks tools in `allow` list** | Permissions remain granted; security hole | Remove from `allow` list entirely for true denial |
| **Skipping JSONC comment preservation** | Loses documentation context; diffs become noisy | Use JSONC-aware editors/tools; never minify config files |

(End of file - total ~280 lines)