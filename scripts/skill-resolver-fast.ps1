#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Fast skill resolver - matches tasks to skills from pre-built registry JSON via keyword scoring.
.DESCRIPTION
    Loads skill-registry.json and scores each skill's description against the task string
    using token overlap (BFS keyword matching). Returns top-N results sorted by relevance.
    Much faster than skill-graph.ps1's full BFS resolution - use for CI/automation.
.PARAMETER Task
    Task description to match against skill descriptions. Required.
.PARAMETER Top
    Number of top matches to return. Default: 8.
.PARAMETER RegistryPath
    Path to skill-registry.json. Default: scripts/skill-registry.json
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Task,

    [int]$Top = 8,
    [string]$RegistryPath = "$PSScriptRoot\skill-registry.json"
,
    [switch]$Quiet,
    [switch]$Json)
# ponytail: -Quiet is a no-op here - output is already JSON-only data via Write-Output
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $RegistryPath)) {
    Write-Error "Registry not found: $RegistryPath - Run build-skill-registry.ps1 first"
    exit 1
}

$registry = Get-Content -Path $RegistryPath -Raw | ConvertFrom-Json
$taskLower = $Task.ToLower()
# Pre-build hashtable cache for O(1) lookup (was: PSObject.Properties iteration)
$triggerHT = @{}
foreach ($p in $registry.trigger_index.PSObject.Properties) { $triggerHT[$p.Name.ToLower()] = $p.Value }
$skillsHT = @{}
foreach ($p in $registry.skills.PSObject.Properties) { $skillsHT[$p.Name.ToLower()] = $p.Value }
# Token-split: foreach filter instead of Where-Object pipeline (avoids pipeline overhead)
$rawTokens = $taskLower -split '\s+|[-_/.,!?;:()]'
$taskTokens = [System.Collections.Generic.List[string]]::new($rawTokens.Count)
$seen = @{}
foreach ($t in $rawTokens) { if ($t.Length -gt 2 -and -not $seen.ContainsKey($t)) { $taskTokens.Add($t); $seen[$t] = $true } }

$scores = @{}
# Match triggers: hashtable lookup per token (was: PSObject.Properties loop per token)
foreach ($tk in $taskTokens) {
    foreach ($key in ($triggerHT.Keys | Sort-Object)) {
        if ($key -match [regex]::Escape($tk)) {
            foreach ($skillName in $triggerHT[$key]) {
                $sn = $skillName.ToLower()
                if (-not $scores.ContainsKey($sn)) { $scores[$sn] = 0 }
                $scores[$sn]++
            }
            break
        }
    }
}
# Match skill names: hashtable lookup per token (was: PSObject.Properties loop per token)
foreach ($tk in $taskTokens) {
    foreach ($key in ($skillsHT.Keys | Sort-Object)) {
        if ($key -match [regex]::Escape($tk)) {
            if (-not $scores.ContainsKey($key)) { $scores[$key] = 0 }
            $scores[$key] += 3; break
        }
    }
}
# Sort and return top N
$ranked = $scores.GetEnumerator() | Sort-Object { $_.Name } | Sort-Object { -$_.Value } | Select-Object -First $Top
if ($ranked.Count -eq 0) {
    Write-Output "[]"
    exit 0
}
$result = $ranked | ForEach-Object {
    [ordered]@{ name = $_.Name; score = $_.Value; path = $skillsHT[$_.Name.ToLower()].path; triggers = $skillsHT[$_.Name.ToLower()].triggers }
}
$result | ConvertTo-Json -Depth 4
