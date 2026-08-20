# customize-opencode — Reference Materials

> **Externalized from** .agents/skills/customize-opencode/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
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

## Externalized Sections (ADR-007 compression)
## FAILURE MODES
JSON/JSONC parse error → `git checkout -- <file>`, report line/column · `opencode doctor` fails → STOP, escalate · Schema violation → STOP, cite · Unclear → STOP, 1 question.


## STANDALONE MODE
Invoked directly: report findings, apply fixes if clear and verified.


## OUTPUT FORMAT
`Changed [file] ([change-type]). Risk: [LOW|MEDIUM|HIGH]. Verified: [pass/fail].`

## RISK HEURISTIC
| Change Type | Risk | Requires Review |
|---|---|---|
| Theme, keybindings, UI prefs | LOW | No |
| Add/remove skill, agent, plugin | MEDIUM | Yes (test load) |
| permissions, modelRouter | HIGH | Yes (dry-run + test) |
| MCP server config | HIGH | Yes (connection test) |
| Global `~/.config/opencode/` | HIGH | Yes (all projects) |


