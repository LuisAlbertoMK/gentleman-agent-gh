#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='Demote')]
<#
.SYNOPSIS
    Wisdom Maintenance — pattern store cleanup and metrics.
.DESCRIPTION
    Consolidated maintenance operations for cross-project Pattern Store.
    Replaces: wisdom-demote.ps1, wisdom-stats.ps1

    SUBCOMMANDS:
    - Demote:   Demote stale patterns, remove unused forged skills, archive deprecated
    - Stats:    Wisdom store metrics: pattern count, severity distribution, hit rates

.PARAMETER Command
    Subcommand: Demote, Stats (default: Demote).

# Demote parameters
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
.PARAMETER Force
    Override safety guards (e.g. remove forged skill referenced by active pattern).
.PARAMETER Quiet
    Output JSON only.

# Stats parameters
.PARAMETER Json
    Output JSON (default: true for agent consumption).
.PARAMETER Trend
    Compare with previous stats snapshot (if available).

.EXAMPLE
    .\scripts\wisdom-maintenance.ps1 -Command Demote -All
    .\scripts\wisdom-maintenance.ps1 -Command Demote -DemoteOnly -DryRun
    .\scripts\wisdom-maintenance.ps1 -Command Stats
    .\scripts\wisdom-maintenance.ps1 -Command Stats -Trend
