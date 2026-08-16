---
name: server-commands
description: "Run long-lived server processes safely — dev-server.ps1, port detection, background management"
triggers: "server, ng serve, npm run dev, dotnet run, python -m http.server, dev server, background process, long-lived, !dev"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Run long-lived server processes safely — dev-server.ps1, por


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

## Example

```powershell
# Start an Angular dev server
.\scripts\dev-server.ps1 -Action Start -Name "myapp" -Command "npx ng serve" -Arguments "--port 4200"

# Check status
.\scripts\dev-server.ps1 -Action Status -Name "myapp"

# View last 20 log lines
.\scripts\dev-server.ps1 -Action Logs -Name "myapp" -Tail 20

# Kill the server
.\scripts\dev-server.ps1 -Action Kill -Name "myapp"
```

## Port Conflict Resolution
```powershell
# Port 4200 in use? Find the owner
$processId = (Get-NetTCPConnection -LocalPort 4200 -ErrorAction SilentlyContinue).OwningProcess
if ($processId) {
  $process = Get-Process -Id $processId
  Write-Warning "Port 4200 in use by $($process.ProcessName) PID $processId"
  # Option A: kill the blocker
  # Stop-Process -Id $processId -Force
  # Option B: next available port
  # .\scripts\dev-server.ps1 -Action Start -Name "myapp" -Command "npx ng serve" -Arguments "--port 4201"
}
```

## Multiple Simultaneous Servers
```powershell
# Frontend + Backend side by side
.\scripts\dev-server.ps1 -Action Start -Name "frontend" -Command "npm run dev" -Arguments "--port 5173"
.\scripts\dev-server.ps1 -Action Start -Name "backend" -Command "dotnet run" -Arguments "--urls http://localhost:5000"

# Check both
.\scripts\dev-server.ps1 -Action Status -Name "frontend"
.\scripts\dev-server.ps1 -Action Status -Name "backend"

# Kill both
.\scripts\dev-server.ps1 -Action Kill -Name "frontend","backend"
```

**Wrong** (will hang the agent):
```powershell
npx ng serve  # ❌ Server never exits, blocks session
npm run dev   # ❌ Same problem
```
