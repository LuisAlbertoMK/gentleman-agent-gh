#requires -Version 5.1
<#
.SYNOPSIS
    Mode Gate — pre-delegation validation. Verifies agent suffix matches current mode.
.DESCRIPTION
    Before delegating to a sub-agent, the orchestrator MUST call this gate.
    It reads .gentleman-mode and validates that the target agent name has the
    correct suffix for the current mode.

    Mode → Required suffix:
      auto   → -auto (e.g., gentleman-quick → gentleman-quick-auto)
      semi   → -semi (e.g., gentleman-quick → gentleman-quick-semi)
      manual → no suffix (e.g., gentleman-quick → gentleman-quick)

    If the suffix doesn't match, the gate BLOCKS the delegation with a clear error.

.PARAMETER TargetAgent
    The intended delegation target (e.g., "gentleman-quick").

.PARAMETER Mode
    Override mode check (default: read from .gentleman-mode).

.PARAMETER Json
    Output JSON instead of human-readable text.

.EXAMPLE
    .\scripts\mode-gate.ps1 -TargetAgent "gentleman-quick-auto"
    .\scripts\mode-gate.ps1 -TargetAgent "gentleman-quick" -Mode auto -Json
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetAgent,

    [ValidateSet('manual', 'semi', 'auto')]
    [string]$Mode,

    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$modeFile = Join-Path -Path $repoRoot '.gentleman-mode'

# --- Resolve current mode ---
if (-not $Mode) {
    if (-not (Test-Path -LiteralPath $modeFile)) {
        $Mode = 'manual'  # default fallback
    } else {
        $Mode = (Get-Content -LiteralPath $modeFile -Raw).Trim()
    }
}

# --- Determine expected suffix ---
$suffixMap = @{
    'auto'   = '-auto'
    'semi'   = '-semi'
    'manual' = ''
}
$expectedSuffix = $suffixMap[$Mode]

# --- Determine if agent is a read-only specialist (always exception) ---
$readOnlySpecialists = @(
    'gentleman-security',
    'gentleman-seo',
    'gentleman-infra',
    'gentleman-frontend',
    'gentleman-performance',
    'gentleman-datascience',
    'gentleman-docs',
    'gentleman-reviewer'
)
$isReadOnly = $TargetAgent -in $readOnlySpecialists

# --- Validate ---
$hasSuffix = $TargetAgent -match '-auto$|-semi$'
$modeOk = $false

if ($isReadOnly) {
    $modeOk = $true  # Read-only specialists always use base name
} elseif ($Mode -eq 'manual') {
    $modeOk = -not $hasSuffix  # No suffix allowed in manual
} elseif ($Mode -eq 'auto') {
    $modeOk = $TargetAgent -match '-auto$'
} elseif ($Mode -eq 'semi') {
    $modeOk = $TargetAgent -match '-semi$'
}

# --- Read-only and SDD sub-agents are always allowed ---
$alwaysAllowed = @(
    'gentleman-orchestrator',
    'sdd-init',
    'sdd-explore',
    'sdd-propose',
    'sdd-design',
    'sdd-spec',
    'sdd-tasks',
    'sdd-apply',
    'sdd-verify',
    'sdd-archive',
    'sdd-quick'
)
$isAlwaysAllowed = $TargetAgent -in $alwaysAllowed

if ($isAlwaysAllowed) {
    $modeOk = $true
}

# --- Build result ---
$result = [PSCustomObject]@{
    action          = 'mode-gate'
    mode            = $Mode
    target_agent    = $TargetAgent
    expected_suffix = $expectedSuffix
    allowed         = $modeOk
    reason          = if ($modeOk) {
        if ($isAlwaysAllowed) { "Always-allowed agent: $TargetAgent" }
        elseif ($isReadOnly) { "Read-only specialist: $TargetAgent" }
        elseif ($Mode -eq 'manual') { "Manual mode — no suffix required" }
        else { "Mode '$Mode' — suffix '$expectedSuffix' matches" }
    } else {
        if ($Mode -eq 'auto') { "AUTO mode requires -auto suffix (got: $TargetAgent, expected: $TargetAgent-auto)" }
        elseif ($Mode -eq 'semi') { "SEMI mode requires -semi suffix (got: $TargetAgent, expected: $TargetAgent-semi)" }
        else { "MANUAL mode requires NO suffix (got: $TargetAgent, expected: $TargetAgent without suffix)" }
    }
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json)
    if (-not $modeOk) { exit 1 } else { exit 0 }
}

# --- Human-readable output ---
$fg = if ($modeOk) { 'Green' } else { 'Red' }
$icon = if ($modeOk) { '✅' } else { '❌' }
$status = if ($modeOk) { 'ALLOWED' } else { 'BLOCKED' }

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor $fg
Write-Host "║         Mode Gate — Delegation Check    ║" -ForegroundColor $fg
Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor $fg
Write-Host "║  $icon  Mode:  $($Mode.ToUpper().PadRight(36))║" -ForegroundColor $fg
Write-Host "║  $icon  Agent: $($TargetAgent.PadRight(36))║" -ForegroundColor $fg
Write-Host "║  $icon  Suffix: $($expectedSuffix.PadRight(35))║" -ForegroundColor $fg
Write-Host "║                                            ║" -ForegroundColor $fg
Write-Host "║  ══ $status ══" -ForegroundColor $fg
if (-not $modeOk) {
    Write-Host "║                                            ║" -ForegroundColor $fg
    Write-Host "║  $($result.reason.PadRight(44))║" -ForegroundColor $fg
}
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor $fg

if (-not $modeOk) {
    exit 1
}
exit 0
