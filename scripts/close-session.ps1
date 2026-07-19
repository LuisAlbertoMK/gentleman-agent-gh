#requires -Version 7.6
<#
.SYNOPSIS
  Unified session close — BITACORA + git status + protected files + external auditor gate + mem_session_summary template.
  Designed for the !close workflow shortcut.
.DESCRIPTION
  Run this at session end BEFORE calling mem_session_summary.
  Handles: BITACORA log, git status check, protected files verification,
  external auditor gate (REQUIRED when code changes touch critical files).
  Outputs the structured info needed for the agent's Engram close protocol.
.PARAMETER Goal
  What was the session goal? Pre-fills the summary template.
.PARAMETER Description
  Short description of what was accomplished (logged to BITACORA).
.PARAMETER Quiet
  Output JSON only (machine-readable).
.PARAMETER CompactPrompt
  Output compact prompt preserving decisions only, dropping raw output.
.EXAMPLE
  .\scripts\close-session.ps1 -Goal "Implement !close, stdlib assertion, context-watchdog checkpoint"
.EXAMPLE
  .\scripts\close-session.ps1 -Goal "Fix N+1 query" -Description "Optimized UserList query" -Quiet
.EXAMPLE
  .\scripts\close-session.ps1 -Goal "Add auth middleware" -CompactPrompt
