#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
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
    [switch]$CompactPrompt,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$SkipSummaryGate,
    [switch]$Checkpoint,
    [string[]]$Discoveries,
    [string[]]$Decisions,
    [string[]]$Errors,
    [string]$BitacoraPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$bitacoraPath = if ($BitacoraPath) { $BitacoraPath } else { Join-Path -Path $repoRoot -ChildPath "BITACORA.md" }
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
# Log to BITACORA (with dedup guard)
$entry = "$(Get-Date -Format 'yyyy-MM-dd') - $Description"
if (Test-Path -LiteralPath $bitacoraPath) {
    $existingLines = Get-Content -LiteralPath $bitacoraPath
    # Guard: skip if exact entry already exists anywhere (prevents multi-session duplicate chains)
    $isDup = $null -ne ($existingLines | Where-Object { $_.Trim() -eq $entry.Trim() } | Select-Object -First 1)
    if (-not $isDup) {
        $existingContent = $existingLines -join "`r`n"
        Set-Content -LiteralPath $bitacoraPath -Value "$entry`r`n$existingContent" -Encoding UTF8
    }
}
# --- Inter-track increment (CYCLE.md LOOP step 6c: "Log a bitacora + inter-track++") ---
if (Test-Path -LiteralPath "$PSScriptRoot/inter-track.ps1") {
    try {
        $itPrev = if (Test-Path ".learnings\inter-track.json") {
            (Get-Content ".learnings\inter-track.json" -Raw | ConvertFrom-Json -EA SilentlyContinue).cycle.count
        } else { 0 }
        # Suppress stdout/stderr — inter-track -Quiet outputs JSON to stdout
        # Skip increment in test mode (PESTER_TEST=1) to prevent test pollution
        if (-not $env:PESTER_TEST) {
            & "$PSScriptRoot/inter-track.ps1" -Increment -Quiet
        }
        $itNew = if (Test-Path ".learnings\inter-track.json") {
            (Get-Content ".learnings\inter-track.json" -Raw | ConvertFrom-Json -EA SilentlyContinue).cycle.count
        } else { $itPrev }
        if (-not $Quiet -and $itNew -ne $itPrev) {
            Write-Host "  📊 inter-track: $itPrev → $itNew (IC/IT)" -ForegroundColor Cyan
        }
    } catch {
        Write-Debug "close-session: inter-track increment skipped ($($_.Exception.Message))"
    }
}

