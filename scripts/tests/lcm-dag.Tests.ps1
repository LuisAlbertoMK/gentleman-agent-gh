#requires -Version 5.1
# Pester tests for scripts/lcm-dag.ps1 — P0-1 parte 2/3 (DAG + escalation + PESTER_TEST isolation)
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'lcm-dag.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'lcm-dag.ps1'
        $script:TmpDag = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-dag-test-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0,8))
    }
    AfterAll { if (Test-Path $script:TmpDag) { Remove-Item $script:TmpDag -Force -ErrorAction SilentlyContinue } }

    It 'parses without errors' {
        $errs = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs)
        $errs | Should -BeNullOrEmpty
    }

    It 'escalation thresholds match watchdog zones' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        Invoke-LcmEscalation -CurrentTokens 70000 -Budget 200000 | Should -Be 'NONE'   # 35%
        Invoke-LcmEscalation -CurrentTokens 90000 -Budget 200000 | Should -Be 'L1'     # 45%
        Invoke-LcmEscalation -CurrentTokens 130000 -Budget 200000 | Should -Be 'L2'    # 65%
        Invoke-LcmEscalation -CurrentTokens 170000 -Budget 200000 | Should -Be 'L3'    # 85%
    }

    It 'PESTER_TEST=1 skips persistence (in-memory only)' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $n = Add-LcmNode -Level L1 -Content 'summary for pester' -Path $script:TmpDag
        $n.level | Should -Be 'L1'
        Test-Path $script:TmpDag | Should -BeFalse
    }

    It 'L3 without pointer warns' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $warnVar = $null
        Add-LcmNode -Level L3 -Content 'lossless but missing pointer' -Path $script:TmpDag -WarningVariable warnVar -WarningAction SilentlyContinue | Out-Null
        $warnVar | Should -Not -BeNullOrEmpty
    }

    It 'L3 with pointer is lossless' {
        $env:PESTER_TEST = '1'
        . $script:ScriptPath
        $n = Add-LcmNode -Level L3 -Content 'full file ref' -Pointer '.agents/skills/context-watchdog/SKILL.md' -Path $script:TmpDag -WarningAction SilentlyContinue
        $n.pointer | Should -Be '.agents/skills/context-watchdog/SKILL.md'
    }

    It 'L3 file pointer round-trips lossless (Add -> Get -> resolve -> sha256 match)' {
        # Needs persistence (Add->Get via file), so PESTER_TEST is OFF inside try; restored after.
        Remove-Item Env:PESTER_TEST -ErrorAction SilentlyContinue
        try {
            . $script:ScriptPath
            $src = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-src-{0}.md" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
            'lossless round-trip fixture content 123' | Set-Content -LiteralPath $src -Encoding UTF8 -NoNewline
            $hash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash.ToLower()
            $pointer = "file:$src#sha256:$hash"
            $n = Add-LcmNode -Level L3 -Content 'fixture summary' -Pointer $pointer -Path $script:TmpDag
            $got = Get-LcmNode -Id $n.id -Path $script:TmpDag
            $got.pointer | Should -Be $pointer
            $m = [regex]::Match($got.pointer, '^file:(?<ref>.+)#sha256:(?<hash>[0-9a-f]{64})$')
            $m.Success | Should -BeTrue
            (Get-FileHash -LiteralPath $m.Groups['ref'].Value -Algorithm SHA256).Hash.ToLower() | Should -Be $m.Groups['hash'].Value
            Remove-Item $src -Force -ErrorAction SilentlyContinue
        }
        finally { $env:PESTER_TEST = '1' }
    }

    It 'chain forms parent->child edges (Add -ParentId)' {
        # Needs persistence (Add->Get via file), so PESTER_TEST is OFF inside try; restored after.
        Remove-Item Env:PESTER_TEST -ErrorAction SilentlyContinue
        $chainDag = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-chain-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
        try {
            . $script:ScriptPath
            $a = Add-LcmNode -Level L1 -Content 'chain parent node' -Path $chainDag
            $b = Add-LcmNode -Level L2 -Content 'chain child node' -Path $chainDag -ParentId $a.id
            $b.parent | Should -Be $a.id
            $dag = Get-LcmDag -Path $chainDag
            @($dag.edges | Where-Object { $_.from -eq $a.id -and $_.to -eq $b.id }).Count | Should -Be 1
        }
        finally { $env:PESTER_TEST = '1'; Remove-Item $chainDag -Force -ErrorAction SilentlyContinue }
    }

    It 'GC keeps current cycle intact and prunes old cycle' {
        Remove-Item Env:PESTER_TEST -ErrorAction SilentlyContinue
        $gcDag = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-gc-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
        try {
            . $script:ScriptPath
            $fixture = @{
                nodes = @(
                    @{ id = 'lcm-l1-0001'; level = 'L1'; parent = $null; content = 'current parent'; pointer = $null; tokens = 10; createdAt = '2026-09-23T00:00:00'; cycle = 'cycle-current' },
                    @{ id = 'lcm-l2-0002'; level = 'L2'; parent = 'lcm-l1-0001'; content = 'current child'; pointer = $null; tokens = 10; createdAt = '2026-09-23T00:00:01'; cycle = 'cycle-current' },
                    @{ id = 'lcm-l1-0003'; level = 'L1'; parent = $null; content = 'old cycle node'; pointer = $null; tokens = 10; createdAt = '2026-09-20T00:00:00'; cycle = 'cycle-old' }
                )
                edges = @(
                    @{ from = 'lcm-l1-0001'; to = 'lcm-l2-0002' },
                    @{ from = 'lcm-l1-0003'; to = 'lcm-l1-0001' }
                )
                meta = @{ createdAt = '2026-09-20T00:00:00'; cycle = 'cycle-old'; budget = 200000 }
            }
            $fixture | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $gcDag -Encoding UTF8
            $r = Remove-LcmOldCycles -Path $gcDag -KeepCycle 'cycle-current'
            $r.pruned | Should -Be 1
            $r.prunedIds | Should -Contain 'lcm-l1-0003'
            $after = Get-Content $gcDag -Raw | ConvertFrom-Json
            @($after.nodes).Count | Should -Be 2
            @($after.nodes.id) | Should -Not -Contain 'lcm-l1-0003'
            # orphan edge (old→current) dropped; current parent→child edge intact
            @($after.edges).Count | Should -Be 1
            $after.edges[0].from | Should -Be 'lcm-l1-0001'
            $after.edges[0].to | Should -Be 'lcm-l2-0002'
            $after.meta.cycle | Should -Be 'cycle-current'
        }
        finally { $env:PESTER_TEST = '1'; Remove-Item $gcDag -Force -ErrorAction SilentlyContinue }
    }

    It 'GC without inter-track.json is a fail-closed no-op' {
        Remove-Item Env:PESTER_TEST -ErrorAction SilentlyContinue
        $gcDag = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-gcnoop-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
        $missingTrack = Join-Path ([System.IO.Path]::GetTempPath()) ("lcm-no-track-{0}.json" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
        try {
            . $script:ScriptPath
            $fixture = @{
                nodes = @(
                    @{ id = 'lcm-l1-0001'; level = 'L1'; parent = $null; content = 'node one'; pointer = $null; tokens = 10; createdAt = '2026-09-23T00:00:00'; cycle = 'cycle-x' },
                    @{ id = 'lcm-l1-0002'; level = 'L1'; parent = $null; content = 'node two'; pointer = $null; tokens = 10; createdAt = '2026-09-23T00:00:01'; cycle = 'cycle-y' }
                )
                edges = @()
                meta = @{ createdAt = '2026-09-23T00:00:00'; cycle = 'cycle-x'; budget = 200000 }
            }
            $fixture | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $gcDag -Encoding UTF8
            $before = Get-Content $gcDag -Raw
            $r = Remove-LcmOldCycles -Path $gcDag -InterTrackPath $missingTrack
            $r.pruned | Should -Be 0
            $r.kept | Should -Be 2
            $r.noOp | Should -BeTrue
            (Get-Content $gcDag -Raw) | Should -Be $before
        }
        finally { $env:PESTER_TEST = '1'; Remove-Item $gcDag -Force -ErrorAction SilentlyContinue }
    }
}