#>
param(
    [string]$Goal = "",
    [string]$Description = "Session close",
    [switch]$Quiet,
    [switch]$CompactPrompt
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$bitacoraPath = Join-Path -Path $repoRoot -ChildPath "BITACORA.md"
# ponytail: protected files — changes to these REQUIRE external audit
$protectedFiles = @(
    '.agents/skills/security-scanner/',
    '.agents/skills/quality-gate/',
    '.agents/skills/auto-metrics/',
    '.agents/skills/external-auditor/',
    '.agents/skills/immune-system/',
    'ANTI-PATTERN-CATALOG.md',
    '.project.json'
)
# Log to BITACORA
$entry = "$(Get-Date -Format 'yyyy-MM-dd') - $Description"
if (Test-Path -LiteralPath $bitacoraPath) {
    $existingContent = Get-Content -LiteralPath $bitacoraPath -Raw
    Set-Content -LiteralPath $bitacoraPath -Value "$entry`r`n$existingContent" -Encoding UTF8
}
# Git status
$gitStatus = git status --short 2>&1
$hasChanges = @($gitStatus | Where-Object { $_ -match '\S' }).Count -gt 0
try {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = "unknown" }
} catch { $branch = "unknown" }
# --- Protected files gate ---
$touchedProtected = @()
if ($hasChanges) {
    $changedFiles = @($gitStatus | ForEach-Object {
        if ($_ -match '^\s*[MADRCU\?]\s+(.+)$') { $matches[1] }
    })
    foreach ($pf in $protectedFiles) {
        # Match both / and \ in paths
        $escd = [regex]::Escape($pf).Replace('/', '[/\\]')
        foreach ($cf in $changedFiles) {
            if ($cf -match $escd) {
                $touchedProtected += $pf
                break
            }
        }
    }
}
$needsAudit = $touchedProtected.Count -gt 0
# --- AGENTS.md bloat gate ---
$agentsPath = Join-Path -Path $repoRoot -ChildPath "AGENTS.md"
$bloatWarning = $null
if (Test-Path -LiteralPath $agentsPath) {
    $agentsBytes = (Get-Item -LiteralPath $agentsPath).Length
    if ($agentsBytes -gt 15KB) {
        $bloatWarning = "AGENTS.md is $([math]::Round($agentsBytes/1KB,1))KB — exceeds 15KB threshold. Consider compressing."
    } elseif ($agentsBytes -gt 10KB) {
        $bloatWarning = "AGENTS.md is $([math]::Round($agentsBytes/1KB,1))KB — approaching 15KB threshold."
    }
}
# --- External auditor gate ---
$auditGatePassed = $true
if ($needsAudit) {
    $auditGatePassed = $false  # Blocks !close until external auditor runs
}
$result = [PSCustomObject]@{
    action            = "close-session"
    timestamp         = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    branch            = $branch
    hasChanges        = $hasChanges
    changeCount       = if ($hasChanges) { @($gitStatus | Where-Object { $_ -match '\S' }).Count } else { 0 }
    goal              = $Goal
    needsAudit        = $needsAudit
    protectedTouched  = $touchedProtected
    auditGatePassed   = $auditGatePassed
    bloatWarning      = $bloatWarning
}
# --- Session miner: scan for repeated error patterns ---
$minerOutput = $null
try {
    $minerResult = & "$PSScriptRoot\session-miner.ps1" -Mode check -Json 2>$null
    if ($minerResult) {
        $minerData = $minerResult | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($minerData -and $minerData.RepeatedPatterns -gt 0) {
            $minerOutput = "$($minerData.RepeatedPatterns) repeated pattern(s) detected — run dreaming to review"
        }
    }
} catch {
    Write-Debug "close-session: session-miner skipped ($($_.Exception.Message))"
}
if ($minerOutput) { $result | Add-Member -NotePropertyName "minerWarning" -NotePropertyValue $minerOutput }
# Compact prompt: show if explicitly requested, or when changes exist and not explicitly disabled
$showCompact = $CompactPrompt -or ($hasChanges -and -not $PSBoundParameters.ContainsKey('CompactPrompt'))
if ($showCompact -and -not $Quiet) {
    $diffFiles = if ($hasChanges) {
        ($gitStatus | Where-Object { $_ -match '\S' } | ForEach-Object { "  - $_" }) -join "`n"
    } else { "" }
    $keyDecisions = if ($Goal) { $Goal } else { "None recorded" }
    $nextActions = if ($needsAudit) {
        "⚠️ AUDIT GATE BLOCKED: run !audit first (protected files changed)"
    } elseif ($minerOutput) {
        "Review miner warning + commit $($result.changeCount) file(s), then run !dream"
    } elseif ($hasChanges) {
        "Review & commit $($result.changeCount) modified file(s), then run !score"
    } else { "Run !score if needed" }
@"
## COMPACT PROMPT FOR NEXT SESSION
- **Accomplished**: $Description
- **Key decisions**: $keyDecisions
- **Next actions**: $nextActions
$(if ($minerOutput) { "- **⚠️ Miner**: $minerOutput" })
$(if ($diffFiles) { "- **Pending changes**:`n$diffFiles" })
"@
}
if ($Quiet) {
    $result | ConvertTo-Json
} else {
    Write-Host "=== SESSION CLOSE ===" -ForegroundColor Cyan
    Write-Host "Branch : $branch"
    Write-Host "Changes: $(if($hasChanges){ "$($result.changeCount) file(s) modified" }else{ 'clean' })" -ForegroundColor Yellow
    Write-Host ""
    if ($bloatWarning) {
        Write-Host "⚠️  $bloatWarning" -ForegroundColor Yellow
        Write-Host ""
    }
    if ($minerOutput) {
        Write-Host "⛏️  $minerOutput" -ForegroundColor DarkYellow
        Write-Host "    Run '!dream' to review repeated patterns." -ForegroundColor DarkYellow
        Write-Host ""
    }
    if ($needsAudit) {
        Write-Host "⚠️  REQUIRED: External auditor gate BLOCKED" -ForegroundColor Red
        Write-Host "    Protected files modified:" -ForegroundColor Red
        foreach ($pf in $touchedProtected) {
            Write-Host "    - $pf" -ForegroundColor Red
        }
        Write-Host "    Run '!audit' before '!close' to pass the gate." -ForegroundColor Red
        Write-Host "    Gate: external-auditor must PASS before this session can close." -ForegroundColor Red
        Write-Host ""
    }
    if ($hasChanges -and -not $needsAudit) {
        Write-Host "Run '!score' to update project score after changes." -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "--- mem_session_summary ---" -ForegroundColor Yellow
    Write-Host "Call with:" -ForegroundColor Yellow
    Write-Host "## Goal" -ForegroundColor Gray
    if ($Goal) { Write-Host "$Goal" -ForegroundColor White }
    Write-Host "## Instructions" -ForegroundColor Gray
    Write-Host "## Discoveries" -ForegroundColor Gray
    Write-Host "## Accomplished" -ForegroundColor Gray
    Write-Host "## Next Steps" -ForegroundColor Gray
    Write-Host "## Relevant Files" -ForegroundColor Gray
}