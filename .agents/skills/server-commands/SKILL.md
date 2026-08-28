---
name: server-commands
description: "Run long-lived server processes safely — dev-server.ps1, port detection, background management"
triggers: "server, ng serve, npm run dev, dotnet run, python -m http.server, dev server, background process, long-lived, !dev"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1693
---

## When to Use
Run long-lived server processes safely — dev-server.ps1, port detection, background management


Commands like `ng serve`, `npm run dev`, `dotnet run`, `python -m http.server`
start SERVERS that **never finish**. DO NOT run them via the bash tool directly.

**Correct flow**:
1. Start: `scripts/dev-server.ps1 -Action Start -Name <name> -Command <cmd> -Arguments <args>`
2. Check:  `scripts/dev-server.ps1 -Action Status -Name <name>`
3. Logs:   `scripts/dev-server.ps1 -Action Logs -Name <name> -Tail 10`
4. Kill:   `scripts/dev-server.ps1 -Action Kill -Name <name>`

**Detection**: If the bash tool would run a server command, use dev-server.ps1 instead.
If `Invoke-Bash` warns that a command is a server, re-run with `-Background` or
use `dev-server.ps1`. If unsure, check `Test-IsServerCommand "$cmd"` first.

**Port conflict**: Before starting, check if the port is already in use. The system
auto-detects common ports (ng=4200, vite=5173, dotnet=5000, etc.) and warns you.
Manual check: `Get-NetTCPConnection -LocalPort <port>` or `Test-PortInUse 4200`
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/server-commands/reference.md

---
## Refs
Cross-Refs: infra-audit | performance
