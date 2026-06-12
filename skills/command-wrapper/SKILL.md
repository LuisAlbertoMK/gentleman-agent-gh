---
name: command-wrapper
description: >
  command-wrapper skill
triggers: "Command wrapper, error handling, output parsing"
  Trigger: Running bash commands, detecting errors, command output parsing.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## COMMAND CONTRACT
Every bash command MUST include:
1. **Description**: 5-10 words of what it does
2. **Error handling**: check exit code, parse stderr for known patterns
3. **Output validation**: does output match expected format?

## ERROR HANDLING PATTERNS

| Error pattern | Action |
|---------------|--------|
| `command not found` | Install dependency or report missing tool |
| `permission denied` | Check file permissions, suggest fix |
| `exit code 1` (git) | Check git status, resolve merge conflicts |
| `exit code 1` (build) | Parse compiler errors, fix file:line |
| Timeout (>30s) | Kill process, retry with simpler command |
| Network error | Retry once, if persists → report connectivity issue |
| Empty output (expected non-empty) | Check if source exists, validate path |

## OUTPUT PARSING RULES
- Always trim whitespace from output
- Parse structured output (JSON, table) with explicit format expectations
- If output has warnings + results → extract BOTH, don't skip warnings
- If output exceeds context limits → save to file, read relevant portions

## SAFETY WRAPPERS
```bash
# Before destructive commands:
# Show what will happen, ask user confirmation
# "git push --force" → BLOCK (ask required)
# "rm -rf" → BLOCK (ask required)
# "git commit" → quality gate first
```

## LOGGING (post-command)
After critical commands, log outcome to Engram:
```
title: "Command: {command-summary}"
type: discovery  (if gotcha) or config (if setup)
content: **What**: command | **Exit code**: N | **Output**: summary | **Learned**: gotchas
```

