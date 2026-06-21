<#
.SYNOPSIS
  Verify backlog item status matches repo reality.

.DESCRIPTION
  Parses CYCLE.md backlog table and checks each item's status
  against verifiable repo state. Returns 0 = all match, 1 = mismatch.

.PARAMETER RepoRoot
  Root of the repo. Defaults to script parent dir.

.PARAMETER Json
  Output structured JSON for agent consumption.

.EXAMPLE
  .\scripts\check-backlog-integrity.ps1
  .\scripts\check-backlog-integrity.ps1 -Json
#>

param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$results = @{ checks = @(); passed = 0; failed = 0; errors = @() }

function Add-Check {
    param([string]$Item, [bool]$Passed, [string]$Detail)
    $script:results.checks += @{ item = $Item; passed = $Passed; detail = $Detail }
    if ($Passed) { $script:results.passed++ } else { $script:results.failed++ }
}

function Test-CommitExists {
    param([string]$CommitHash)
    Push-Location $RepoRoot
    try {
        $result = git cat-file -t $CommitHash 2>$null
        return ($result -eq 'commit')
    } finally {
        Pop-Location
    }
}

# Parse backlog table from CYCLE.md
$cyclePath = Join-Path $RepoRoot 'CYCLE.md'
if (-not (Test-Path $cyclePath)) { Write-Host 'CYCLE.md not found'; exit 1 }

$cycleContent = Get-Content $cyclePath -Raw -Encoding UTF8

# Extract table rows between "### Backlog" and the next "### "
$tableSection = $cycleContent -split '(?=### )' | Where-Object { $_ -match '### Backlog' } | Select-Object -First 1

if (-not $tableSection) { Write-Host 'Backlog table not found in CYCLE.md'; exit 1 }

# Parse pipe-delimited rows (skip header and separator lines)
$rows = $tableSection -split "`n" | Where-Object { $_ -match '^\|' -and $_ -notmatch '^\|[\s-]+\|' }
# Skip header row (contains "Item | Impact | Risk")
$rows = $rows | Where-Object { $_ -notmatch 'Item \| Impact \| Risk' }

$items = @()
foreach ($row in $rows) {
    $cols = $row -split '\|' | ForEach-Object { $_.Trim() }
    if ($cols.Count -ge 6) {
        $items += @{
            raw          = $row
            description  = $cols[1]
            impact       = $cols[2]
            risk         = $cols[3]
            ir           = $cols[4]
            estInter     = $cols[5]
            status       = $cols[6]
            doneCriteria = if ($cols.Count -ge 8) { $cols[7] } else { '' }
        }
    }
}

if ($items.Count -eq 0) { Write-Host 'No backlog items found'; exit 1 }

# --- Check each item ---
$allPassed = $true

foreach ($item in $items) {
    $desc = $item.description -replace '\s+', ' ' -replace '^\*{0,2}\s*', ''
    $status = $item.status -replace '\s+', ' '
    $criteria = $item.doneCriteria.Trim()

    if ($status -match 'Done') {
        # Item claims done â€” verify criteria
        if ($criteria -match 'commit\s+([a-f0-9]{7,})') {
            $commitHash = $Matches[1]
            if (Test-CommitExists $commitHash) {
                Add-Check -Item $desc -Passed $true -Detail "Done -- commit $commitHash found"
            } else {
                Add-Check -Item $desc -Passed $false -Detail "Done claimed but commit $commitHash not found"
                $allPassed = $false
            }
        } elseif ($criteria -match 'script exists at (.+?)(?:[|]|$)') {
            $scriptPath = $Matches[1].Trim()
            $fullPath = Join-Path $RepoRoot $scriptPath
            if (Test-Path $fullPath) {
                Add-Check -Item $desc -Passed $true -Detail "Done -- script exists at $scriptPath"
            } else {
                Add-Check -Item $desc -Passed $false -Detail "Done claimed but $scriptPath not found"
                $allPassed = $false
            }
        } else {
            Add-Check -Item $desc -Passed $true -Detail "Done (no auto-verifiable criteria)"
        }
    } elseif ($status -match 'Pending') {
        # Item claims pending â€” verify it's NOT accidentally done
        if ($criteria -match 'script exists at (.+?)(?:[|]|$)') {
            $scriptPath = $Matches[1].Trim()
            $fullPath = Join-Path $RepoRoot $scriptPath
            if (Test-Path $fullPath) {
                Add-Check -Item $desc -Passed $false -Detail "Pending but $scriptPath already exists"
                $allPassed = $false
            } else {
                Add-Check -Item $desc -Passed $true -Detail "Pending -- no premature implementation"
            }
        } else {
            Add-Check -Item $desc -Passed $true -Detail "Pending (no auto-verifiable criteria)"
        }
    } else {
        Add-Check -Item $desc -Passed $false -Detail "Unknown status: $status"
        $allPassed = $false
    }
}

# --- Summary ---
$score = if ($results.passed + $results.failed -gt 0) {
    [math]::Round(($results.passed / ($results.passed + $results.failed)) * 10, 1)
} else { 0 }

$results.score = $score
$results.totalItems = $items.Count
$results.allPassed = $allPassed

if ($Json) {
    $results.timestamp = (Get-Date -Format 'o')
    Write-Output ($results | ConvertTo-Json -Depth 3)
} else {
    Write-Host "`n=== Backlog Integrity ===" -ForegroundColor Cyan
    foreach ($check in $results.checks) {
        $color = if ($check.passed) { 'Green' } else { 'Red' }
        $symbol = if ($check.passed) { 'PASS' } else { 'FAIL' }
        Write-Host "[$symbol] $($check.item)" -NoNewline
        Write-Host " -- $($check.detail)" -ForegroundColor $color
    }
    Write-Host "`nScore: $score/10 ($($results.passed)/$($results.totalItems) items correct)" -ForegroundColor $(if ($allPassed) { 'Green' } else { 'Yellow' })
}

exit $(if ($allPassed) { 0 } else { 1 })