# Git status
$savedEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"; $gitStatus = git status --short 2>$null; $ErrorActionPreference = $savedEap
$gitStatusLines = @($gitStatus | Where-Object { $_ -match '\S' })
$hasChanges = $gitStatusLines.Count -gt 0
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
# --- Session summary gate ---
$summaryLockPath = Join-Path -Path $repoRoot -ChildPath ".opencode\session-summary.lock"
$summaryGatePassed = $true
if (-not (Test-Path -LiteralPath $summaryLockPath) -and -not $SkipSummaryGate) {
    $summaryGatePassed = $false
    if (-not $Quiet) {
        Write-Host "⚠️  SESSION SUMMARY NOT CONFIRMED: call mem_session_summary before !close" -ForegroundColor Yellow
        Write-Host ""
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
    changeCount       = if ($hasChanges) { $gitStatusLines.Count } else { 0 }
    goal              = $Goal
    needsAudit        = $needsAudit
    protectedTouched  = $touchedProtected
    auditGatePassed   = $auditGatePassed
    summaryGatePassed = $summaryGatePassed
    bloatWarning      = $bloatWarning
}
# Force override for summary gate
if (-not $summaryGatePassed -and $Force) {
    $summaryGatePassed = $true
}
# --- Session miner: populate from discoveries then scan for patterns ---
$minerOutput = $null
try {
    $hasSessionData = ($Discoveries -and $Discoveries.Count -gt 0) -or ($Errors -and $Errors.Count -gt 0)
    if ($hasSessionData) {
        if ($Discoveries) { Write-Debug "close-session: passing $($Discoveries.Count) discovery(ies) to session-miner" }
        if ($Errors) { Write-Debug "close-session: passing $($Errors.Count) error(s) to session-miner" }
        $minerMode = "populate"
    } else {
        $minerMode = "check"
    }
    $minerParams = @{ Mode = $minerMode; Json = $true }
    if ($Discoveries) { $minerParams.PatternKeys = $Discoveries }
    if ($Errors) { $minerParams.ErrorEntries = $Errors }
    $minerResult = & "$PSScriptRoot\session-miner.ps1" @minerParams 2>$null
    if ($minerResult) {
        $minerData = $minerResult | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($minerData -and $minerData.RepeatedPatterns -gt 0) {
            $minerOutput = "$($minerData.RepeatedPatterns) repeated pattern(s) detected — run dreaming to review"
        }
        if ($hasSessionData -and $minerData -and -not $Quiet) {
            $dc = if ($Discoveries) { $Discoveries.Count } else { 0 }
            $ec = if ($Errors) { $Errors.Count } else { 0 }
            Write-Host "  ⛏️  Session-miner: $($dc+$ec) entries ingested, $($minerData.RepeatedPatterns) repeated patterns found" -ForegroundColor DarkYellow
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
        ($gitStatusLines | ForEach-Object { "  - $_" }) -join "`n"
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
    if ($summaryGatePassed) {
        Write-Host "✅ Session summary confirmed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Run mem_session_summary before closing" -ForegroundColor Yellow
    }
    Write-Host ""
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
    # --- Token ledger summary (engram-auto-capture I/R 3.0) ---
    $ledgerFile = Join-Path (Join-Path $repoRoot '.learnings') 'token-ledger.jsonl'
    if (Test-Path -LiteralPath $ledgerFile) {
        try {
            $entries = @(Get-Content -LiteralPath $ledgerFile -Tail 20 | ConvertFrom-Json -ErrorAction SilentlyContinue)
            $total = @($entries | Measure-Object -Property tokens -Sum).Sum
            Write-Host "  ledger: $($entries.Count) entries, ~$total tokens (auto-capture)" -ForegroundColor DarkGray
        } catch { Write-Debug "ledger summary: $($_.Exception.Message)" }
    }

    # --- Checkpoint bridge integration (medium-term memory) — G7 hard gate ---
    # .ps1 cannot call MCP engram_mem_save; this bridge emits directive for orchestrator.
    # Orchestrator MUST read checkpoint_file + mem_save_directive and call engram_mem_save.
    if ($Checkpoint) {
        $checkpointPath = Join-Path $PSScriptRoot "session-checkpoint.ps1"
        if (Test-Path -LiteralPath $checkpointPath) {
            $cpParams = @("-Mode", "full", "-Quiet")
            if ($Discoveries) { $cpParams += "-Discoveries"; $cpParams += $Discoveries }
            if ($Decisions) { $cpParams += "-Decisions"; $cpParams += $Decisions }
            if ($Errors) { $cpParams += "-Errors"; $cpParams += $Errors }
            $cpRaw = & "$PSScriptRoot/session-checkpoint.ps1" @cpParams 2>&1 | Out-String
            $cpResult = $null
            try {
                $cpResult = $cpRaw | ConvertFrom-Json -ErrorAction Stop
            } catch {
                # Fallback: read pending-engram.json if JSON parse failed
                $pendingPath = Join-Path $PSScriptRoot "..\.opencode\session-checkpoints\pending-engram.json"
                if (Test-Path -LiteralPath $pendingPath) {
                    try {
                        $pendingContent = Get-Content -LiteralPath $pendingPath -Raw -ErrorAction Stop
                        $cpResult = $pendingContent | ConvertFrom-Json -ErrorAction Stop
                        $cpResult.checkpoint_created = $true  # we know it was created since file exists
                    } catch {
                        Write-Debug "Checkpoint bridge: fallback read of pending-engram.json failed: $($_.Exception.Message)"
                    }
                }
            }
            if ($cpResult -and $cpResult.checkpoint_created) {
                Write-Host "💾 Checkpoint saved (zone: $($cpResult.zone), $($cpResult.percent)%)" -ForegroundColor Cyan
                if ($cpResult.mem_save_directive) {
                    Write-Host "  → mem_save_directive: $($cpResult.mem_save_directive | ConvertTo-Json -Compress)" -ForegroundColor DarkGray
                    Write-Host "  ORCHESTRATOR ACTION REQUIRED: call engram_mem_save with above directive (topic_key=checkpoint/session-state)" -ForegroundColor Yellow
                }
                if ($cpResult.checkpoint_file) { Write-Host "  File: $($cpResult.checkpoint_file)" -ForegroundColor DarkGray }
            }
        }
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
