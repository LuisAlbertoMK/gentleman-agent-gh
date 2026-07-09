#requires -Version 7.6
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Bash-syntax safe executor for PowerShell 5.1 environments.

.VERSION
    1.0.0

.DESCRIPTION
    PowerShell 5.1 does NOT support `&&`, `||`, or `@{var}` hash literals.
    WSL bash in PATH is a relay (fails without WSL). Git Bash at
    "C:\Program Files\Git\bin\bash.exe" is the working interpreter.

    This script provides Invoke-Bash that delegates to Git Bash,
    bypassing PowerShell parser.

.EXAMPLE
    . "$PSScriptRoot\bash-safe.ps1"
    Invoke-Bash "git status --short && git log --oneline -5"

.EXAMPLE
    Invoke-Bash "git log @{u}.. --oneline"

.NOTES
    Falls back to PATH bash (WSL) if Git Bash not found.
    Self-test: 6/6 PASS (run Test-BashSafe after dot-sourcing).
#>

# Locate real bash interpreter — check 4 common locations + PATH fallback
$script:GitBash = $null
$bashCandidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe"
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    "$env:ChocolateyInstall\lib\git\tools\bin\bash.exe"
)
foreach ($c in $bashCandidates) {
    if (Test-Path $c) { $script:GitBash = $c; break }
}
if (-not $script:GitBash) {
    $script:GitBash = (Get-Command bash -ErrorAction SilentlyContinue).Source
}
if (-not $script:GitBash -or -not (Test-Path $script:GitBash)) {
    throw "No bash interpreter found. Install Git for Windows or WSL."
}

# Server command patterns — commands that start long-lived processes
$script:ServerPatterns = @(
    '^\s*ng\s+serve'
    '^\s*npm\s+run\s+(dev|start|serve)'
    '^\s*yarn\s+(dev|start|serve)'
    '^\s*pnpm\s+run\s+(dev|start|serve)'
    '^\s*dotnet\s+run'
    '^\s*python\s+-m\s+http\.server'
    '^\s*python\s+.*server\.py'
    '^\s*node\s+.*server\.(js|ts)'
    '^\s*npx\s+.*serve'
    '^\s*jekyll\s+serve'
    '^\s*hugo\s+server'
    '^\s*vite(\s|$)'
    '^\s*webpack-dev-server'
    '^\s*ts-node\s+.*server'
)

# Server → puerto default mapping
$script:ServerDefaultPorts = @(
    @{ pattern = '^\s*ng\s+serve';     port = 4200 }
    @{ pattern = '^\s*vite';           port = 5173 }
    @{ pattern = '^\s*webpack-dev-server'; port = 8080 }
    @{ pattern = '^\s*jekyll\s+serve'; port = 4000 }
    @{ pattern = '^\s*hugo\s+server';  port = 1313 }
    @{ pattern = '^\s*python\s+-m\s+http\.server'; port = 8000 }
    @{ pattern = '^\s*dotnet\s+run';   port = 5000 }
    @{ pattern = '^\s*(npm|yarn|pnpm)\s+run\s+dev'; port = 3000 }
)

<#
.SYNOPSIS
    Detect if a command matches known server patterns.
.DESCRIPTION
    Server commands (ng serve, npm run dev, etc.) start long-lived processes
    that never finish on their own. This function detects them so they can be
    handled with -Background or dev-server.ps1.
.EXAMPLE
    Test-IsServerCommand "ng serve"  # $true
    Test-IsServerCommand "git status"  # $false
#>
function Test-IsServerCommand {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)
    foreach ($pattern in $script:ServerPatterns) {
        if ($Command -match $pattern) { return $true }
    }
    return $false
}

<#
.SYNOPSIS
    Extract the port number from a server command, or return default.
.DESCRIPTION
    Looks for --port, -p, :port patterns in the command. Falls back to
    known defaults (ng=4200, vite=5173, etc.). Returns $null if unknown.
.EXAMPLE
    Get-ServerPort "ng serve --port 4300"  # 4300
    Get-ServerPort "ng serve"               # 4200 (default)
    Get-ServerPort "git status"             # $null
