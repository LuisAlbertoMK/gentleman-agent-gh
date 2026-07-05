# OpenCode Error Analysis — 2026-07-04

## Image 1: YAML Parsing Error
- **Tool**: OpenCode (terminal)
- **Error Type**: YAMLException
- **Issue**: Incomplete explicit mapping pair — key node missing
- **Location**: Line 3, Column 87
- **Context**: Processing codebase with "codebase-memory" MCP
- **Status**: Build Pickle OpenCode Zen active; TODO comment detected

---

## Image 2: SQLite Column Error
- **Tool**: OpenCode (terminal tab)
- **Error Type**: SQLiteError
- **Message**: `no such column: replacement_seq`
- **Root Cause**: Schema mismatch or migration not applied
- **Impact**: Session/DB operation blocked
- **Note**: Suggests `git pull --rebase` + force push if history is corrupted
- **Stack Trace**: Full Node.js chain captured (SessionPrompt → createUserMessage → prepare)

---

## Image 3: PowerShell Session
- **Tool**: OpenCode with PowerShell
- **Status**: Startup in progress ("Finishing startup...")
- **Error**: Same YAMLException (incomplete mapping) repeating
- **MCP Status**: codebase-memory active, 2 MCP /status checks
- **System**: vMK-dev environment, 26% CPU usage

---

## Summary
| Error | Severity | Category |
|-------|----------|----------|
| YAML parsing | Medium | Config/syntax |
| SQLite column | High | DB schema |
| Recurring YAML | Medium | Persistent config issue |

**Next Steps**: Validate schema migration, check YAML syntax in config files, ensure git history clean.
