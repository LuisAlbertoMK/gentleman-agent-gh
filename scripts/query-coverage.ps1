#requires -Version 5.1
<#
.SYNOPSIS
    Token-efficient helper to query coverage.xml (JaCoCo format, ~780KB / ~15K lines)
    WITHOUT loading the file into AI context.

    Token saving: Naive Read: 194K tokens vs Helper: ~150 tokens (99.9% saving)

.DESCRIPTION
    Parses coverage.xml once via [xml] and exposes three functions:
      Get-CoverageSummary    - one-line global summary
      Get-UncoveredFile      - top 10 worst-covered files
      Get-FileCoverage       - coverage detail for one file by name fragment

    Requires PowerShell 5.1+, no external dependencies. The XML is parsed with
    the in-memory [xml] object model; only a tiny derived result is written to
    stdout, keeping the AI context cost near zero.

.EXAMPLE
    .\query-coverage.ps1 summary
    .\query-coverage.ps1 uncovered
    .\query-coverage.ps1 file adversarial-review

.NOTES
    Coverage rates are computed from LINE counters (ranked line coverage).
    This Pester report emits no BRANCH data, so branch-rate is shown as N/A.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('summary', 'uncovered', 'file')]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$FileName,

    [Parameter()]
    [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'coverage.xml')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Shared loader: locate + parse coverage.xml once, cache for reuse.
# ---------------------------------------------------------------------------
function Get-CoverageXml {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path
    )
    if ([string]::IsNullOrEmpty($Path)) {
        throw "No coverage.xml path supplied."
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "coverage.xml not found at: $Path`nExpected it at the repo root next to the script, or pass -Path explicitly."
    }
    $resolved = (Resolve-Path -LiteralPath $Path).Path

    try {
        $xml = [xml](Get-Content -LiteralPath $resolved -Raw)
    }
    catch {
        throw "Failed to parse coverage.xml at '$resolved': $($_.Exception.Message)"
    }
    return $xml
}

# ---------------------------------------------------------------------------
# 1) Global summary.
# ---------------------------------------------------------------------------
function Get-CoverageSummary {
    <#
    .SYNOPSIS
        Prints a compact global coverage summary (5 lines max).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'coverage.xml')
    )
    $xml = Get-CoverageXml -Path $Path

    $packages = @($xml.SelectNodes('/report/package'))
    $classes  = @($xml.SelectNodes('//package/class'))
    $lines    = @($xml.SelectNodes('//package/class/counter[@type="LINE"]'))

    $coveredLines = 0
    $missedLines  = 0
    foreach ($c in $lines) {
        $coveredLines += [int]$c.covered
        $missedLines  += [int]$c.missed
    }
    $totalLines = $coveredLines + $missedLines
    $lineRate = if ($totalLines -gt 0) { '{0:P1}' -f ($coveredLines / $totalLines) } else { 'N/A' }

    $instr = @($xml.SelectNodes('//package/class/counter[@type="INSTRUCTION"]'))
    $covInstr = 0; $misInstr = 0
    foreach ($c in $instr) { $covInstr += [int]$c.covered; $misInstr += [int]$c.missed }

    "overall line-rate  : $lineRate  ($coveredLines/$totalLines lines covered)"
    "instruction-rate   : $('{0:P1}' -f ($covInstr / ($covInstr + $misInstr)))  ($covInstr/$($covInstr + $misInstr) instr)"
    "branch-rate        : N/A (no BRANCH counters in this report)"
    "packages           : $($packages.Count)  classes: $($classes.Count)"
    "lines              : $totalLines total ($missedLines missed, $coveredLines covered)"
}