#>
param(
    [Parameter(ParameterSetName='Demote', Position=0)]
    [Parameter(ParameterSetName='Stats', Position=0)]
    [ValidateSet('Demote','Stats')]
    [string]$Command = 'Demote',

    # Demote params
    [switch]$All,
    [switch]$DemoteOnly,
    [switch]$RemoveOnly,
    [switch]$ArchiveOnly,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Quiet,

    # Stats params
    [bool]$Json = $true,
    [switch]$Trend
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$patternsDir = Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "patterns"
$skillsDir = Join-Path (Join-Path $repoRoot ".agents") "skills"
$archivedDir = Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "archived"

# ============================================================
# SHARED HELPER
# ============================================================
function Get-PatternIndex {
    $index = @{}
    if (Test-Path $patternsDir) {
        foreach ($pf in @(Get-ChildItem $patternsDir -Filter "*.json")) {
            try { $pp = Get-Content $pf.FullName -Raw | ConvertFrom-Json; if ($pp.id) { $index[$pp.id] = $pf.FullName } } catch { Write-Debug "wisdom-maintenance: $($_.Exception.Message)" }
        }
    }
    return $index
}
$patternIndex = Get-PatternIndex

# ============================================================
# DEMOTE COMMAND
# ============================================================
if ($Command -eq 'Demote') {
    $runAll = $All -or (-not $DemoteOnly -and -not $RemoveOnly -and -not $ArchiveOnly)
    $changes = @()

    # 1. Demote stale patterns (90d no hits)
    if ($runAll -or $DemoteOnly) {
        if (-not (Test-Path $patternsDir)) { if (-not $Quiet) { Write-Host "[SKIP] No patterns directory" } }
        else {
            $now = Get-Date
            foreach ($file in @(Get-ChildItem $patternsDir -Filter "*.json")) {
                try { $p = Get-Content $file.FullName -Raw | ConvertFrom-Json } catch { continue }
                $status = if ($p.status) { $p.status } else { "active" }
                if ($status -ne "active") { continue }
                $updatedStr = if ($p.updated) { $p.updated } else { $p.created }
                if (-not $updatedStr) { continue }
                $updatedDate = try { [DateTime]::ParseExact($updatedStr, "yyyy-MM-dd", $null) } catch { continue }
                $days = ($now - $updatedDate).Days
                $hits = if ($p.hits) { [int]$p.hits } else { 0 }
                if ($days -ge 90 -and $hits -eq 0) {
                    if ($DryRun) { $changes += @{Action="DEMOTE_DRYRUN";Target=$p.id;Reason="No hits in $days days (>=90)"}; if (-not $Quiet) { Write-Host "  [DRY] Would demote: $($p.id)" } }
                    else { $p|Add-Member -NotePropertyName "status" -NotePropertyValue "deprecated" -Force; $p|Add-Member -NotePropertyName "deprecated_at" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force; $p|ConvertTo-Json -Depth 6|Set-Content $file.FullName -Encoding UTF8; $changes += @{Action="DEMOTED";Target=$p.id;Reason="No hits in $days days (>=90)"}; if (-not $Quiet) { Write-Host "  [->] Demoted: $($p.id) -> deprecated" } }
                }
            }
            if (-not $Quiet) { $cnt = @($changes|Where-Object{$_.Action-like"DEMOT*"}).Length; Write-Host "[$cnt] stale pattern(s) processed" }
        }
    }

    # 2. Remove unused forged skills (14d no resolution)
    if ($runAll -or $RemoveOnly) {
        $now = Get-Date
        foreach ($skillDir in @(Get-ChildItem $skillsDir -Directory|Where-Object{$_.Name-like"cross-project-*"})) {
            $skillFile = Join-Path $skillDir.FullName "SKILL.md"
            if (-not (Test-Path $skillFile)) { continue }
            $days = ($now - $skillDir.LastWriteTime).Days
            if ($days -lt 14) { continue }
            $src = ""; $sc = Get-Content $skillFile -Raw
            if ($sc -match 'source_pattern:\s*"([^"]+)"') { $src = $Matches[1] }
            if ($DryRun) { $changes += @{Action="REMOVE_DRYRUN";Target=$skillDir.Name;Reason="Not resolved in $days days (>=14)";SourcePattern=$src}; if (-not $Quiet) { Write-Host "  [DRY] Would remove: $($skillDir.Name)" } }
            else {
                if ($src -and $patternIndex.ContainsKey($src)) {
                    $sp = Get-Content $patternIndex[$src] -Raw | ConvertFrom-Json
                    if ($sp.status -eq 'active' -and -not $Force) {
                        $changes += @{Action="REMOVE_SKIPPED";Target=$skillDir.Name;Reason="Pattern active ($src) references this skill; use -Force to override"}
                        if (-not $Quiet) { Write-Host "  [SKIP] $($skillDir.Name): active pattern $src references it (use -Force)" }
                        continue
                    }
                }
                Remove-Item -Recurse -Force $skillDir.FullName
                $changes += @{Action="REMOVED";Target=$skillDir.Name;Reason="Not resolved in $days days (>=14)";SourcePattern=$src}
                if ($src -and $patternIndex.ContainsKey($src)) {
                    $sp = Get-Content $patternIndex[$src] -Raw | ConvertFrom-Json
                    $sp | Add-Member -NotePropertyName "status" -NotePropertyValue "active" -Force
                    $sp | Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $null -Force
                    $sp | Add-Member -NotePropertyName "updated" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
                    $sp | ConvertTo-Json -Depth 6 | Set-Content $patternIndex[$src] -Encoding UTF8
                    $changes += @{Action="DEMOTED";Target=$src;Reason="Rollback: forged skill removed (unused)"}
                }
                if (-not $Quiet) { Write-Host "  [X] Removed: $($skillDir.Name) (unused $days days)" }
            }
        }
        if (-not $Quiet) { $cnt = @($changes|Where-Object{$_.Action-like"REMOVE*"}).Length; Write-Host "[$cnt] unused forged skill(s) processed" }
    }

    # 3. Archive deprecated patterns >180d
    if ($runAll -or $ArchiveOnly) {
        $now = Get-Date
        if (-not (Test-Path $archivedDir) -and -not $DryRun) { New-Item -ItemType Directory -Path $archivedDir -Force | Out-Null }
        $pFiles = if (Test-Path $patternsDir) { @(Get-ChildItem $patternsDir -Filter "*.json") } else { @() }
        foreach ($file in $pFiles) {
            try { $p = Get-Content $file.FullName -Raw | ConvertFrom-Json } catch { continue }
            $status = if ($p.status) { $p.status } else { "active" }
            if ($status -ne "deprecated") { continue }
            $depStr = if ($p.deprecated_at) { $p.deprecated_at } else { $p.updated }
            if (-not $depStr) { continue }
            $depDate = try { [DateTime]::ParseExact($depStr, "yyyy-MM-dd", $null) } catch { continue }
            $days = ($now - $depDate).Days
            if ($days -ge 180) {
                if ($DryRun) { $changes += @{Action="ARCHIVE_DRYRUN";Target=$p.id;Reason="Deprecated $days days (>=180)"}; if (-not $Quiet) { Write-Host "  [DRY] Would archive: $($p.id)" } }
                else { Move-Item -Path $file.FullName -Destination (Join-Path $archivedDir $file.Name) -Force; $changes += @{Action="ARCHIVED";Target=$p.id;Reason="Deprecated $days days (>=180)"}; if (-not $Quiet) { Write-Host "  [->] Archived: $($p.id) -> archived/" } }
            }
        }
        if (-not $Quiet) { $cnt = @($changes|Where-Object{$_.Action-like"ARCHIVE*"}).Length; Write-Host "[$cnt] archived pattern(s) processed" }
    }

    # Output
    $result = [PSCustomObject]@{Status=if($changes.Length-gt 0){"CHANGES"}else{"CLEAN"};TotalChanges=@($changes).Length;Changes=@($changes);Timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ");DryRun=$DryRun.IsPresent}
    if ($Quiet -or $changes.Length -gt 0) { $result | ConvertTo-Json -Depth 3 }
    elseif (-not $Quiet) { Write-Host "`n[OK] Store is clean -- no stale patterns or unused skills" }
    exit 0
}

# ============================================================
# STATS COMMAND
# ============================================================
if ($Command -eq 'Stats') {
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

    if (-not (Test-Path $patternsDir)) {
        $result = [PSCustomObject]@{ Timestamp = $timestamp; Status = "NO_STORE" }
        if ($Json) { return $result | ConvertTo-Json }
        Write-Host "Pattern store not found at $patternsDir"
        exit 0
    }

    $patternFiles = Get-ChildItem $patternsDir -Filter "*.json"
    if ($patternFiles.Count -eq 0) {
        $result = [PSCustomObject]@{ Timestamp = $timestamp; Status = "EMPTY"; Total = 0 }
        if ($Json) { return $result | ConvertTo-Json }
        Write-Host "[OK] No patterns in store"
        exit 0
    }

    $patterns = @()
    $errors = @()
    foreach ($file in $patternFiles) {
        try { $p = Get-Content $file.FullName -Raw | ConvertFrom-Json; $patterns += $p } catch { $errors += $file.Name }
    }

    $sevDist = @{}
    foreach ($p in $patterns) { $s = if ($p.severity) { $p.severity.ToUpper() } else { "UNKNOWN" }; if ($sevDist.ContainsKey($s)) { $sevDist[$s]++ } else { $sevDist[$s] = 1 } }

    $domainDist = @{}
    foreach ($p in $patterns) { $d = if ($p.domain) { $p.domain } else { "unknown" }; if ($domainDist.ContainsKey($d)) { $domainDist[$d]++ } else { $domainDist[$d] = 1 } }

    $statusDist = @{}
    foreach ($p in $patterns) { $s = if ($p.status) { $p.status } else { "unknown" }; if ($statusDist.ContainsKey($s)) { $statusDist[$s]++ } else { $statusDist[$s] = 1 } }

    $confidences = $patterns | Where-Object { $_.confidence -ne $null } | ForEach-Object { [double]$_.confidence }
    $avgConfidence = if ($confidences.Count -gt 0) { [Math]::Round(($confidences | Measure-Object -Average).Average, 3) } else { 0 }

    $hits = $patterns | Where-Object { $_.hits -ne $null } | ForEach-Object { [int]$_.hits }
    $totalHits = if ($hits.Count -gt 0) { ($hits | Measure-Object -Sum).Sum } else { 0 }

    $now = Get-Date
    $ages = @()
    foreach ($p in $patterns) {
        if ($p.created) {
            try { $created = [DateTime]::ParseExact($p.created, "yyyy-MM-dd", $null); $ages += ($now - $created).Days } catch { Write-Debug "wisdom-maintenance: Could not parse date '$($p.created)' for pattern" }
        }
    }
    $avgAgeDays = if ($ages.Count -gt 0) { [Math]::Round(($ages | Measure-Object -Average).Average, 0) } else { 0 }

    $result = [PSCustomObject]@{
        Timestamp = $timestamp; Status = "OK"; Total = $patterns.Count; Errors = $errors.Count; ErrorFiles = $errors
        SeverityDistribution = $sevDist; DomainDistribution = $domainDist; StatusDistribution = $statusDist
        AvgConfidence = $avgConfidence; TotalHits = $totalHits; AvgAgeDays = $avgAgeDays
        RecentlyUpdated = @($patterns | Where-Object { $_.updated -and (([DateTime]::Now - [DateTime]::ParseExact($_.updated, "yyyy-MM-dd", $null)).Days -le 7) }).Count
    }

    if ($Trend) {
        $snapDir = Join-Path (Join-Path $repoRoot "docs\metricas") "snapshots"
        $snapFile = Join-Path $snapDir "LATEST_wisdom_stats.json"
        $prev = $null
        if (Test-Path $snapFile) { try { $prev = Get-Content $snapFile -Raw | ConvertFrom-Json } catch { $prev = $null } }
        if ($prev -and $prev.Status -eq "OK") {
            $result | Add-Member -NotePropertyName Previous -NotePropertyValue $prev
            $result | Add-Member -NotePropertyName TotalDelta -NotePropertyValue ($result.Total - $prev.Total)
            $result | Add-Member -NotePropertyName HitsDelta -NotePropertyValue ($result.TotalHits - $prev.TotalHits)
        } else { $result | Add-Member -NotePropertyName Previous -NotePropertyValue $null }
        if (-not (Test-Path $snapDir)) { New-Item -ItemType Directory -Path $snapDir -Force | Out-Null }
        $result | ConvertTo-Json -Depth 4 | Set-Content -Path $snapFile -Encoding utf8
    }

    if ($Json) { $result | ConvertTo-Json -Depth 4 }
    else {
        Write-Host "=== Wisdom Store Stats ==="
        Write-Host "Total patterns: $($patterns.Count)"
        Write-Host "Severity: " -NoNewline; foreach ($kv in $sevDist.GetEnumerator() | Sort-Object Name) { Write-Host "$($kv.Key)=$($kv.Value) " -NoNewline }; Write-Host ""
        Write-Host "Domains: " -NoNewline; foreach ($kv in $domainDist.GetEnumerator() | Sort-Object Name) { Write-Host "$($kv.Key)=$($kv.Value) " -NoNewline }; Write-Host ""
        Write-Host "Avg confidence: $avgConfidence"; Write-Host "Total hits: $totalHits"; Write-Host "Avg age: $avgAgeDays days"
        Write-Host "Recently updated: $($result.RecentlyUpdated)"; Write-Host "Errors: $($errors.Count)"
        if ($errors.Count -gt 0) { Write-Host "  Failed files: $($errors -join ', ')" }
    }
    exit 0
}