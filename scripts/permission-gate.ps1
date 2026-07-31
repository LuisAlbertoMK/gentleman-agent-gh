#requires -Version 5.1
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gentleman Agent — Runtime Permission Gate
.DESCRIPTION
    Classifies a command as allow/ask/deny based on current mode (.gentleman-mode).
    Works as a behavioral gate — the orchestrator calls this BEFORE running
    any command to check if it's permitted in the current mode.

    Modes:
      manual → Everything asks (except built-in denials: network, interpreters, destructive)
      semi   → Safe commands (read-only git, filesystem, search, test) auto-allow
      auto   → Everything auto-allows except push + destructive + network

.PARAMETER Command
    The full command string to check (e.g. "git push origin main")

.PARAMETER Mode
    Override mode (default: read from .gentleman-mode)

.PARAMETER ListModes
    Show mode summaries

.EXAMPLE
    .\scripts\permission-gate.ps1 -Command "git status"
    .\scripts\permission-gate.ps1 -Command "rm -rf node_modules"
    .\scripts\permission-gate.ps1 -Command "git push" -Mode auto
#>

param(
    [string]$Command = "",
    [ValidateSet('manual','semi','auto')][string]$Mode = "",
    [switch]$ListModes,
    [switch]$Json,
    [switch]$Force,
    [switch]$DryRun
)
Set-StrictMode -Version Latest

# --- Resolve paths ---
$repoRoot   = Split-Path -Path $PSScriptRoot -Parent
$modeFile   = Join-Path -Path $repoRoot '.gentleman-mode'

# --- Read current mode ---
if (-not $Mode) {
    $Mode = if (Test-Path -LiteralPath $modeFile) {
        (Get-Content -LiteralPath $modeFile -Raw).Trim()
    } else { 'manual' }
}

# ===== COMMAND CLASSIFICATION RULES =====

# These patterns are checked in order: deny → allow → ask (default)

$denyPatterns = @(
    # Network — always blocked
    '^curl\s', '^wget\s', '^Invoke-WebRequest', '^Invoke-RestMethod',
    '^irm\s', '^iwr\s', '^iex\s', '^Start-BitsTransfer',
    '^ssh\s', '^docker\s', '^docker-compose\s', '^docker compose',
    '^telnet\s', '^ncat\s', '^nc\s', '^Test-NetConnection',
    # Destructive filesystem
    '^rm\s', '^rm -rf', '^Remove-Item',
    # Interpreters
    '^python\s', '^python3\s', '^node\s', '^ruby\s', '^perl\s', '^php\s', '^npx\s',
    # System/admin — always blocked
    '^certutil\s', '^bitsadmin\s', '^schtasks\s', '^reg\s', '^sc\s', '^icacls\s',
    '^cmd /c', '^cmd\.exe', '^powershell\s-c\s', '^powershell\s-command\s',
    '^powershell\s-enc\s', '^powershell\s-File\s', '^powershell\.exe',
    '^pwsh\s', '^pwsh\.exe',
    '^Start-Process', '^Invoke-Command', '^Register-ScheduledTask', '^New-Service',
    '^net user', '^net localgroup', '^net share', '^net use', '^net session',
    '^Add-MpPreference', '^Set-MpPreference',
    '^saps\s', '^start\s',
    # Push --force is always denied
    '^git push --force', '^git push -f'
)

# Semi-auto allowlist (safe commands that run without asking in semi mode)
$semiAllowPatterns = @(
    # Git read-only
    '^git status', '^git log', '^git diff', '^git show', '^git branch',
    '^git stash list', '^git stash show',
    # Filesystem read-only
    '^ls$', '^ls\s', '^dir$', '^dir\s', '^Get-ChildItem', '^Test-Path',
    '^pwd$', '^Get-Location', '^cat\s', '^Get-Content', '^type\s',
    # Output
    '^echo\s', '^Write-Output',
    # Search
    '^grep\s', '^rg\s', '^Select-String', '^findstr\s',
    # Query
    '^which\s', '^Get-Command', '^Get-Help', '^Get-Alias',
    # Build/test
    '^npm test', '^pytest\s', '^go test', '^Invoke-Pester',
    '^dotnet test', '^cargo test', '^npm run', '^npm ci',
    '^pip (freeze|list|show|install --user)(\s|$)',
    # Git read-only (no args)
    '^git stash list$', '^git status$', '^git diff$', '^git log$'
)

# Auto-mode: everything allowed EXCEPT pushes + denies + asks
$autoAskPatterns = @(
    '^git push$', '^git push\s', # git push ASKS (not denied) in auto mode
    '^git push --delete'
)

# ===== CLASSIFY =====
function Classify-Command {
    param([string]$cmd, [string]$mode)

    if (-not $cmd) { return 'help' }

    # 1. Check deny patterns (all modes)
    foreach ($p in $denyPatterns) {
        if ($cmd -match $p) { return 'deny' }
    }

    # 2. Mode-specific checks
    switch ($mode) {
        'manual' {
            # Everything asks unless allowed by explicit patterns
            # (deny patterns already checked above)
            return 'ask'
        }
        'semi' {
            # Check allowlist first
            foreach ($p in $semiAllowPatterns) {
                if ($cmd -match $p) { return 'allow' }
            }
            # Not in allowlist → ask
            return 'ask'
        }
        'auto' {
            # Check auto-mode ask patterns (push etc.)
            foreach ($p in $autoAskPatterns) {
                if ($cmd -match $p) { return 'ask' }
            }
            # Everything else → allow
            return 'allow'
        }
    }

    return 'ask' # safe default
}

# ===== OUTPUT =====
if ($ListModes) {
    $summaries = @{
        manual = "Manual: Everything asks (with built-in denials for network/interpreters/destructive)"
        semi   = "Semi:   Read-only git/filesystem/search/test auto-approve, writes ask, destructive denied"
        auto   = "Auto:   Everything auto-approves except git push (ask) and destructive/network (deny)"
    }
    if ($Json) {
        $summaries | ConvertTo-Json
    } else {
        $summaries.Values | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
    }
    return
}

try {
    $verdict = Classify-Command -cmd $Command -mode $Mode

    if ($Json) {
        @{
            action  = 'permission-gate'
            command = $Command
            mode    = $Mode
            verdict = $verdict
            rule    = switch ($verdict) {
                'deny'  { 'Built-in security restriction' }
                'allow' { "Allowed in $Mode mode" }
                'ask'   { "Requires confirmation in $Mode mode" }
                'help'  { 'No command provided' }
            }
        } | ConvertTo-Json
    } else {
        $icon = switch ($verdict) {
            'allow' { '✅' }
            'ask'   { '⏸️' }
            'deny'  { '❌' }
            'help'  { 'ℹ️' }
        }
        $modeLabel = $Mode.ToUpper().PadRight(8)
        Write-Host "$icon [$modeLabel] $Command" -NoNewline
        switch ($verdict) {
            'allow' { Write-Host " → ALLOW" -ForegroundColor Green }
            'ask'   { Write-Host " → ASK"  -ForegroundColor Yellow }
            'deny'  { Write-Host " → DENY" -ForegroundColor Red }
            'help'  { Write-Host "Usage: permission-gate.ps1 -Command '<cmd>' [-Mode manual|semi|auto]" }
        }
    }
} catch {
    Write-Error "Permission gate error: $_"
    exit 1
}
