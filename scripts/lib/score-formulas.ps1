#requires -Version 7

<#
.SYNOPSIS
    Pure scoring formulas extracted from score-dims.ps1 — no I/O, no caller scope.
.DESCRIPTION
    Behavior-preserving extraction of the 5 pure arithmetics (DC, Bi, Me, CA, Gate).
    Filesystem scans stay inline in score-dims.ps1; these functions take the
    SAME already-collected inputs and return the SAME scores prod computed.
    Dot-sourced by score-dims.ps1. Safe to dot-source standalone in tests.
#>

function Get-DcScore {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [int]$Orphans,
        [int]$DeadJunctions,
        [int]$Commented
    )
    $score = 10
    if ($Orphans -gt 5) {
        $score -= 2
    } elseif ($Orphans -gt 0) {
        $score -= 1
    }
    if ($DeadJunctions -gt 0) {
        $score -= 1
    }
    if ($Commented -gt 10) {
        $score -= 1
    }
    [math]::Max(0, [math]::Min(10, $score))
}

function Get-BiScore {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [bool]$Exists,
        [int]$Lines
    )
    if ($Lines -gt 10) {
        10
    } elseif ($Lines -gt 5) {
        7
    } elseif ($Exists) {
        5
    } else {
        0
    }
}

function Get-MeScore {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [bool]$Dir,
        [bool]$ErrDir,
        [bool]$ErrJson,
        [bool]$Reports
    )
    $score = 4
    if ($Dir -and $ErrJson) {
        $score = 9
    } elseif ($Dir) {
        $score = 7
    }
    if ($Reports -and $ErrDir) {
        $score = [math]::Min(10, $score + 1)
    }
    $score
}

function Get-CaScore {
    [CmdletBinding()]
    param(
        [int]$Count,
        [int]$Target
    )
    # NOTE: Target=0 throws System.Management.Automation.RuntimeException
    # ("Attempted to divide by zero") — this replicates prod exactly.
    # score-dims.ps1 wraps the call site in try/catch (missing/corrupt
    # inter-track.json -> 0), so the throw surfaces identically to prod.
    # DO NOT add a zero-guard here: that would change prod behavior.
    [math]::Min(10, [math]::Round(($Count / $Target) * 10, 1))
}

function Get-GatePassScore {
    [CmdletBinding()]
    param(
        $Passed,
        $Total
    )
    # BUGFIX: docs/metricas/errors/LATEST_error.json from quality-gate currently
    # omits `total` (source=quality-gate, passed=28, NO total). Under
    # Set-StrictMode -Version Latest (score-auto.ps1) the inline access
    # `$latError.total` THREW, so the try/catch in score-dims.ps1 forced
    # gatePassScore=0 instead of the intended fallback (passed>=5 -> 10),
    # costing ~10pts in one SD sub-dimension (~-0.24 avg in SD).
    # Null-safe: ratio branch ONLY when Total is present and > 0 (exact
    # original semantics); otherwise the intended passed>=5 -> 10 fallback.
    # Pure: no I/O, no caller scope.
    if ($null -ne $Total -and $Total -gt 0) {
        [math]::Round(([double]$Passed / [double]$Total) * 10, 1)
    } elseif ($Passed -ge 5) {
        10
    } else {
        0
    }
}
