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
    ADR: Dag is per-cycle (cycle id from inter-track.json if present).
    GC: Remove-LcmOldCycles prunes non-current cycles, fail-closed when cycle unknown.
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
            Write-Debug "what failed: $($_.Exception.Message)"
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

function Remove-LcmOldCycles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '', Justification = 'Bulk GC prunes ALL old cycles; plural is semantically correct (Ronda4 S1 plan-mandated name)')]
    param(
        [string]$Path = $DagPath,
        [string]$KeepCycle,
        [string]$InterTrackPath = (Join-Path $repoRoot '.learnings/inter-track.json')
    )
    # Retention watermark: current cycle id, best-effort (same pattern as Initialize-LcmDag).
    $currentCycle = $KeepCycle
    if (-not $currentCycle) {
        try { $currentCycle = (Get-Content $InterTrackPath -Raw | ConvertFrom-Json).cycle.id } catch {
            # inter-track.json optional — without it the current cycle is unknown, swallow is intentional
            Write-Debug "what failed: $($_.Exception.Message)"
        }
    }
    if (-not $currentCycle) {
        # FAIL-CLOSED: without a known current cycle, old is indistinguishable from
        # current → no-op. Read-only: never creates or modifies the DAG file here.
        Write-Verbose 'Remove-LcmOldCycles: current cycle unknown — no-op (fail-closed, nothing deleted)'
        $keptCount = 0
        if (Test-Path -LiteralPath $Path) { $keptCount = @((Get-Content $Path -Raw | ConvertFrom-Json).nodes).Count }
        return [PSCustomObject]@{ keepCycle = $null; kept = $keptCount; pruned = 0; prunedIds = @(); path = $Path; noOp = $true }
    }
    $dag = Get-LcmDag -Path $Path
    $keptIds = [System.Collections.Generic.HashSet[string]]::new()
    $kept = @()
    $prunedIds = @()
    foreach ($n in @($dag.nodes)) {
        # Fail-closed per node: prune ONLY when the node carries a cycle AND it differs
        # from current. Nodes without a cycle predate cycle tracking — kept, never
        # delete on suspicion.
        if ($n.cycle -and ($n.cycle -ne $currentCycle)) { $prunedIds += $n.id }
        else { $kept += $n; [void]$keptIds.Add([string]$n.id) }
    }
    $edges = @(@($dag.edges) | Where-Object { $keptIds.Contains([string]$_.from) -and $keptIds.Contains([string]$_.to) })
    $result = [PSCustomObject]@{
        keepCycle = $currentCycle; kept = $kept.Count; pruned = $prunedIds.Count
        prunedIds = $prunedIds; path = $Path; noOp = ($prunedIds.Count -eq 0)
    }
    if (($env:PESTER_TEST -eq '1') -or (-not $PSCmdlet.ShouldProcess($Path, ("prune {0} node(s) from older cycles (keep {1})" -f $prunedIds.Count, $currentCycle)))) {
        return $result
    }
    $dag.nodes = @($kept)
    $dag.edges = @($edges)
    if ($dag.meta) { $dag.meta.cycle = $currentCycle }
    $dag | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
    return $result
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

function New-LcmL1Content {
    <#
    .SYNOPSIS
        Builds L1 section-summary content (Ronda4 S2 migration).
    .DESCRIPTION
        L1 = section summary (~20% tokens, schema §1): one line per section.
        Pure function — no persistence, safe under PESTER_TEST=1.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pure string builder, no persistence or state change (Ronda4 S2 contract)')]
    param(
        [string[]]$Sections = @(),
        [string]$Prefix = 'L1 section summary'
    )
    $lines = @($Sections | Where-Object { $_ -and $_.Trim() })
    if ($lines.Count -eq 0) { $lines = @('(no sections captured)') }
    $body = ($lines | ForEach-Object { "- $($_.Trim())" }) -join "`n"
    return "$Prefix ($($lines.Count) sections):`n$body"
}

