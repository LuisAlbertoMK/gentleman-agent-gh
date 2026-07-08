#requires -Version 7.6
<#
.SYNOPSIS
    Demote stale patterns and remove unused forged skills.
.DESCRIPTION
    Periodic maintenance for the Pattern Store:
    - Demotes patterns with 0 hits in 90+ days → deprecated
    - Removes forged skills that haven't been resolved in 14+ days
    - Archives deprecated patterns older than 180 days
.PARAMETER All
    Run all checks (demote + remove + archive).
.PARAMETER DemoteOnly
    Only check for stale patterns (90d no hits).
.PARAMETER RemoveOnly
    Only check for unused forged skills (14d).
.PARAMETER ArchiveOnly
    Only archive patterns deprecated >180d.
.PARAMETER DryRun
    Report what would change without making changes.
.PARAMETER Quiet
    Output JSON only.

.EXAMPLE
    .\scripts\wisdom-demote.ps1 -All
    .\scripts\wisdom-demote.ps1 -DemoteOnly -DryRun
    .\scripts\wisdom-demote.ps1 -All -Quiet

.NOTES
    Designed to run via !dream or as scheduled maintenance (cron / Task Scheduler).
#>
param(
    [switch]$All,
    [switch]$DemoteOnly,
    [switch]$RemoveOnly,
    [switch]$ArchiveOnly,
    [switch]$DryRun,
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$patternsDir = Join-Path $repoRoot "docs" "cross-project" "patterns"
$skillsDir = Join-Path $repoRoot ".agents" "skills"
$archivedDir = Join-Path $repoRoot "docs" "cross-project" "archived"

# Default: run all if no flag
$runAll = $All -or (-not $DemoteOnly -and -not $RemoveOnly -and -not $ArchiveOnly)

$changes = @()  # { Action, Target, Reason }

# ─── 1. Demote stale patterns (90d no hits) ───────────────────
if ($runAll -or $DemoteOnly) {
    if (-not (Test-Path $patternsDir)) {
        if (-not $Quiet) { Write-Host "[SKIP] No patterns directory" }
    } else {
        $patternFiles = @(Get-ChildItem $patternsDir -Filter "*.json")
        $dataAtual = Get-Date

        foreach ($file in $patternFiles) {
            try {
                $pattern = Get-Content $file.FullName -Raw | ConvertFrom-Json
            } catch { continue }

            $status = if ($pattern.status) { $pattern.status } else { "active" }
            # Only process active patterns
            if ($status -ne "active") { continue }

            $updatedStr = if ($pattern.updated) { $pattern.updated } else { $pattern.created }
            if (-not $updatedStr) { continue }

            $updatedDate = try { [DateTime]::ParseExact($updatedStr, "yyyy-MM-dd", $null) } catch { continue }
            $daysSinceUpdate = ($dataAtual - $updatedDate).Days

            $hits = if ($pattern.hits) { [int]$pattern.hits } else { 0 }

            if ($daysSinceUpdate -ge 90 -and $hits -eq 0) {
                if ($DryRun) {
                    $changes += @{ Action = "DEMOTE_DRYRUN"; Target = $pattern.id; Reason = "No hits in $daysSinceUpdate days (≥90)" }
                    if (-not $Quiet) { Write-Host "  [DRY] Would demote: $($pattern.id) — no hits in $daysSinceUpdate days" }
                } else {
                    $pattern | Add-Member -NotePropertyName "status" -NotePropertyValue "deprecated" -Force
                    $pattern | Add-Member -NotePropertyName "deprecated_at" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
                    $pattern | ConvertTo-Json -Depth 6 | Set-Content $file.FullName -Encoding UTF8
                    $changes += @{ Action = "DEMOTED"; Target = $pattern.id; Reason = "No hits in $daysSinceUpdate days (≥90)" }
                    if (-not $Quiet) { Write-Host "  [→] Demoted: $($pattern.id) → deprecated" }
                }
            }
        }

        if ((-not $Quiet) -and ($runAll -or $DemoteOnly)) {
            $cnt = @($changes | Where-Object { $_.Action -eq "DEMOTED" -or $_.Action -eq "DEMOTE_DRYRUN" }).Length
            Write-Host "[$cnt] stale pattern(s) processed"
        }
    }
}

# ─── 2. Remove unused forged skills (14d no resolution) ───────
if ($runAll -or $RemoveOnly) {
    $forgeSkills = @(Get-ChildItem $skillsDir -Directory | Where-Object { $_.Name -like "cross-project-*" })
    $dataAtual = Get-Date

    foreach ($skillDir in $forgeSkills) {
        $skillFile = Join-Path $skillDir.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) { continue }

        $skillContent = Get-Content $skillFile -Raw

        # Check last modified time
        $lastWrite = $skillDir.LastWriteTime
        $daysSinceWrite = ($dataAtual - $lastWrite).Days

        # Check if skill-graph has resolved it at least once (heuristic: if
        # the SKILL.md has a `last_resolved` field or we check modified date)
        if ($daysSinceWrite -lt 14) { continue }

        # Try to extract source pattern
        $sourcePattern = ""
        if ($skillContent -match 'source_pattern:\s*"([^"]+)"') { $sourcePattern = $Matches[1] }

        if ($DryRun) {
            $reason = "Not resolved in $daysSinceWrite days (≥14)"
            $changes += @{ Action = "REMOVE_DRYRUN"; Target = $skillDir.Name; Reason = $reason; SourcePattern = $sourcePattern }
            if (-not $Quiet) { Write-Host "  [DRY] Would remove: $($skillDir.Name) — $reason" }
        } else {
            Remove-Item -Recurse -Force $skillDir.FullName
            $reason = "Not resolved in $daysSinceWrite days (≥14)"
            $changes += @{ Action = "REMOVED"; Target = $skillDir.Name; Reason = $reason; SourcePattern = $sourcePattern }

            # Also demote source pattern back to active
            if ($sourcePattern) {
                $foundFiles = @(Get-ChildItem $patternsDir -Filter "*.json" | Where-Object {
                    try { (Get-Content $_.FullName -Raw | ConvertFrom-Json).id -eq $sourcePattern } catch { $false }
                })
                if ($foundFiles.Length -gt 0) {
                    $srcPattern = Get-Content $foundFiles[0].FullName -Raw | ConvertFrom-Json
                    $srcPattern | Add-Member -NotePropertyName "status" -NotePropertyValue "active" -Force
                    $srcPattern | Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $null -Force
                    $srcPattern | Add-Member -NotePropertyName "updated" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
                    $srcPattern | ConvertTo-Json -Depth 6 | Set-Content $foundFiles[0].FullName -Encoding UTF8
                    $changes += @{ Action = "DEMOTED"; Target = $sourcePattern; Reason = "Rollback: forged skill removed (unused)" }
                }
            }

            if (-not $Quiet) { Write-Host "  [✗] Removed: $($skillDir.Name) (unused $daysSinceWrite days)" }
        }
    }

    if ((-not $Quiet) -and ($runAll -or $RemoveOnly)) {
        $cnt = @($changes | Where-Object { $_.Action -eq "REMOVED" -or $_.Action -eq "REMOVE_DRYRUN" }).Length
        Write-Host "[$cnt] unused forged skill(s) processed"
    }
}

