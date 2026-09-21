#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Pester 6 tests for SP proportional threshold boundaries (ADR-047).
.DESCRIPTION
  Tests the SP (Script Performance) dimension threshold: max(60, skillDirCount × 1.3).
  Boundary tests at 100 skills → threshold = 130, testing scripts 129-132.
  Does NOT modify existing ScoreMaths.Tests.ps1 (separate test file per plan).
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    $script:math = [math]

    # Extracted pure function from score-dims.ps1 SP scoring with ADR-047 threshold.
    # Mirrors score-dims.ps1:370-383 logic (no I/O, no side effects).
    function Get-SpScoreAdr047([int]$TotalScripts, [int]$SkillDirCount, [double]$AvgKB, [int]$HugeCount) {
        $sp = 10
        # ADR-047: threshold = max(60, skillDirCount × 1.3)
        $spScriptThreshold = [math]::Max(60, $SkillDirCount * 1.3)
        if ($TotalScripts -lt 15 -or $TotalScripts -gt $spScriptThreshold) { $sp -= 1 }
        if ($AvgKB -gt 15) { $sp -= 1 } elseif ($AvgKB -gt 20) { $sp -= 2 }
        if ($HugeCount -gt 0) { $sp -= 2 }
        return $script:math::Max(0, $script:math::Min(10, $sp))
    }
}

Describe 'SP Threshold Boundaries (ADR-047 proportional)' {
    Context '100 skills → threshold = max(60, 130) = 130' {
        It '129 scripts ≤ 130 → no penalty (SP = 10)' {
            Get-SpScoreAdr047 -TotalScripts 129 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 10
        }
        It '130 scripts ≤ 130 → no penalty (SP = 10)' {
            Get-SpScoreAdr047 -TotalScripts 130 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 10
        }
        It '131 scripts > 130 → penalty -1 (SP = 9)' {
            Get-SpScoreAdr047 -TotalScripts 131 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 9
        }
        It '132 scripts > 130 → penalty -1 (SP = 9)' {
            Get-SpScoreAdr047 -TotalScripts 132 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 9
        }
    }

    Context 'Floor guard: 30 skills → threshold = max(60, 39) = 60' {
        It '59 scripts ≤ 60 → no penalty (SP = 10)' {
            Get-SpScoreAdr047 -TotalScripts 59 -SkillDirCount 30 -AvgKB 5.0 -HugeCount 0 | Should -Be 10
        }
        It '60 scripts ≤ 60 → no penalty (SP = 10)' {
            Get-SpScoreAdr047 -TotalScripts 60 -SkillDirCount 30 -AvgKB 5.0 -HugeCount 0 | Should -Be 10
        }
        It '61 scripts > 60 → penalty -1 (SP = 9)' {
            Get-SpScoreAdr047 -TotalScripts 61 -SkillDirCount 30 -AvgKB 5.0 -HugeCount 0 | Should -Be 9
        }
    }

    Context 'Below minimum: <15 scripts always penalized' {
        It '14 scripts → penalty -1 (SP = 9)' {
            Get-SpScoreAdr047 -TotalScripts 14 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 9
        }
        It '15 scripts within threshold → no penalty (SP = 10)' {
            Get-SpScoreAdr047 -TotalScripts 15 -SkillDirCount 100 -AvgKB 5.0 -HugeCount 0 | Should -Be 10
        }
    }
}