# ---------------------------------------------------------------------------
# 2) Top 10 worst-covered files.
# ---------------------------------------------------------------------------
function Get-UncoveredFile {
    <#
    .SYNOPSIS
        Lists the 10 worst-covered files (class name + line-rate), worst first.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Top = 10,
        [Parameter(Mandatory = $false)]
        [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'coverage.xml')
    )
    $xml = Get-CoverageXml -Path $Path

    $rows = foreach ($cls in $xml.SelectNodes('//package/class')) {
        $lineCounter = @($cls.SelectNodes('counter[@type="LINE"]'))
        if ($lineCounter.Count -eq 0) { continue }
        $lc = $lineCounter[0]
        $cov = [int]$lc.covered
        $mis = [int]$lc.missed
        $tot = $cov + $mis
        $rate = if ($tot -gt 0) { [double]$cov / $tot } else { 0.0 }
        [pscustomobject]@{
            Name     = $cls.name
            LineRate = $rate
            Covered  = $cov
            Missed   = $mis
        }
    }

    $rows = $rows | Sort-Object -Property LineRate, { $_.Covered } | Select-Object -First $Top
    "rank  line-rate   covered/missed   file"
    $i = 0
    foreach ($r in $rows) {
        $i++
        $rateStr = if ($r.LineRate -eq 0) { '  0.0%' } else { ('{0,6:P1}' -f $r.LineRate) }
        '{0,3}  {1}  {2,5}/{3,-6} {4}' -f $i, $rateStr, $r.Covered, $r.Missed, $r.Name
    }
}
Set-Alias -Name Get-UncoveredFiles -Value Get-UncoveredFile

# ---------------------------------------------------------------------------
# 3) Coverage for one file by name fragment.
# ---------------------------------------------------------------------------
function Get-FileCoverage {
    <#
    .SYNOPSIS
        Shows coverage for a single file matched by a partial/partial name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,
        [Parameter(Mandatory = $false)]
        [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'coverage.xml')
    )
    $xml = Get-CoverageXml -Path $Path

    $match = $null
    foreach ($cls in $xml.SelectNodes('//package/class')) {
        if ($cls.name -and $cls.name.IndexOf($FileName, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $match = $cls
            break
        }
    }

    if (-not $match) {
        Write-Warning "No file matched fragment '$FileName'."
        return
    }

    $lineCounter = @($match.SelectNodes('counter[@type="LINE"]'))
    if ($lineCounter.Count -eq 0) {
        "File: $($match.name)"
        "No LINE counter available."
        return
    }
    $cov = [int]$lineCounter[0].covered
    $mis = [int]$lineCounter[0].missed
    $tot = $cov + $mis
    $rate = if ($tot -gt 0) { [double]$cov / $tot } else { 0.0 }

    "File : $($match.name)"
    "line-rate: $('{0:P1}' -f $rate)  ($cov covered / $mis missed)"

    # First 5 uncovered line numbers come from the per-line <line> entries.
    $lineNodes = @($match.SelectNodes('line'))
    if ($lineNodes.Count -eq 0) {
        "per-line detail: unavailable (this report emits no <line> entries)"
        return
    }
    $uncovered = @()
    foreach ($ln in $lineNodes) {
        if ($ln.mi -and [int]$ln.mi -gt 0) {
            $uncovered += [int]$ln.nr
        }
    }
    if ($uncovered.Count -gt 0) {
        $first5 = ($uncovered | Sort-Object -Unique | Select-Object -First 5) -join ', '
        "first uncovered lines: $first5  (total uncovered lines: $($uncovered.Count))"
    }
    else {
        "no uncovered lines."
    }
}

# ---------------------------------------------------------------------------
# CLI dispatch: .\query-coverage.ps1 summary | uncovered | file <name>
# ---------------------------------------------------------------------------
if ($MyInvocation.InvocationName -ne '.') {
    if ($Command) {
        switch ($Command) {
            'summary'   { Get-CoverageSummary -Path $Path }
            'uncovered' { Get-UncoveredFile -Path $Path }
            'file'      {
                if (-not $FileName) {
                    throw "Usage: .\query-coverage.ps1 file <partial-name>"
                }
                Get-FileCoverage -FileName $FileName -Path $Path
            }
            default { throw "Unknown command: $Command" }
        }
    }
    else {
        Get-CoverageSummary -Path $Path
    }
}
