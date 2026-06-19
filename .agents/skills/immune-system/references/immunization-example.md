# Immunization Example

## Real Case: Bash-Safe violation
```
Symptom: Used && in PowerShell command → PS5.1 parse error
Root cause: Not scanning command string before bash tool call
Fix: Added ampersand detection to pssa-gate.ps1 + AGENTS.md pre-flight rule
Prevention: "BEFORE every bash call, scan for && or ||"
Files: scripts/pssa-gate.ps1 (section 2b), AGENTS.md (pre-flight gate)
```

## Immunity Levels
| Level | Scope | Enforced |
|-------|-------|----------|
| Session | In-memory | Current session only |
| Skill | auto-metrics trigger | Next session |
| Catalog | ANTI-PATTERN-CATALOG.md | Every session start |
| AGENTS.md | Rules section | Always (hard-coded) |