function New-LcmL2Content {
    <#
    .SYNOPSIS
        Builds L2 decisions + Engram IDs content (Ronda4 S2 migration).
    .DESCRIPTION
        L2 = decisions (1-2 lines each) + `Refs: <engram-id>, ...` (schema §1).
        Engram IDs are never fabricated: empty -EngramIds omits the Refs line.
        Pure function — no persistence, safe under PESTER_TEST=1.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pure string builder, no persistence or state change (Ronda4 S2 contract)')]
    param(
        [string[]]$Decisions = @(),
        [string[]]$EngramIds = @()
    )
    $ds = @($Decisions | Where-Object { $_ -and $_.Trim() })
    if ($ds.Count -eq 0) { $ds = @('(no decisions captured)') }
    $out = "Decisions ($($ds.Count)):`n" + (($ds | ForEach-Object { "- $($_.Trim())" }) -join "`n")
    $ids = @($EngramIds | Where-Object { $_ -and $_.Trim() })
    if ($ids.Count -gt 0) { $out += "`nRefs: " + ($ids -join ', ') }
    return $out
}

function Get-LcmSha256Hex {
    <#
    .SYNOPSIS
        sha256 (lowercase hex) over a byte array — canonical hash for pointers.
    #>
    [CmdletBinding()]
    param([byte[]]$Bytes = @())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes)) -replace '-', '').ToLower() }
    finally { $sha.Dispose() }
}

function Get-LcmPointerBytes {
    <#
    .SYNOPSIS
        Resolves a pointer ref to its canonical bytes (shared by builder + resolver).
    .DESCRIPTION
        file:   bytes of the file (repo-relative resolved against -RepoRoot, or absolute).
        engram: UTF8 bytes of the observation text (-Content, fetched via
                mem_get_observation by the caller — the MCP transport stays with
                the agent; this function proves the hash, it does not fetch).
        diff:   UTF8 bytes of `git diff --no-color <range>` (LF-joined — the
                normalization is part of the canonical form for diff kind).
        Returns @{ ok = bool; bytes = byte[]; note = string } — never throws on
        unresolvable refs (fail-closed via ok=$false); malformed input throws.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '', Justification = 'Returns canonical byte[] payload; plural is semantically correct (same rationale as Remove-LcmOldCycles)')]
    param(
        [ValidateSet('file','engram','diff')][string]$Kind,
        [string]$Ref,
        [string]$Content,
        [string]$GitDir,
        [string]$RepoRoot
    )
    if (-not $Ref) { throw 'Get-LcmPointerBytes: -Ref required' }
    switch ($Kind) {
        'file' {
            $p = $Ref
            if (-not [System.IO.Path]::IsPathRooted($p)) { $p = Join-Path $RepoRoot $p }
            if (-not (Test-Path -LiteralPath $p)) {
                return @{ ok = $false; bytes = @(); note = "file ref not found: $Ref" }
            }
            return @{ ok = $true; bytes = [System.IO.File]::ReadAllBytes($p); note = '' }
        }
        'engram' {
            if (-not $Content) {
                return @{ ok = $false; bytes = @(); note = 'engram kind needs -Content (observation text via mem_get_observation)' }
            }
            return @{ ok = $true; bytes = [System.Text.Encoding]::UTF8.GetBytes($Content); note = '' }
        }
        'diff' {
            try { $raw = & git -C $GitDir diff --no-color $Ref 2>&1 } catch {
                return @{ ok = $false; bytes = @(); note = "git diff failed: $($_.Exception.Message)" }
            }
            if ($LASTEXITCODE -ne 0) {
                return @{ ok = $false; bytes = @(); note = "git diff exited $LASTEXITCODE for range: $Ref" }
            }
            $text = ($raw -join "`n")
            return @{ ok = $true; bytes = [System.Text.Encoding]::UTF8.GetBytes($text); note = '' }
        }
    }
}

