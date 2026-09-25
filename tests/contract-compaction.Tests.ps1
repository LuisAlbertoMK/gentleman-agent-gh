#requires -Version 7
<#
.SYNOPSIS
    R11-S3: compaction/snapshot NO-OP invariant (determinism/receipts guard).
.DESCRIPTION
    Freezes the R11 decision: scripts/lib/opencode-base.json compaction stays
    closed ({auto:true, prune:true, reserved:4000, keep:{tokens:8000}}),
    `snapshot` stays ABSENT, and `compaction.buffer` stays ABSENT.
    Any accidental compaction change FAILS ON PURPOSE — break this test only
    via an explicit owner-approved slice (see odd/tasks/ronda11-deuda.md R11-S3).
    Read-only: never modifies base.json (runtime intact).
#>

Describe 'Compaction/snapshot invariant (R11-S3 NO-OP)' {
    BeforeAll {
        $BasePath = Join-Path $PSScriptRoot '..\scripts\lib\opencode-base.json'
        $Base = Get-Content -LiteralPath $BasePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }

    It 'compaction is closed (auto/prune/reserved/keep.tokens)' {
        $Base.compaction.auto | Should -Be $true
        $Base.compaction.prune | Should -Be $true
        $Base.compaction.reserved | Should -Be 4000
        $Base.compaction.keep.tokens | Should -Be 8000
    }

    It 'snapshot is absent (NO-OP, determinism/receipts)' {
        ($Base.PSObject.Properties.Name -contains 'snapshot') | Should -Be $false
    }

    It 'compaction.buffer is absent (NO-OP default)' {
        ($Base.compaction.PSObject.Properties.Name -contains 'buffer') | Should -Be $false
    }
}
