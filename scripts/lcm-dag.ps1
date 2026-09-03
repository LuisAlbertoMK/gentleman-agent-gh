#requires -Version 7
<#
.SYNOPSIS
    LCM hierarchical summary DAG for context-watchdog — P0-1 parte 2/3.
.DESCRIPTION
    Builds a DAG of compressed context nodes (L1 summary ~20% tokens, L2 section,
    L3 lossless pointer) persisted to .learnings/lcm-dag.json.

    Implements paper §2.1 Hierarchical DAG + Fig.3 escalation (60%→L2, 80%→L3).
    Wire target: context-watchdog SKILL.md ORANGE 60% → YELLOW/RED zones.

    Storage: .learnings/lcm-dag.json  { nodes:[{id,level,parent,pointer,tokens,createdAt,cycle}], edges:[] }
    CLI:  pwsh -File scripts/lcm-dag.ps1 -Add -Level L1 -Content "summary..." -Pointer ".agents/skills/context-watchdog/SKILL.md"
          pwsh -File scripts/lcm-dag.ps1 -Get -Id <id>
          pwsh -File scripts/lcm-dag.ps1 -Escalate -CurrentTokens 145000 -Budget 200000
          dot-source:  . ./scripts/lcm-dag.ps1; Initialize-LcmDag; Add-LcmNode -Level L2 ...

    PESTER_TEST=1 skips persistence (in-memory only).
.NOTES
    ADR: Dag is per-cycle (cycle id from inter-track.json if present). GC not yet.
    Part 3 will wire to context-watchdog.ps1 auto-escalation.
#>
[CmdletBinding(DefaultParameterSetName = 'Add')]
param(
    [Parameter(ParameterSetName = 'Add')][switch]$Add,
    [Parameter(ParameterSetName = 'Get')][switch]$Get,
    [Parameter(ParameterSetName = 'Escalate')][switch]$Escalate,
    [Parameter(ParameterSetName = 'Init')][switch]$Init,
    [ValidateSet('L1','L2','L3')][string]$Level = 'L1',
    [string]$Content,
    [string]$Pointer,
    [string]$Id,
    [int]$CurrentTokens,
    [int]$Budget = 200000,
    [int]$Tokens = 0,
    [string]$DagPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$defaultDagPath = Join-Path $repoRoot '.learnings/lcm-dag.json'
if (-not $DagPath) { $DagPath = $defaultDagPath }

function Initialize-LcmDag {
    [CmdletBinding()]
    param([string]$Path = $DagPath)
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (-not (Test-Path $Path)) {
        $cycleId = $null
        try { $cycleId = (Get-Content (Join-Path $repoRoot '.learnings/inter-track.json') -Raw | ConvertFrom-Json).cycle.id } catch {
            # inter-track.json optional — cycle id may be absent in early runs, swallow is intentional
            Write-Verbose "lcm-dag: cycle id load ignored intentionally: $_"
        }
        $init = @{ nodes = @(); edges = @(); meta = @{ createdAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'); cycle = $cycleId; budget = $Budget } }
        if ($env:PESTER_TEST -ne '1') {
            $init | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8
        }
    }
    return $Path
}

function Get-LcmDag {
    [CmdletBinding()]
    param([string]$Path = $DagPath)
    Initialize-LcmDag -Path $Path | Out-Null
    if (-not (Test-Path $Path)) { return @{ nodes = @(); edges = @(); meta = @{} } }
    return Get-Content $Path -Raw | ConvertFrom-Json
}

function Add-LcmNode {
    [CmdletBinding()]
    param(
        [ValidateSet('L1','L2','L3')][string]$Level,
        [string]$Content,
        [string]$Pointer,
        [int]$Tokens = 0,
        [string]$ParentId,
        [string]$Path = $DagPath
    )
    if (-not $Content) { throw "Add-LcmNode: -Content required for $Level" }
    $dag = Get-LcmDag -Path $Path
    $nodes = @($dag.nodes)
    $count = $nodes.Count
    $id = "lcm-{0}-{1:D4}" -f $Level.ToLower(), ($count + 1)
    if (-not $Tokens) { $Tokens = [math]::Ceiling($Content.Length / 4) } # ~4 chars/token
    if ($Level -eq 'L3' -and -not $Pointer) { Write-Warning "L3 without Pointer is not lossless — add -Pointer <file-or-diff>" }
    $cycleId = $null
    if ($dag.meta -and $dag.meta.PSObject.Properties.Name -contains 'cycle') { $cycleId = $dag.meta.cycle }
    $node = [ordered]@{
        id        = $id
        level     = $Level
        parent    = $ParentId
        content   = $Content.Substring(0, [math]::Min(500, $Content.Length))
        pointer   = $Pointer
        tokens    = $Tokens
        createdAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        cycle     = $cycleId
    }
    $dag.nodes = @($nodes + $node)
    if ($ParentId) { $dag.edges = @($dag.edges + @{ from = $ParentId; to = $id }) }
    if ($env:PESTER_TEST -ne '1') {
        $dag | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
    }
    return $node
}

function Get-LcmNode {
    [CmdletBinding()]
    param([string]$Id, [string]$Path = $DagPath)
    $dag = Get-LcmDag -Path $Path
    return @($dag.nodes) | Where-Object { $_.id -eq $Id } | Select-Object -First 1
}

function Invoke-LcmEscalation {
    [CmdletBinding()]
    param([int]$CurrentTokens, [int]$Budget = 200000)
    $pct = if ($Budget -gt 0) { $CurrentTokens / $Budget } else { 0 }
    if ($pct -ge 0.80) { return 'L3' }
    if ($pct -ge 0.60) { return 'L2' }
    if ($pct -ge 0.40) { return 'L1' }
    return 'NONE'
}

# CLI dispatch
if ($Init) { Initialize-LcmDag -Path $DagPath | Out-Null; Write-Host "DAG init: $DagPath" }
elseif ($Add) { $n = Add-LcmNode -Level $Level -Content $Content -Pointer $Pointer -Tokens $Tokens; $n | ConvertTo-Json -Depth 4 }
elseif ($Get) { $n = Get-LcmNode -Id $Id; if ($n) { $n | ConvertTo-Json -Depth 4 } else { Write-Warning "node $Id not found" } }
elseif ($Escalate) { Invoke-LcmEscalation -CurrentTokens $CurrentTokens -Budget $Budget }