function New-LcmL3Pointer {
    <#
    .SYNOPSIS
        Builds a canonical hash-verified L3 pointer `kind:ref#sha256:<hex64>` (Ronda4 S2).
    .DESCRIPTION
        Implements schema §2 canonical form for all 3 kinds. Throws fail-closed
        when the ref cannot be resolved — a pointer that cannot be proven at
        build time must never enter the DAG (schema: unverified != lossless).
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Pure pointer builder, read-only resolution plus hash; never writes state (Ronda4 S2 contract)')]
    param(
        [ValidateSet('file','engram','diff')][string]$Kind,
        [string]$Ref,
        [string]$Content,
        [string]$GitDir = $repoRoot,
        [string]$RepoRoot = $repoRoot
    )
    $r = Get-LcmPointerBytes -Kind $Kind -Ref $Ref -Content $Content -GitDir $GitDir -RepoRoot $RepoRoot
    if (-not $r.ok) { throw "New-LcmL3Pointer: cannot prove pointer ($Kind`:$Ref) — $($r.note)" }
    $hash = Get-LcmSha256Hex -Bytes $r.bytes
    return "$Kind`:$Ref#sha256:$hash"
}

function Resolve-LcmPointer {
    <#
    .SYNOPSIS
        Resolves + hash-verifies a lossless pointer for all 3 schema kinds (Ronda4 S2).
    .DESCRIPTION
        Resolver contract (schema §2, all kinds):
          1. Parse `^(file|engram|diff):<ref>[#sha256:<hex64>]`.
          2. Resolve ref to canonical bytes (see Get-LcmPointerBytes).
          3. Hash match → lossless proven (verified=$true); mismatch/missing →
             corrupt, re-capture. Bare pointer (no hash) → resolvable but
             unverified (verified=$false), per schema §2.
        Returns PSCustomObject @{ kind; ref; expectedHash; actualHash;
        verified; resolvable; note }. Throws only on malformed pointer syntax.
    #>
    [CmdletBinding()]
    param(
        [string]$Pointer,
        [string]$Content,
        [string]$GitDir = $repoRoot,
        [string]$RepoRoot = $repoRoot
    )
    $m = [regex]::Match($Pointer, '^(?<kind>file|engram|diff):(?<ref>.+?)(?:#sha256:(?<hash>[0-9a-f]{64}))?$')
    if (-not $m.Success) { throw "Resolve-LcmPointer: malformed pointer: $Pointer" }
    $kind = $m.Groups['kind'].Value
    $ref = $m.Groups['ref'].Value
    $expected = $m.Groups['hash'].Value
    $r = Get-LcmPointerBytes -Kind $kind -Ref $ref -Content $Content -GitDir $GitDir -RepoRoot $RepoRoot
    if (-not $r.ok) {
        return [PSCustomObject]@{
            kind = $kind; ref = $ref; expectedHash = $expected; actualHash = ''
            verified = $false; resolvable = $false; note = $r.note
        }
    }
    $actual = Get-LcmSha256Hex -Bytes $r.bytes
    $verified = ($expected -ne '' -and ($actual -eq $expected))
    return [PSCustomObject]@{
        kind = $kind; ref = $ref; expectedHash = $expected; actualHash = $actual
        verified = [bool]$verified; resolvable = $true; note = ''
    }
}

# CLI dispatch
if ($Init) { Initialize-LcmDag -Path $DagPath | Out-Null; Write-Host "DAG init: $DagPath" }
elseif ($Add) { $n = Add-LcmNode -Level $Level -Content $Content -Pointer $Pointer -Tokens $Tokens; $n | ConvertTo-Json -Depth 4 }
elseif ($Get) { $n = Get-LcmNode -Id $Id; if ($n) { $n | ConvertTo-Json -Depth 4 } else { Write-Warning "node $Id not found" } }
elseif ($Escalate) { Invoke-LcmEscalation -CurrentTokens $CurrentTokens -Budget $Budget }
