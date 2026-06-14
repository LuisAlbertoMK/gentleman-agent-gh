---
name: command-wrapper
description: >  command-wrapper skill
triggers: "Command wrapper, error handling, output parsing"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

Trigger: Running bash commands, detecting errors, command output parsing.
## COMMAND CONTRACTEvery bash command MUST include:1. **Description**: 5-10 words of what it does2. **Error handling**: check exit code, parse stderr for known patterns3. **Output validation**: does output match expected format?
## ERROR HANDLING PATTERNS| Error pattern | Action ||---------------|--------|| `command not found` | Install dependency or report missing tool || `permission denied` | Check file permissions, suggest fix || `exit code 1` (git) | Check git status, resolve merge conflicts || `exit code 1` (build) | Parse compiler errors, fix file:line || Timeout (>30s) | Kill process, retry with simpler command || Network error | Retry once, if persists â†’ report connectivity issue || Empty output (expected non-empty) | Check if source exists, validate path |
## OUTPUT PARSING RULES- Always trim whitespace from output- Parse structured output (JSON, table) with explicit format expectations- If output has warnings + results â†’ extract BOTH, don't skip warnings- If output exceeds context limits â†’ save to file, read relevant portions
## SAFETY WRAPPERS
```bash# Before destructive commands:# Show what will happen, ask user confirmation# "git push --force" â†’ BLOCK (ask required)# "rm -rf" â†’ BLOCK (ask required)# "git commit" â†’ quality gate first```
## LOGGING (post-command)After critical commands, log outcome to Engram:
```title: "Command: {command-summary}"type: discovery  (if gotcha) or config (if setup)content: **What**: command | **Exit code**: N | **Output**: summary | **Learned**: gotchas```
