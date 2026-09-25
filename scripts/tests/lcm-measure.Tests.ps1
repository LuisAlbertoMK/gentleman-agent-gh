#requires -Version 5.1
# Pester tests for scripts/measure-lcm-compression.ps1 - Ronda4 S3 (G-d readout + thresholds)
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'measure-lcm-compression.ps1' {
    BeforeAll {
        $script:MeasurePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'measure-lcm-compression.ps1'
        $script:TmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-measure-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
        $null = New-Item -ItemType Directory -Path $script:TmpRoot -Force
        # Pointer fixtures with exact byte sizes (pre-tokens = bytes/4, same estimator as Add-LcmNode)
        Set-Content -LiteralPath (Join-Path $script:TmpRoot 'small.txt') -Value ('x' * 400) -NoNewline -Encoding UTF8   # 400B → pre 100
        Set-Content -LiteralPath (Join-Path $script:TmpRoot 'medium.txt') -Value ('y' * 800) -NoNewline -Encoding UTF8  # 800B → pre 200
        Set-Content -LiteralPath (Join-Path $script:TmpRoot 'large.txt') -Value ('z' * 4000) -NoNewline -Encoding UTF8  # 4000B → pre 1000
        Set-Content -LiteralPath (Join-Path $script:TmpRoot 'tiny.txt') -Value ('w' * 100) -NoNewline -Encoding UTF8    # 100B → pre 25

        function New-Node($Id, $Level, $Tokens, $Pointer) {
            $n = [ordered]@{ id = $Id; level = $Level; parent = $null; content = "content for $Id"; tokens = $Tokens; createdAt = '2026-09-23T00:00:00'; cycle = $null }
            if ($Pointer) { $n.pointer = $Pointer } else { $n.pointer = $null }
            return $n
        }
        $passDag = @{ nodes = @(
                (New-Node 'lcm-l1-0001' 'L1' 20 'file:small.txt'),
                (New-Node 'lcm-l1-0002' 'L1' 15 $null),
                (New-Node 'lcm-l2-0001' 'L2' 100 'file:medium.txt'),
                (New-Node 'lcm-l3-0001' 'L3' 10 'file:large.txt')
            ); edges = @(); meta = @{} }
        $script:PassDagPath = Join-Path $script:TmpRoot 'dag-pass.json'
        $passDag | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:PassDagPath -Encoding UTF8

        $warnDag = @{ nodes = @((New-Node 'lcm-l1-0009' 'L1' 500 'file:tiny.txt')); edges = @(); meta = @{} }
        $script:WarnDagPath = Join-Path $script:TmpRoot 'dag-warn.json'
        $warnDag | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:WarnDagPath -Encoding UTF8

        $script:EmptyDagPath = Join-Path $script:TmpRoot 'dag-empty.json'
        @{ nodes = @(); edges = @(); meta = @{} } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:EmptyDagPath -Encoding UTF8

        function Invoke-Measure($DagPath, $Tokens = -1) {
            return & $script:MeasurePath -DagPath $DagPath -RepoRoot $script:TmpRoot -CurrentTokens $Tokens -Json | ConvertFrom-Json -ErrorAction Stop
        }
    }
    AfterAll { if (Test-Path $script:TmpRoot) { Remove-Item -LiteralPath $script:TmpRoot -Recurse -Force -ErrorAction SilentlyContinue } }

    It 'parses without errors' {
        $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:MeasurePath, [ref]$null, [ref]$errs)
        $errs | Should -BeNullOrEmpty
    }

    It 'reports per-level totals (post tokens + counts)' {
        $r = Invoke-Measure $script:PassDagPath
        $r.totalNodes | Should -Be 4
        $r.l1.count | Should -Be 2
        $r.l1.tokensPost | Should -Be 35
        $r.l2.tokensPost | Should -Be 100
        $r.l3.tokensPost | Should -Be 10
    }

    It 'computes pre/post ratios from file pointers (L1 0.2, L2 0.5, L3 0.01)' {
        $r = Invoke-Measure $script:PassDagPath
        $r.l1.measured | Should -Be 1   # pointer-less node excluded, never fails on suspicion
        $r.l1.ratio | Should -Be 0.2
        $r.l2.ratio | Should -Be 0.5
        $r.l3.ratio | Should -Be 0.01
        $r.verdict | Should -Be 'PASS'
    }

    It 'WARNs when a level breaches its threshold (bloated L1 ratio 20 > 0.35)' {
        $r = Invoke-Measure $script:WarnDagPath
        $r.l1.ratio | Should -Be 20.0
        $r.l1.verdict | Should -Be 'WARN'
        $r.verdict | Should -Be 'WARN'
    }

    It 'empty DAG is vacuous PASS with zero totals' {
        $r = Invoke-Measure $script:EmptyDagPath
        $r.totalNodes | Should -Be 0
        $r.verdict | Should -Be 'PASS'
    }

    It 'zone readout maps 85% to RED and 45% to YELLOW (YELLOW>40%->RED>80%)' {
        $red = Invoke-Measure $script:PassDagPath -Tokens 170000
        $red.zone | Should -Be 'RED'
        $yellow = Invoke-Measure $script:PassDagPath -Tokens 90000
        $yellow.zone | Should -Be 'YELLOW'
    }
}
