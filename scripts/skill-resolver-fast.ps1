#requires -Version 7.6
# ponytail: skill registry — fast resolver
# Resolves skills by trigger matching from pre-built registry JSON
# Usage: .\skill-resolver-fast.ps1 -Task "optimize prompt tokens" [-Top 5]

param(
    [Parameter(Mandatory = $true)]
    [string]$Task,

    [int]$Top = 8,
    [string]$RegistryPath = "$PSScriptRoot\skill-registry.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $RegistryPath)) {
    Write-Error "Registry not found: $RegistryPath — Run build-skill-registry.ps1 first"
    exit 1
}

$registry = Get-Content -Path $RegistryPath -Raw | ConvertFrom-Json
$taskLower = $Task.ToLower()
$taskTokens = $taskLower -split "[\s,;:.!?]+" | Where-Object { $_.Length -gt 2 }

$scores = @{}

foreach ($trigger in $registry.trigger_index.PSObject.Properties) {
    $triggerKey = $trigger.Name.ToLower()
    $skillNames = $trigger.Value

    # Score: count token overlaps between task and trigger
    $triggerTokens = $triggerKey -split "[\s,;/]+" | Where-Object { $_.Length -gt 2 }
    $matchCount = 0
    foreach ($tt in $triggerTokens) {
        foreach ($tk in $taskTokens) {
            if ($tk -eq $tt -or $tk -like "*$tt*" -or $tt -like "*$tk*") {
                $matchCount++
                break
            }
        }
    }

    if ($matchCount -gt 0) {
        foreach ($skillName in $skillNames) {
            if (-not $scores.ContainsKey($skillName)) {
                $scores[$skillName] = 0
            }
            $scores[$skillName] += $matchCount
        }
    }
}

# Also check skill names directly
foreach ($skill in $registry.skills.PSObject.Properties) {
    $name = $skill.Name.ToLower()
    foreach ($tk in $taskTokens) {
        if ($name -like "*$tk*") {
            if (-not $scores.ContainsKey($skill.Name)) {
                $scores[$skill.Name] = 0
            }
            $scores[$skill.Name] += 3  # name match = high score
            break
        }
    }
}

# Sort by score, return top N
$ranked = $scores.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    Select-Object -First $Top

if ($ranked.Count -eq 0) {
    Write-Output "[]"
    exit 0
}

$result = $ranked | ForEach-Object {
    $skillData = $registry.skills.PSObject.Properties[$_.Name].Value
    [ordered]@{
        name     = $_.Name
        score    = $_.Value
        path     = $skillData.path
        triggers = $skillData.triggers
    }
}

$result | ConvertTo-Json -Depth 4

