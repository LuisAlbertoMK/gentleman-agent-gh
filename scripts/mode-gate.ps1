#requires -Version 7
[CmdletBinding()]
<#
.SYNOPSIS
    Mode Gate — single-mode pre-delegation validation (Refactor-AP S2).
.DESCRIPTION
    Single-mode gate (gentle-ai style): there is only ONE mode. Every
    delegation target is ALLOWED; the retired `-auto` / `-semi` suffixes are
    accepted as backward-compat aliases (with a warning), and
    `.gentleman-mode` is a no-op — the file stays on disk for switch-mode
    compat but is always treated as 'manual'.

    The security deny-floor (bash deny-list, push deny, ask-list) is enforced
    elsewhere (opencode-base.json + permission-gate) and is UNAFFECTED by
    this gate being permissive by design (upstream gentle-ai: single mode,
    human-owned push/release).

    Refactor-AP S2 retired the auto/manual/semi suffix enforcement.
    Fallback mode: 'manual'.

.PARAMETER TargetAgent
    The intended delegation target (e.g., "gentleman-quick").

.PARAMETER Mode
    Accepted for backward compat only; any value is treated as 'manual'.
    A non-manual value emits a warning.

.PARAMETER ModeFilePath
    Override the mode file path (default: nearest .gentleman-mode walking up from
    cwd, bounded by the project root — see Get-GentlemanProjectRoot).

.PARAMETER Json
    Output JSON instead of human-readable text.

.EXAMPLE
    .\scripts\mode-gate.ps1 -TargetAgent "gentleman-quick"
    .\scripts\mode-gate.ps1 -TargetAgent "gentleman-quick-auto" -Json
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetAgent,

    [string]$Mode,

    [switch]$Json,

    [string]$ModeFilePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Cross-platform helpers (Get-GentlemanProjectRoot)
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")

$projectRoot = if (Get-Command Get-GentlemanProjectRoot -ErrorAction SilentlyContinue) { Get-GentlemanProjectRoot } else { (Get-Location).Path }

# --- Resolve .gentleman-mode: nearest file walking up from cwd, NEVER past the
#     project root (git root) — no repo fallback, so an external project without
#     its own mode file cannot inherit the repo's mode. Mirrors switch-mode. ---
$modeFile = if ($ModeFilePath) {
    $ModeFilePath
} else {
    $found = $null
    $dir = (Get-Location).Path
    while ($dir) {
        $candidate = Join-Path -Path $dir '.gentleman-mode'
        if (Test-Path -LiteralPath $candidate) { $found = $candidate; break }
        if ($dir -eq $projectRoot) { break }
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    if ($found) { $found } else { Join-Path -Path $projectRoot '.gentleman-mode' }
}

# --- Resolve current mode (single-mode: always 'manual') ---
if (-not $Mode) {
    if (Test-Path -LiteralPath $modeFile) {
        $Mode = (Get-Content -LiteralPath $modeFile -Raw).Trim()
    } else {
        $Mode = 'manual'  # default fallback
    }
}
if (-not $Mode) { $Mode = 'manual' }

# --- Refactor-AP S2 single-mode: mode file / -Mode are no-ops ---
if ($Mode -ne 'manual') {
    Write-Warning "Single-mode (Refactor-AP S2): mode '$Mode' is a no-op — treating as 'manual'. Suffixes -auto/-semi are compat aliases."
    $Mode = 'manual'
}

# --- Compat aliases: retired -auto / -semi suffixes accepted with warning ---
$aliasSuffix = ''
$baseAgent = $TargetAgent
if ($TargetAgent -match '(?<suffix>-auto|-semi)$') {
    $aliasSuffix = $Matches['suffix']
    $baseAgent = $TargetAgent.Substring(0, $TargetAgent.Length - $aliasSuffix.Length)
    Write-Warning "Single-mode (Refactor-AP S2): '$TargetAgent' uses retired suffix '$aliasSuffix' — compat alias for '$baseAgent'."
}

# --- Single-mode: everything is ALLOWED, exit 0 by default ---
$modeOk = $true
$expectedSuffix = ''

# --- Build result (JSON field contract unchanged) ---
$result = [PSCustomObject]@{
    action          = 'mode-gate'
    mode            = $Mode
    target_agent    = $TargetAgent
    expected_suffix = $expectedSuffix
    allowed         = $modeOk
    reason          = if ($aliasSuffix) {
        "Compat alias: '$TargetAgent' accepted as '$baseAgent' (retired '$aliasSuffix' suffix, single-mode)"
    } else {
        "Single-mode — no suffix required (mode file is a no-op)"
    }
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json)
    exit 0
}

# --- Human-readable output ---
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         Mode Gate — Delegation Check    ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  ✅  Mode:  $($Mode.ToUpper().PadRight(36))║" -ForegroundColor Green
Write-Host "║  ✅  Agent: $($TargetAgent.PadRight(36))║" -ForegroundColor Green
Write-Host "║  ✅  Suffix: $($expectedSuffix.PadRight(35))║" -ForegroundColor Green
Write-Host "║                                            ║" -ForegroundColor Green
Write-Host "║  ══ ALLOWED ══" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green

exit 0