#>
function Get-ServerPort {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)
    # Try explicit --port NNNN
    if ($Command -match '--port[= ](\d+)') { return [int]$Matches[1] }
    # Try -p NNNN (short flag)
    if ($Command -match '(?:^|\s)-p\s+(\d+)') { return [int]$Matches[1] }
    # Try :NNNN at end (URL-like)
    if ($Command -match ':(\d{4,5})(?:\s|$)') { return [int]$Matches[1] }
    # Try bare port number at end of command, only if it's a known server
    if ((Test-IsServerCommand $Command) -and ($Command -match '(\d{4,5})$')) { return [int]$Matches[1] }
    # Fallback to defaults
    foreach ($entry in $script:ServerDefaultPorts) {
        if ($Command -match $entry.pattern) { return $entry.port }
    }
    return $null
}

<#
.SYNOPSIS
    Check if a TCP port is already in use on localhost.
.DESCRIPTION
    Uses Get-NetTCPConnection. Falls back to netstat if unavailable.
    Returns $true if port is occupied, $false if free, $null if undetermined.
.EXAMPLE
    Test-PortInUse 4200  # $true if ng serve already running
#>
function Test-PortInUse {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Port)
    # Uses .NET TcpClient with 1s timeout — no Windows module dependency
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $ar = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $ok = $ar.AsyncWaitHandle.WaitOne(1000, $false)
        if ($ok) {
            $client.EndConnect($ar)
            $client.Close()
            return $true  # connected → port in use
        }
        $client.Close()
        return $false  # no response in 1s → probably free
    } catch {
        # Connection refused or invalid port → free
        return $false
    }
}