# ─── 3. Archive deprecated patterns >180d ──────────────────────
if ($runAll -or $ArchiveOnly) {
    $patternFiles = @()
    if (Test-Path $patternsDir) { $patternFiles = @(Get-ChildItem $patternsDir -Filter "*.json") }
    $dataAtual = Get-Date

    if (-not (Test-Path $archivedDir)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $archivedDir -Force | Out-Null }
    }

    foreach ($file in $patternFiles) {
        try { $pattern = Get-Content $file.FullName -Raw | ConvertFrom-Json } catch { continue }
        $status = if ($pattern.status) { $pattern.status } else { "active" }
        if ($status -ne "deprecated") { continue }

        $depStr = if ($pattern.deprecated_at) { $pattern.deprecated_at } else { $pattern.updated }
        if (-not $depStr) { continue }

        $depDate = try { [DateTime]::ParseExact($depStr, "yyyy-MM-dd", $null) } catch { continue }
        $daysDeprecated = ($dataAtual - $depDate).Days

        if ($daysDeprecated -ge 180) {
            if ($DryRun) {
                $changes += @{ Action = "ARCHIVE_DRYRUN"; Target = $pattern.id; Reason = "Deprecated $daysDeprecated days (≥180)" }
                if (-not $Quiet) { Write-Host "  [DRY] Would archive: $($pattern.id) — deprecated $daysDeprecated days" }
            } else {
                $destPath = Join-Path $archivedDir $file.Name
                Move-Item -Path $file.FullName -Destination $destPath -Force
                $changes += @{ Action = "ARCHIVED"; Target = $pattern.id; Reason = "Deprecated $daysDeprecated days (≥180)" }
                if (-not $Quiet) { Write-Host "  [→] Archived: $($pattern.id) → archived/" }
            }
        }
    }

    if ((-not $Quiet) -and ($runAll -or $ArchiveOnly)) {
        $cnt = @($changes | Where-Object { $_.Action -eq "ARCHIVED" -or $_.Action -eq "ARCHIVE_DRYRUN" }).Length
        Write-Host "[$cnt] archived pattern(s) processed"
    }
}

# ─── Output ────────────────────────────────────────────────────
$result = [PSCustomObject]@{
    Status       = if ($changes.Length -gt 0) { "CHANGES" } else { "CLEAN" }
    TotalChanges = @($changes).Length
    Changes      = @($changes)
    Timestamp    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    DryRun       = $DryRun.IsPresent
}

if ($Quiet -or $changes.Length -gt 0) {
    $result | ConvertTo-Json -Depth 3
} elseif (-not $Quiet) {
    Write-Host "`n[OK] Store is clean — no stale patterns or unused skills"
}
