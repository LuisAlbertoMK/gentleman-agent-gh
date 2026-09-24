#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Single-mode agent routing — always resolves the base agent name (Refactor-AP S2).

.DESCRIPTION
    Single-mode routing (gentle-ai style): there is only ONE mode. Every
    base agent resolves to itself with NO suffix. The retired `-auto` /
    `-semi` suffixes and `.gentleman-mode` / `-Mode` values are no-ops
    accepted for backward compat (with a warning); effective mode is
    always 'manual'.

    Read-only specialists, SDD phase subagents and mode-aware core agents
    all execute directly with no suffix.

.PARAMETER BaseAgent
    Base agent name without mode suffix (e.g. gentleman-quick, gentleman-deep-sub).

.PARAMETER Mode
    Override mode instead of reading .gentleman-mode. If empty, reads the
    nearest .gentleman-mode file (walking up from cwd, stopping at project root).
    Defaults to 'manual' when no mode file is found.

.PARAMETER Json
    Emit machine-readable JSON (baseAgent, mode, targetAgent, suffix, note).

.EXAMPLE
    .\scripts\route-agent.ps1 -BaseAgent gentleman-quick
    .\scripts\route-agent.ps1 -BaseAgent gentleman-security-sub  # → no suffix
    .\scripts\route-agent.ps1 -BaseAgent gentleman-quick -Mode auto -Json  # mode no-op → no suffix
#>
param(
    [Parameter(Mandatory)]
    [string]$BaseAgent,

    [string]$Mode = "",

    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\platform.ps1")

# --- Agents that have -semi / -auto variants (per README + use-gentleman.ps1) ---
# Only these 5 core agent families support mode-aware routing.
$ModeAwareAgents = @('gentleman-vMK', 'gentle-MK', 'gentleman-deep', 'gentleman-quick', 'gentleman-codex', 'gentleman-implementer')

# --- Read-only specialists: NO suffix ever (per AGENTS.md: "always execute") ---
$ReadOnlySpecialists = @(
    'gentleman-security-sub', 'gentleman-seo-sub', 'gentleman-infra-sub',
    'gentleman-frontend-sub', 'gentleman-performance-sub',
    'gentleman-datascience-sub', 'gentleman-docs-sub', 'gentleman-reviewer'
)

# --- Resolve mode ---
if (-not $Mode) {
    $projectRoot = if (Get-Command Get-GentlemanProjectRoot -ErrorAction SilentlyContinue) {
        Get-GentlemanProjectRoot
    } else {
        (Get-Location).Path
    }
    $modeFile = Join-Path $projectRoot '.gentleman-mode'
    if (Test-Path -LiteralPath $modeFile) {
        $Mode = (Get-Content -LiteralPath $modeFile -Raw).Trim()
    } else {
        $Mode = 'manual'   # protocol default
    }
}

# --- Refactor-AP S2 single-mode: mode file / -Mode are no-ops ---
if ($Mode -ne 'manual') {
    Write-Warning "Single-mode (Refactor-AP S2): mode '$Mode' is a no-op — treating as 'manual'. Suffixes -auto/-semi are compat aliases."
    $Mode = 'manual'
}

# --- Compat alias: retired -auto / -semi suffix on input accepted with warning ---
$aliasSuffix = ''
$canonicalBase = $BaseAgent
if ($BaseAgent -match '(?<suffix>-auto|-semi)$') {
    $aliasSuffix = $Matches['suffix']
    $canonicalBase = $BaseAgent.Substring(0, $BaseAgent.Length - $aliasSuffix.Length)
    Write-Warning "Single-mode (Refactor-AP S2): '$BaseAgent' uses retired suffix '$aliasSuffix' — compat alias for '$canonicalBase'."
}

# --- Routing logic (single-mode: always no suffix) ---
$note = ""
if ($ReadOnlySpecialists -contains $canonicalBase) {
    $TargetAgent = $canonicalBase
    $suffix      = ""
    $note        = "read-only specialist — no suffix (single-mode)"
}
elseif ($ModeAwareAgents -contains $canonicalBase) {
    $TargetAgent = $canonicalBase
    $suffix      = ""
    $note        = "single-mode — no suffix (mode file is a no-op)"
}
else {
    # SDD phase agents (sdd-*) and non-mode-aware subagent twins (gentleman-*-sub): no suffix
    $TargetAgent = $canonicalBase
    $suffix      = ""
    # Warn for truly unknown agents (not sdd-* or *-sub variants)
    if ('sdd', '-sub' | Where-Object { $canonicalBase.Contains($_) }) {
        $note = "non-mode-aware agent — no suffix"
    } else {
        Write-Warning "route-agent: '$canonicalBase' is not a recognized agent — no suffix applied"
        $note = "unknown agent — no suffix (WARNING)"
    }
}
if ($aliasSuffix) { $note += " (compat alias for retired '$aliasSuffix' suffix)" }

if ($Json) {
    return [PSCustomObject]@{
        baseAgent    = $BaseAgent
        mode         = $Mode
        targetAgent  = $TargetAgent
        suffix       = $suffix
        note         = $note
    } | ConvertTo-Json -Compress
}

# Human-readable output for direct invocation
Write-Output "🔀 → $TargetAgent | $note"

    return $TargetAgent
