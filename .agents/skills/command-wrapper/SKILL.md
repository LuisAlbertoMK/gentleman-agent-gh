---
name: command-wrapper
description: "Run commands safely — description, error handling, output parsing, and safety wrappers for destructive operations"
triggers: "Command wrapper, error handling, output parsing"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 3000
---

## When to Use
Running bash commands, detecting errors, parsing output.

## COMMAND CONTRACT
Every bash command MUST include: 1. **Description**: 5-10 words. 2. **Error handling**: check exit code, parse stderr for known patterns. 3. **Output validation**: does output match expected format?

## ERROR HANDLING PATTERNS
| Error pattern | Action |
|---|---|
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
Destructive commands → BLOCK (ask required): `git push --force`, `rm -rf`. `git commit` → quality gate first.

## LOGGING (post-command)
After critical commands, log to Engram: `title:"Command: {summary}" type:discovery|config content:"**What**: command | **Exit code**: N | **Output**: summary | **Learned**: gotchas"`

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "destructivo sin -WhatIf" | rm -rf / git push --force sin safety wrapper | bloquear destructivo o usar -WhatIf + quality gate file:line |
| "output sin parsear se pierde" | output con warnings+results sin parsear | trim + parse JSON/table + extraer warnings y results file:line |
| "ignorar exit code" | exit code ≠0 sin diagnosticar stderr | check exit code + parse stderr patterns file:line |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
security-scanner · delivery-harness · subagent-isolation · recovery-protocol · context-watchdog · quick-executor · server-commands

## Anti-Patterns
Skip description · Ignore stderr · Parse output by eye · Raw bash for destructive ops · No timeout

## Reference
> docs/skills/command-wrapper/reference.md

