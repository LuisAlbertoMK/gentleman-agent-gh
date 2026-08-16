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

## More Examples

**Example 1: React + Vite with custom port and logging**
```powershell
# Start Vite dev server on port 3000
.\scripts\dev-server.ps1 -Action Start -Name "vite-app" -Command "npm" -Arguments "run dev -- --port 3000 --host"

# Follow logs in real-time (like tail -f)
.\scripts\dev-server.ps1 -Action Logs -Name "vite-app" -Tail 0 -Follow
```

**Example 2: .NET Core Web API with environment**
```powershell
# Start ASP.NET Core with Development environment
.\scripts\dev-server.ps1 -Action Start -Name "api" -Command "dotnet" -Arguments "run --project src/Api --environment Development --urls http://localhost:5000"

# Check health endpoint once server reports ready
.\scripts\dev-server.ps1 -Action Status -Name "api"
```

**Example 3: Python HTTP server for static files**
```powershell
# Serve a build output folder on port 8080
.\scripts\dev-server.ps1 -Action Start -Name "static" -Command "python" -Arguments "-m http.server 8080 --directory dist"

# Verify serving works
.\scripts\dev-server.ps1 -Action Logs -Name "static" -Tail 5
```

**Example 4: Concurrent frontend + backend + proxy**
```powershell
# Terminal 1: Vite frontend
.\scripts\dev-server.ps1 -Action Start -Name "web" -Command "npm" -Arguments "run dev -- --port 5173"

# Terminal 2: Express backend
.\scripts\dev-server.ps1 -Action Start -Name "api" -Command "node" -Arguments "server.js"

# Terminal 3: Vite proxy (configured in vite.config.ts to proxy /api to :3000)
# Verify both running
.\scripts\dev-server.ps1 -Action Status -Name "web","api"
```

**Example 5: Restart with config change (hot reload pattern)**
```powershell
# Kill, update config, restart
.\scripts\dev-server.ps1 -Action Kill -Name "myapp"
# ... edit config file ...
.\scripts\dev-server.ps1 -Action Start -Name "myapp" -Command "npm" -Arguments "run dev"
```

## Testing Patterns

**Pattern 1: Smoke test — server responds to HTTP**
```powershell
function Test-ServerReady($name, $url, $timeoutSec = 30) {
    $start = [DateTime]::Now
    while (([DateTime]::Now - $start).TotalSeconds -lt $timeoutSec) {
        try {
            $resp = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec 2 -ErrorAction Stop
            if ($resp.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Seconds 1
    }
    return $false
}

# Usage
.\scripts\dev-server.ps1 -Action Start -Name "test" -Command "npm run dev"
if (Test-ServerReady "test" "http://localhost:5173") { Write-Host "✅ Ready" }
```

**Pattern 2: Log-based readiness detection**
```powershell
function Wait-ForLogPattern($name, $pattern, $timeoutSec = 60) {
    $start = [DateTime]::Now
    while (([DateTime]::Now - $start).TotalSeconds -lt $timeoutSec) {
        $logs = .\scripts\dev-server.ps1 -Action Logs -Name $name -Tail 50
        if ($logs -match $pattern) { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

# Wait for Vite "ready" message
Wait-ForLogPattern "web" "ready in|Local:" 45
```

**Pattern 3: Port availability + process health check**
```powershell
function Assert-ServerHealthy($name, $port) {
    $status = .\scripts\dev-server.ps1 -Action Status -Name $name
    $portOpen = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" # placeholder
    $processAlive = $status -match "Running"
    if (-not $processAlive) { throw "Server $name not running" }
    # Additional: verify port is listening
    $listening = (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
    if (-not $listening) { throw "Port $port not listening for $name" }
    return $true
}
```

## Edge Cases

**Edge 1: Port already in use by stale process**
```powershell
# Detect and clear orphaned server on same port
$existing = Get-NetTCPConnection -LocalPort 4200 -ErrorAction SilentlyContinue
if ($existing) {
    $pid = $existing.OwningProcess
    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
    if ($proc -and $proc.ProcessName -like "*node*" -or $proc.ProcessName -like "*dotnet*") {
        Write-Warning "Killing stale $($proc.ProcessName) PID $pid on port 4200"
        Stop-Process -Id $pid -Force
        Start-Sleep -Seconds 1
    }
}
```

**Edge 2: Server crashes immediately (config error, missing deps)**
```powershell
# Start then immediately check status — catches fast-fail
.\scripts\dev-server.ps1 -Action Start -Name "flaky" -Command "npm run dev"
Start-Sleep -Seconds 3
$status = .\scripts\dev-server.ps1 -Action Status -Name "flaky"
if ($status -notmatch "Running") {
    $logs = .\scripts\dev-server.ps1 -Action Logs -Name "flaky" -Tail 30
    throw "Server failed to start: $logs"
}
```

**Edge 3: Long startup time (webpack build, .NET restore)**
```powershell
# Use extended timeout + polling for slow starters
.\scripts\dev-server.ps1 -Action Start -Name "slow" -Command "dotnet run"
$ready = $false
for ($i = 0; $i -lt 120; $i++) {  # 2 min max
    $logs = .\scripts\dev-server.ps1 -Action Logs -Name "slow" -Tail 20
    if ($logs -match "Now listening on|Application started") { $ready = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $ready) { throw "Timeout waiting for server ready" }
```

**Edge 4: Multiple instances of same server name (race condition)**
```powershell
# Ensure unique names; dev-server.ps1 rejects duplicates
.\scripts\dev-server.ps1 -Action Start -Name "app-instance-1" -Command "npm run dev -- --port 3000"
.\scripts\dev-server.ps1 -Action Start -Name "app-instance-2" -Command "npm run dev -- --port 3001"
# Kill by pattern not supported — use explicit names
.\scripts\dev-server.ps1 -Action Kill -Name "app-instance-1","app-instance-2"
```

## Anti-Patterns

**Anti-Pattern 1: Backgrounding with `&` or `Start-Process -NoNewWindow`**
```powershell
# ❌ WRONG — loses control, no logs, no cleanup, port leaks
npm run dev &
Start-Process "dotnet" "run" -NoNewWindow

# ✅ CORRECT — managed lifecycle, logs captured, clean kill
.\scripts\dev-server.ps1 -Action Start -Name "app" -Command "npm run dev"
```

**Anti-Pattern 2: Assuming server is ready immediately after Start**
```powershell
# ❌ WRONG — race condition, tests hit 404/connection refused
.\scripts\dev-server.ps1 -Action Start -Name "api" -Command "dotnet run"
Invoke-WebRequest "http://localhost:5000/health"  # fails!

# ✅ CORRECT — wait for readiness signal (log pattern or HTTP)
.\scripts\dev-server.ps1 -Action Start -Name "api" -Command "dotnet run"
Wait-ForLogPattern "api" "Now listening on" 30
# or: Test-ServerReady "api" "http://localhost:5000/health"
```
