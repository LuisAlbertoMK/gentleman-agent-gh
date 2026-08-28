#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Gentleman Agent — Permission Mode Switcher
.DESCRIPTION
  Switches between MANUAL and AUTO permission modes.
  Reads the nearest .gentleman-mode walking up from the current directory,
  bounded by the project root (first .git — Get-GentlemanProjectRoot), so a
  global copy of this script still honors the external project's mode without
  inheriting a mode from HOME or unrelated ancestors.
  When no mode file exists, defaults to MANUAL; writes target the current
  directory (cwd) so a -Mode switch creates .gentleman-mode in the project.

  MANUAL (default): Every command asks for permission (*: ask)
  AUTO:            Everything auto-executes except push + destructive ops

  NOTE: SEMI mode is DEPRECATED (see ADR-033). Passing -Mode semi emits a
  warning and falls back to AUTO. The 'semi' value is accepted for backward
  compatibility but will be removed in a future revision.

.PARAMETER Mode
  Target mode: manual or auto (semi accepted but deprecated, falls back to auto)

.PARAMETER Status
    Show current mode without changing

.PARAMETER Help
    Show help banner

.PARAMETER DryRun
    Reserved for parity with sibling scripts; accepted but not used
    by the switch logic.

.PARAMETER Force
    Reserved for parity with sibling scripts; accepted but not used
    by the switch logic.

.EXAMPLE
    ./switch-mode.ps1 -Mode manual
    ./switch-mode.ps1 -Mode auto
    ./switch-mode.ps1 -Status
    ./switch-mode.ps1

    NOTE: `./switch-mode.ps1 -Mode semi` is accepted for backward compat but emits
    a deprecation warning and falls back to 'auto' (see ADR-033).
#>

param(
    [string]$Mode,
    [switch]$Status,
    [switch]$Help,
    [switch]$Force,
    [switch]$DryRun
,
    [switch]$Quiet,
    [switch]$Json)
Set-StrictMode -Version Latest

# --- Legacy 'semi' handling (DEPRECATED per ADR-033) ---
# Accept 'semi' at the CLI for backward compat but translate to 'auto' with a
# deprecation warning. ValidateSet was removed (it would Parameter-binding-
# reject 'semi' before this block runs). Manual validation enforced below.
if ($Mode) { $Mode = $Mode.ToLower() }
if ($Mode -eq 'semi') {
    Write-Host ""
    Write-Host "⚠️  DEPRECATION WARNING: 'semi' mode is deprecated (ADR-033: simplified to manual+auto)."
    Write-Host "   Falling back to 'auto' mode (semi's read-only allowlist is now covered by the"
    Write-Host "   runtime behavioral gate deny-floor in permission-gate.ps1: curl, ssh, docker,"
    Write-Host "   rm, Remove-Item, python, node, etc. are still denied)."
    Write-Host ""
    $Mode = 'auto'
}
if ($Mode -and $Mode -notin 'manual','auto') {
    Write-Error "Invalid mode '$Mode'. Valid modes: manual, auto. (semi is deprecated, maps to auto.)"
    exit 1
}

# --- Resolve .gentleman-mode: nearest file walking up from cwd, bounded by the
#     project root (git root). Never past the project → no mode inheritance from
#     HOME or unrelated ancestors. Write targets cwd when absent. ---
$platformLib = Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1"
if (Test-Path -LiteralPath $platformLib) { . $platformLib }
$modeFile = $null
$dir = (Get-Location).Path
$projectRoot = if (Get-Command Get-GentlemanProjectRoot -ErrorAction SilentlyContinue) { Get-GentlemanProjectRoot } else { $dir }
while ($dir) {
    $candidate = Join-Path -Path $dir '.gentleman-mode'
    if (Test-Path -LiteralPath $candidate) { $modeFile = $candidate; break }
    if ($dir -eq $projectRoot) { break }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $modeFile) { $modeFile = Join-Path -Path $projectRoot '.gentleman-mode' }

# --- Banner colors ---
$colors = @{
    manual = @{ fg = 'Yellow';  icon = '🟡' }
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
    Write-Host "║  ./switch-mode.ps1 -Mode manual|auto       ║" -ForegroundColor DarkGray
    Write-Host "║  ./switch-mode.ps1 -Status                 ║" -ForegroundColor DarkGray
    Write-Host "║  (semi deprecated → falls back to auto)    ║" -ForegroundColor DarkGray
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "║  manual:  Everything asks permission       ║" -ForegroundColor Yellow
    Write-Host "║  auto:    All auto except push + deletes   ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor DarkGray
    Write-Host "║  Tip: Use in OpenCode: !manual / !auto      ║" -ForegroundColor DarkGray
    Write-Host "║       !mode    (semi deprecated→auto)      ║" -ForegroundColor DarkGray
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor $c.fg
}

# --- Show summary of what each mode allows ---
function Show-ModeDetail {
    param([string]$targetMode)
    $N = [Environment]::NewLine
    $text =     switch ($targetMode) {
        manual { "MANUAL MODE --- Maximum safety${N}  Git:              All operations ask${N}  File read:        Allowed but each command asks${N}  File write/edit:  Allowed but each command asks${N}  Scripts:          Each execution asks${N}  Network:          Denied (curl, ssh, docker, etc.)${N}  Destructive:      Denied (rm, Remove-Item, etc.)${N}  Interpreters:     Denied (python, node, ruby, etc.)${N}${N}  Best for: Exploration, learning, untrusted code" }
        auto   { "AUTO MODE --- Maximum speed (autonomous on request)${N}  [OK] Git:           Everything auto except push${N}  [OK] File ops:      Read, write, edit --- auto${N}  [OK] Scripts:       Execute --- auto${N}  [OK] Commit:        Auto (no ask)${N}  [..] Git push:      Ask (unless --force, which is denied)${N}  [..] Deletes:       Ask (rm, Remove-Item, branch -D, stash drop)${N}  [NO] Network:       Denied (curl, ssh, docker, python, node)${N}${N}  Best for: Focused implementation, trusted environment" }
    }
    $text = $text -replace '\[OK\]', '✅' -replace '\[..\]', '⏸️ ' -replace '\[NO\]', '❌'
    Write-Host "${N}${text}" -ForegroundColor White
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
try {
    $Mode | Set-Content -LiteralPath $modeFile -NoNewline -Encoding ASCII -ErrorAction Stop
} catch {
    Write-Error "Failed to write mode file: $_"
    exit 1
}
$c = $colors[$Mode]

Write-Host "`n$($c.icon)  Switched to $Mode mode." -ForegroundColor $c.fg
Write-Host "" -ForegroundColor $c.fg

Show-ModeDetail -targetMode $Mode

Write-Host "`n⚠️  IMPORTANTE:" -ForegroundColor Yellow
Write-Host "   El cambio de modo requiere que el orquestador recargue la skill de routing." -ForegroundColor Yellow
    Write-Host "   Los shortcuts !manual/!auto en OpenCode activan el modo completo." -ForegroundColor Yellow
Write-Host "   Para aplicar los permisos a nivel OpenCode runtime, se necesita:" -ForegroundColor Yellow
Write-Host "   1. Editar opencode.json con los agents -$Mode (ver docs adjuntos)" -ForegroundColor Yellow
Write-Host "   2. El orquestador usará agents con sufijo -$Mode en las delegaciones" -ForegroundColor Yellow
Write-Host "`n   Usa '!mode' en OpenCode para ver el modo actual." -ForegroundColor Cyan
