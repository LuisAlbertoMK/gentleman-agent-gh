#requires -Version 5.1
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gentleman Agent — Permission Mode Switcher
.DESCRIPTION
    Switches between MANUAL, SEMI, and AUTO permission modes.
    Creates/reads .gentleman-mode file in the project root.

    MANUAL (default): Every command asks for permission (*: ask)
    SEMI:            Safe commands auto-execute (read-only, test), rest ask
    AUTO:            Everything auto-executes except push + destructive ops

.PARAMETER Mode
    Target mode: manual, semi, auto

.PARAMETER Status
    Show current mode without changing

.PARAMETER Help
    Show help banner

.EXAMPLE
    ./switch-mode.ps1 -Mode semi
    ./switch-mode.ps1 -Status
    ./switch-mode.ps1
#>

param(
    [ValidateSet('manual','semi','auto')][string]$Mode,
    [switch]$Status,
    [switch]$Help
)

# --- Resolve .gentleman-mode path ---
$scriptDir = Split-Path -Path $PSScriptRoot -Parent
$modeFile  = Join-Path -Path $scriptDir '.gentleman-mode'
$configFile = Join-Path -Path $scriptDir 'opencode.json'

# --- Banner colors ---
$colors = @{
    manual = @{ fg = 'Yellow';  icon = '🟡' }
    semi   = @{ fg = 'Cyan';    icon = '🔵' }
    auto   = @{ fg = 'Green';   icon = '🟢' }
}

# --- Read current mode ---
function Get-CurrentMode {
    if (Test-Path -LiteralPath $modeFile) {
        return (Get-Content -LiteralPath $modeFile -Raw).Trim()
    }
    return 'manual'
}

# --- Show banner ---
function Show-Banner {
    $current = Get-CurrentMode
    $c = $colors[$current]
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor $c.fg
    Write-Host "║       Gentleman Agent Permission Mode    ║" -ForegroundColor $c.fg
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor $c.fg
    Write-Host "║                                            ║" -ForegroundColor $c.fg
    Write-Host "║  $($c.icon)  Current: $($current.ToUpper().PadRight(32))║" -ForegroundColor $c.fg
    Write-Host "║                                            ║" -ForegroundColor $c.fg
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "║  Commands:                                 ║" -ForegroundColor DarkGray
    Write-Host "║  ./switch-mode.ps1 -Mode manual|semi|auto  ║" -ForegroundColor DarkGray
    Write-Host "║  ./switch-mode.ps1 -Status                 ║" -ForegroundColor DarkGray
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "║  manual:  Everything asks permission       ║" -ForegroundColor Yellow
    Write-Host "║  semi:    Safe commands auto-approve       ║" -ForegroundColor Cyan
    Write-Host "║  auto:    All auto except push + deletes   ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "║  Tip: Use in OpenCode: !manual / !semi /  ║" -ForegroundColor DarkGray
    Write-Host "║       !auto / !mode                        ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor $c.fg
}

# --- Show summary of what each mode allows ---
function Show-ModeDetail {
    param([string]$targetMode)

    $details = @{
        manual = @"
MANUAL MODE — Maximum safety
  Git:              All operations ask (status, diff, commit, push)
  File read:        Allowed but each command asks
  File write/edit:  Allowed but each command asks
  Scripts:          Each execution asks
  Network:          Denied (curl, ssh, docker, etc.)
  Destructive:      Denied (rm, Remove-Item, etc.)
  Interpreters:     Denied (python, node, ruby, etc.)

  Best for: Exploration, learning, untrusted code
"@
        semi = @"
SEMI-AUTO MODE — Balanced
  ✅ Git read:      status, log, diff, show, branch — auto
  ✅ File read:     ls, pwd, cat, grep, Test-Path — auto
  ✅ Build/test:    npm test, pytest, go test, Invoke-Pester — auto
  ⏸️ Git write:     commit, add, push — ask
  ⏸️ File create:   mkdir, New-Item — ask (unless whitelisted)
  ❌ Network:       Denied (curl, ssh, docker)
  ❌ Destructive:   Denied (rm, Remove-Item)
  ❌ Interpreters:  Denied (python, node)

  Best for: Daily development with guardrails
"@
        auto = @"
AUTO MODE — Maximum speed
  ✅ Git:           Everything auto except push (ask) and push --force (deny)
  ✅ File ops:      Read, write, edit — auto
  ✅ Scripts:       Execute — auto (except interpreters)
  ✅ Commit:        Auto (no ask)
  ⏸️ Git push:      Ask (unless --force, which is denied)
  ❌ Destructive:   Denied (rm, Remove-Item, curl, ssh, docker, python, node)

  Best for: Focused implementation, trusted environment
"@
    }

    Write-Host "`n$($details[$targetMode])" -ForegroundColor White
}

# ===== MAIN =====

if ($Help -or ($PSBoundParameters.Count -eq 0 -and -not $Status)) {
    Show-Banner
    Show-ModeDetail -targetMode (Get-CurrentMode)
    return
}

if ($Status) {
    $current = Get-CurrentMode
    Write-Output $current
    return
}

# --- Switching ---
$current = Get-CurrentMode

if ($Mode -eq $current) {
    $c = $colors[$Mode]
    Write-Host "`n$($c.icon)  Already in $Mode mode." -ForegroundColor $c.fg
    Show-ModeDetail -targetMode $Mode
    return
}

# Write the new mode
$Mode | Set-Content -LiteralPath $modeFile -NoNewline -Encoding ASCII
$c = $colors[$Mode]

Write-Host "`n$($c.icon)  Switched to $Mode mode." -ForegroundColor $c.fg
Write-Host "" -ForegroundColor $c.fg

Show-ModeDetail -targetMode $Mode

Write-Host "`n⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "   El cambio de modo requiere que el orquestador recargue la skill de routing." -ForegroundColor Yellow
Write-Host "   Los shortcuts !manual/!semi/!auto en OpenCode activan el modo completo." -ForegroundColor Yellow
Write-Host "   Para aplicar los permisos a nivel OpenCode runtime, se necesita:" -ForegroundColor Yellow
Write-Host "   1. Editar opencode.json con los agents -$Mode (ver docs adjuntos)" -ForegroundColor Yellow
Write-Host "   2. El orquestador usará agents con sufijo -$Mode en las delegaciones" -ForegroundColor Yellow
Write-Host "`n   Usa '!mode' en OpenCode para ver el modo actual." -ForegroundColor Cyan
