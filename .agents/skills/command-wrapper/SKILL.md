---
name: command-wrapper
description: "Run commands safely — description, error handling, output parsing, and safety wrappers for destructive operations"
triggers: "Command wrapper, error handling, output parsing"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Run commands safely — description, error handling, output pa


Trigger: Running bash commands, detecting errors, parsing output.

## COMMAND CONTRACT
Every bash command MUST include:
1. **Description**: 5-10 words
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
| Network error | Retry once → report connectivity issue |
| Empty output | Check if source exists, validate path |

## OUTPUT PARSING RULES
- Always trim whitespace from output
- Parse structured output (JSON, table) with explicit format expectations
- If output has warnings + results → extract BOTH, don't skip warnings
- If output exceeds context limits → save to file, read relevant portions

## SAFETY WRAPPERS
```bash
# Before destructive commands: show what will happen, ask confirmation
# "git push --force" → BLOCK (ask required)
# "rm -rf" → BLOCK (ask required)
# "git commit" → quality gate first
```

## LOGGING (post-command)
After critical commands, log outcome to Engram:
```yaml
title: "Command: {summary}"
type: discovery (if gotcha) or config (if setup)
content: "**What**: command | **Exit code**: N | **Output**: summary | **Learned**: gotchas"
```

## Refs
security-scanner · delivery-harness · subagent-isolation · recovery-protocol · context-watchdog

## Anti-Patterns
Skip description · Ignore stderr · Parse output by eye · Use raw bash for destructive ops · No timeout