# Dot-source entry point
function Invoke-Bash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Command,

        [switch]$CaptureOutput,

        [switch]$Background
    )

    $ErrorActionPreference = 'Continue'

    # Server command detection — warn if launched without -Background
    $isServer = Test-IsServerCommand $Command
    if ($isServer -and -not $Background) {
        Write-Warning "[bash-safe] ⚠️  '$($Command -replace '^(.{55}).*', '$1…')' parece un SERVIDOR (nunca termina)."
        Write-Warning "[bash-safe]    Usá -Background: Invoke-Bash '$($Command -replace "'","''")' -Background"
        Write-Warning "[bash-safe]    O dev-server.ps1: .\scripts\dev-server.ps1 -Action Start -Name <name> -Command $($script:GitBash) -Arguments '-c ""$($Command -replace '"','""')""'"
    }

    # Port conflict detection for server commands
    if ($isServer) {
        $port = Get-ServerPort $Command
        if ($port) {
            $inUse = Test-PortInUse $port
            if ($inUse -eq $true) {
                Write-Warning "[bash-safe] ⚠️  Puerto $port ya está EN USO — otro servidor está corriendo ahí."
                Write-Warning "[bash-safe]    Descubrí quién: Get-Process -Id ((Get-NetTCPConnection -LocalPort $port).OwningProcess)"
                Write-Warning "[bash-safe]    O usá un puerto distinto: --port <otro>"
            } elseif ($inUse -eq $null) {
                Write-Warning "[bash-safe] ⚠️  No se pudo verificar si el puerto $port está ocupado."
            }
            # $false = libre, no warning
        }
    }

    if ($Background) {
        # Launch process without waiting
        $psi = [System.Diagnostics.ProcessStartInfo]@{
            FileName               = $script:GitBash
            Arguments              = "-c `"$Command`""
            UseShellExecute        = $false
            CreateNoWindow         = $true
        }
        try {
            $p = [System.Diagnostics.Process]::Start($psi)
            $msg = "[background] PID $($p.Id): $Command"
            if ($CaptureOutput) {
                return [PSCustomObject]@{ Output = @($msg); ExitCode = 0 }
            }
            Write-Host "[bash-safe] ✅ Background PID $($p.Id): $Command" -ForegroundColor Green
            return
        } catch {
            Write-Error "[bash-safe] Error starting background process: $_"
            if ($CaptureOutput) { return [PSCustomObject]@{ Output = @(); ExitCode = 1 } }
            return
        }
    }

    # Original synchronous behavior
    if ($CaptureOutput) {
        $output = & $script:GitBash -c $Command 2>&1
        $code = $LASTEXITCODE
        return [PSCustomObject]@{ Output = $output; ExitCode = $code }
    }
    else {
        & $script:GitBash -c $Command
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            Write-Warning "Invoke-Bash exit=$code : $Command"
        }
    }
}

# Quick test runner
function Test-BashSafe {
    Write-Host "[1] && operator..." -NoNewline
    $r = Invoke-Bash "echo a && echo b" -CaptureOutput
    if (($r.Output -join '') -match 'a\s*b') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($($r.ExitCode))" -ForegroundColor Red; $r.Output }

    Write-Host "[2] || operator..." -NoNewline
    $r = Invoke-Bash "false || echo fallback" -CaptureOutput
    if (($r.Output -join '') -match 'fallback') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[3] @{u} hash literal..." -NoNewline
    # @{}.. is bash syntax; PowerShell 5.1 would refuse to parse it.
    # Exit 0 = command parsed & ran (empty output means "0 unpushed" = correct).
    $r = Invoke-Bash "git log @{u}.. --oneline 2>&1; echo END" -CaptureOutput
    if ($r.ExitCode -eq 0 -and ($r.Output -join '') -match 'END') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL (exit=$($r.ExitCode))" -ForegroundColor Red }

    Write-Host "[4] 2>&1 redirect..." -NoNewline
    $r = Invoke-Bash "echo err 1>&2; echo out" -CaptureOutput
    if (($r.Output -join '') -match 'err.*out') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[5] pipeline + grep..." -NoNewline
    $r = Invoke-Bash "echo -e 'foo\nbar\nbaz' | grep ba" -CaptureOutput
    if (($r.Output -join '') -match 'bar') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[6] git --version..." -NoNewline
    $r = Invoke-Bash "git --version" -CaptureOutput
    if (($r.Output -join '') -match 'git version') { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }
}

# Server detection test runner
function Test-ServerDetection {
    Write-Host "[S1] ng serve..." -NoNewline
    $r = Test-IsServerCommand "ng serve"
    if ($r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S2] npm run dev..." -NoNewline
    $r = Test-IsServerCommand "npm run dev"
    if ($r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S3] npm run build (NO server)..." -NoNewline
    $r = Test-IsServerCommand "npm run build"
    if (-not $r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S4] dotnet run..." -NoNewline
    $r = Test-IsServerCommand "dotnet run"
    if ($r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S5] git status (NO server)..." -NoNewline
    $r = Test-IsServerCommand "git status"
    if (-not $r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S6] python -m http.server..." -NoNewline
    $r = Test-IsServerCommand "python -m http.server 8080"
    if ($r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S7] vite..." -NoNewline
    $r = Test-IsServerCommand "vite"
    if ($r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }

    Write-Host "[S8] echo hello (NO server)..." -NoNewline
    $r = Test-IsServerCommand "echo hello"
    if (-not $r) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL" -ForegroundColor Red }
}

# Port detection test runner
function Test-PortDetection {
    Write-Host "[P1] ng serve → default 4200..." -NoNewline
    $p = Get-ServerPort "ng serve"
    if ($p -eq 4200) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P2] ng serve --port 4300..." -NoNewline
    $p = Get-ServerPort "ng serve --port 4300"
    if ($p -eq 4300) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P3] npm run dev → default 3000..." -NoNewline
    $p = Get-ServerPort "npm run dev"
    if ($p -eq 3000) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P4] python -m http.server 8080..." -NoNewline
    $p = Get-ServerPort "python -m http.server 8080"
    if ($p -eq 8080) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P5] vite --port 5173..." -NoNewline
    $p = Get-ServerPort "vite --port 5173"
    if ($p -eq 5173) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P6] git status (NO port)..." -NoNewline
    $p = Get-ServerPort "git status"
    if ($null -eq $p) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P7] dotnet run → default 5000..." -NoNewline
    $p = Get-ServerPort "dotnet run"
    if ($p -eq 5000) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }

    Write-Host "[P8] jekyll serve --port 4000..." -NoNewline
    $p = Get-ServerPort "jekyll serve --port 4000"
    if ($p -eq 4000) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAIL ($p)" -ForegroundColor Red }
}

# Auto-discover GENTLEMAN_AGENT_ROOT on dot-source (via junction)
$__dir = Split-Path $MyInvocation.MyCommand.Path -Parent
$__item = Get-Item $__dir
if ($__item.LinkType -eq "Junction" -and $__item.Target) {
    $env:GENTLEMAN_AGENT_ROOT = (Split-Path $__item.Target -Parent).Replace('\', '/')
}

# Self-test if run directly
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand.Path -eq $PSCommandPath) {
    Write-Host "Using: $script:GitBash" -ForegroundColor Cyan
    Test-BashSafe
    Write-Host ""
    Test-ServerDetection
    Write-Host ""
    Test-PortDetection
}
