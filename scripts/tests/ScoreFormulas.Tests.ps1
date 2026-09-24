#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Pester 6 tests for pure scoring formulas in scripts/lib/score-formulas.ps1.
.DESCRIPTION
  Exact-assert coverage of the 4 formulas extracted behavior-preserving from
  score-dims.ps1: DC (Dead Code), Bi (Bitacora), Me (Metrics), CA (Cycle Activity).
  No I/O — dot-sources the pure module only.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'lib' 'score-formulas.ps1')
}

Describe 'Get-DcScore (Dead Code)' {
    It 'returns 10 when everything is clean (0,0,0)' {
        Get-DcScore -Orphans 0 -DeadJunctions 0 -Commented 0 | Should -Be 10
    }
    It 'deducts 2 when orphans > 5 (6,0,0 -> 8)' {
        Get-DcScore -Orphans 6 -DeadJunctions 0 -Commented 0 | Should -Be 8
    }
    It 'deducts 2 for large orphan counts (10,0,0 -> 8)' {
        Get-DcScore -Orphans 10 -DeadJunctions 0 -Commented 0 | Should -Be 8
    }
    It 'deducts 1 when orphans in 1..5 (1,0,0 -> 9)' {
        Get-DcScore -Orphans 1 -DeadJunctions 0 -Commented 0 | Should -Be 9
    }
    It 'deducts 1 at orphan boundary 5 (5,0,0 -> 9)' {
        Get-DcScore -Orphans 5 -DeadJunctions 0 -Commented 0 | Should -Be 9
    }
    It 'deducts 1 when deadJunctions > 0 (0,1,0 -> 9)' {
        Get-DcScore -Orphans 0 -DeadJunctions 1 -Commented 0 | Should -Be 9
    }
    It 'deducts 1 for multiple dead junctions (0,3,0 -> 9)' {
        Get-DcScore -Orphans 0 -DeadJunctions 3 -Commented 0 | Should -Be 9
    }
    It 'deducts 1 when commented > 10 (0,0,11 -> 9)' {
        Get-DcScore -Orphans 0 -DeadJunctions 0 -Commented 11 | Should -Be 9
    }
    It 'deducts 0 at commented boundary 10 (0,0,10 -> 10)' {
        Get-DcScore -Orphans 0 -DeadJunctions 0 -Commented 10 | Should -Be 10
    }
    It 'stacks all penalties (6,1,11 -> 6)' {
        Get-DcScore -Orphans 6 -DeadJunctions 1 -Commented 11 | Should -Be 6
    }
    It 'stacks minor penalties (3,2,20 -> 7)' {
        Get-DcScore -Orphans 3 -DeadJunctions 2 -Commented 20 | Should -Be 7
    }
    It 'combines orphan-major with clean rest (6,0,5 -> 8)' {
        Get-DcScore -Orphans 6 -DeadJunctions 0 -Commented 5 | Should -Be 8
    }
}

Describe 'Get-BiScore (Bitacora)' {
    It 'returns 10 when lines > 10 (T,11)' {
        Get-BiScore -Exists $true -Lines 11 | Should -Be 10
    }
    It 'returns 7 when lines in 6..10 (T,6)' {
        Get-BiScore -Exists $true -Lines 6 | Should -Be 7
    }
    It 'returns 7 at upper middle boundary (T,10)' {
        Get-BiScore -Exists $true -Lines 10 | Should -Be 7
    }
    It 'returns 5 when file exists with few lines (T,3)' {
        Get-BiScore -Exists $true -Lines 3 | Should -Be 5
    }
    It 'returns 5 at lower middle boundary (T,5)' {
        Get-BiScore -Exists $true -Lines 5 | Should -Be 5
    }
    It 'returns 0 when file is missing (F,0)' {
        Get-BiScore -Exists $false -Lines 0 | Should -Be 0
    }
    It 'lines dominate existence flag (F,20 -> 10)' {
        Get-BiScore -Exists $false -Lines 20 | Should -Be 10
    }
    It 'lines dominate existence flag in middle tier (F,7 -> 7)' {
        Get-BiScore -Exists $false -Lines 7 | Should -Be 7
    }
}

Describe 'Get-MeScore (Metrics)' {
    It 'returns 10 for full setup with reports bonus (T,T,T,T)' {
        Get-MeScore -Dir $true -ErrDir $true -ErrJson $true -Reports $true | Should -Be 10
    }
    It 'returns 4 when nothing exists (F,F,F,F)' {
        Get-MeScore -Dir $false -ErrDir $false -ErrJson $false -Reports $false | Should -Be 4
    }
    It 'returns 7 for metrics dir alone (T,F,F,F)' {
        Get-MeScore -Dir $true -ErrDir $false -ErrJson $false -Reports $false | Should -Be 7
    }
    It 'returns 9 for dir plus error json (T,F,T,F)' {
        Get-MeScore -Dir $true -ErrDir $false -ErrJson $true -Reports $false | Should -Be 9
    }
    It 'returns 9 for dir plus error json without bonus path (T,T,T,F)' {
        Get-MeScore -Dir $true -ErrDir $true -ErrJson $true -Reports $false | Should -Be 9
    }
    It 'adds reports bonus to base 4 (F,T,F,T -> 5)' {
        Get-MeScore -Dir $false -ErrDir $true -ErrJson $false -Reports $true | Should -Be 5
    }
    It 'adds reports bonus to dir-only base (T,T,F,T -> 8)' {
        Get-MeScore -Dir $true -ErrDir $true -ErrJson $false -Reports $true | Should -Be 8
    }
    It 'needs both reports and errDir for bonus (T,F,T,T -> 9)' {
        Get-MeScore -Dir $true -ErrDir $false -ErrJson $true -Reports $true | Should -Be 9
    }
}

Describe 'Get-CaScore (Cycle Activity)' {
    It 'returns 5.0 for half target (15,30)' {
        Get-CaScore -Count 15 -Target 30 | Should -Be 5.0
    }
    It 'returns 10 at full target (30,30)' {
        Get-CaScore -Count 30 -Target 30 | Should -Be 10
    }
    It 'returns 0 for zero count (0,30)' {
        Get-CaScore -Count 0 -Target 30 | Should -Be 0
    }
    It 'caps above target at 10 (45,30)' {
        Get-CaScore -Count 45 -Target 30 | Should -Be 10
    }
    It 'throws on Target=0 like prod (15,0)' {
        { Get-CaScore -Count 15 -Target 0 } | Should -Throw
    }
    It 'throws on Target=0 with zero count like prod (0,0)' {
        { Get-CaScore -Count 0 -Target 0 } | Should -Throw
    }
}
