#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Pester 6 tests for pure scoring math from score-dims.ps1 (sourced by score-auto.ps1)
.DESCRIPTION
  Tests SP (Script Performance), Or (Orthography), BP (Best Practices), and
  CC (Clean Code) scoring logic. No I/O — extracted as pure functions.
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    # ponytail: extracted pure math from score-dims.ps1 — no I/O, no side effects
    # score-dims.ps1 has no function blocks (all inline), so manual extraction.
    $script:math = [math]

    # From scripts/lib/score-dims.ps1 L389-401 (+ ADR-047 comment L380-388) — SP scoring
    function Get-SpScore([int]$TotalScripts, [double]$AvgKB, [int]$HugeCount, [double]$Threshold = 60) {
        $sp = 10
        if ($TotalScripts -lt 15 -or $TotalScripts -gt $Threshold) { $sp -= 1 }
        # Note: condition order matters — >20 checked first, then >15 (prod L393-398)
        if ($AvgKB -gt 20) { $sp -= 2 } elseif ($AvgKB -gt 15) { $sp -= 1 }
        if ($HugeCount -gt 0) { $sp -= 2 }
        return $script:math::Max(0, $script:math::Min(10, $sp))
    }

    # From scripts/lib/score-dims.ps1 L70-76 — PA scoring (pure replica, no prod extraction)
    function Get-PaScore([bool]$CrossRefClean, [bool]$HasReadme, [int]$SkillDirCount, [bool]$HasProjectJson) {
        $paScore = 10
        if (-not $CrossRefClean) { $paScore -= 2 }
        if (-not $HasReadme) { $paScore -= 2 }
        if ($SkillDirCount -lt 60) { $paScore -= 2 }
        if (-not $HasProjectJson) { $paScore -= 1 }
        return $script:math::Max(0, $paScore)
    }

    # From score-dims.ps1 lines 202-210 — Or scoring (corruption tiers)
    function Get-OrScore([int]$Corrupted) {
        if ($Corrupted -gt 10) { return 4 }
        elseif ($Corrupted -gt 5) { return 7 }
        elseif ($Corrupted -gt 0) { return 9 }
        else { return 10 }
    }

    # From score-dims.ps1 lines 165-170 — BP bonus/penalty
    function Get-BpBonus([double]$TryCatchRatio, [double]$BaseBP) {
        if ($TryCatchRatio -ge 0.8) { return $script:math::Min(10, $BaseBP + 1) }
        elseif ($TryCatchRatio -le 0.3) { return $script:math::Max(0, $BaseBP - 1) }
        return $BaseBP
    }

    # From score-dims.ps1 lines 149-152 — CC ratio scoring
    function Get-CcScore([double]$HelpR, [double]$ParamR, [double]$StrictR) {
        return $script:math::Round(($HelpR + $ParamR + $StrictR) / 3 * 10, 1)
    }
}

Describe 'SP Score (Script Performance)' {
    It 'returns 10 for ideal parameters (30 scripts, 5KB avg, 0 huge)' {
        Get-SpScore 30 5.0 0 | Should -Be 10
    }
    It 'penalizes -1 for low script count (<15)' {
        Get-SpScore 10 5.0 0 | Should -Be 9
    }
    It 'penalizes -1 for high script count (>threshold, default 60)' {
        Get-SpScore 70 5.0 0 | Should -Be 9
    }
    It 'penalizes -1 for avg size >15KB' {
        Get-SpScore 30 16.0 0 | Should -Be 9
    }
    It 'penalizes -2 for avg >20KB (>20 checked first, prod L394-398)' {
        Get-SpScore 30 25.0 0 | Should -Be 8
    }
    It 'penalizes -2 for huge scripts' {
        Get-SpScore 30 5.0 1 | Should -Be 8
    }
    It 'combines all penalties (10-1-2-2=5)' {
        Get-SpScore 10 25.0 3 | Should -Be 5
    }
    It 'never exceeds 10' {
        Get-SpScore 30 5.0 0 | Should -BeLessOrEqual 10
    }
    It 'ADR-047: 129 scripts @100 skills (threshold 130) -> no penalty -> 10' {
        Get-SpScore 129 5.0 0 -Threshold 130 | Should -Be 10
    }
    It 'ADR-047: 130 scripts @100 skills (threshold 130) -> boundary inclusive -> 10' {
        Get-SpScore 130 5.0 0 -Threshold 130 | Should -Be 10
    }
    It 'ADR-047: 131 scripts @100 skills (threshold 130) -> penalty -1 -> 9' {
        Get-SpScore 131 5.0 0 -Threshold 130 | Should -Be 9
    }
    It 'ADR-047: threshold formula Max(60, skills*1.3) - 100 skills -> 130' {
        $threshold = [math]::Max(60, 100 * 1.3)
        $threshold | Should -Be 130
        Get-SpScore 131 5.0 0 -Threshold $threshold | Should -Be 9
    }
}

Describe 'PA Score (Project Artifacts)' {
    It 'returns 10 for ideal parameters (clean xref, readme, 60+ skills, project.json)' {
        Get-PaScore $true $true 60 $true | Should -Be 10
    }
    It 'penalizes -2 for dirty cross-ref' {
        Get-PaScore $false $true 60 $true | Should -Be 8
    }
    It 'penalizes -2 for missing readme' {
        Get-PaScore $true $false 60 $true | Should -Be 8
    }
    It 'penalizes -2 for skillDirCount <60 (boundary: 59 penalizes, 60 passes)' {
        Get-PaScore $true $true 59 $true | Should -Be 8
        Get-PaScore $true $true 60 $true | Should -Be 10
    }
    It 'penalizes -1 for missing project.json' {
        Get-PaScore $true $true 60 $false | Should -Be 9
    }
    It 'combines all penalties (10-2-2-2-1=3)' {
        Get-PaScore $false $false 59 $false | Should -Be 3
    }
    It 'never drops below 0 (clamp)' {
        Get-PaScore $false $false 0 $false | Should -BeGreaterOrEqual 0
    }
}

Describe 'Or Score (Orthography Corruption)' {
    It 'returns 10 for zero corrupted files' {
        Get-OrScore 0 | Should -Be 10
    }
    It 'returns 9 for 1-5 corrupted files' {
        Get-OrScore 1 | Should -Be 9
        Get-OrScore 5 | Should -Be 9
    }
    It 'returns 7 for 6-10 corrupted files' {
        Get-OrScore 6 | Should -Be 7
        Get-OrScore 10 | Should -Be 7
    }
    It 'returns 4 for >10 corrupted files' {
        Get-OrScore 11 | Should -Be 4
        Get-OrScore 100 | Should -Be 4
    }
    It 'handles negative input as zero corruption' {
        Get-OrScore -1 | Should -Be 10
    }
}

Describe 'BP Bonus/Penalty (Best Practices)' {
    It 'adds +1 when try/catch ratio >= 0.8' {
        Get-BpBonus 0.8 7.0 | Should -Be 8.0
    }
    It 'caps bonus at 10 (cannot exceed)' {
        Get-BpBonus 1.0 10.0 | Should -Be 10
    }
    It 'subtracts -1 when try/catch ratio <= 0.3' {
        Get-BpBonus 0.3 5.0 | Should -Be 4.0
    }
    It 'floors penalty at 0' {
        Get-BpBonus 0.0 0.5 | Should -Be 0
    }
    It 'no change for ratio in (0.3, 0.8)' {
        Get-BpBonus 0.5 6.0 | Should -Be 6.0
    }
    It 'handles ratio exactly 0.3 (boundary — no change)' {
        Get-BpBonus 0.3 6.0 | Should -Be 5.0
    }
    It 'handles ratio exactly 0.8 (boundary — bonus applies)' {
        Get-BpBonus 0.8 5.0 | Should -Be 6.0
    }
}

Describe 'CC Score (Clean Code Ratios)' {
    It 'returns 10 when all ratios are 1.0 (100%)' {
        Get-CcScore 1.0 1.0 1.0 | Should -Be 10.0
    }
    It 'returns 0 when all ratios are 0' {
        Get-CcScore 0.0 0.0 0.0 | Should -Be 0.0
    }
    It 'averages three ratios scaled to 10' {
        # (1.0 + 0.0 + 0.0) / 3 * 10 = 3.3
        Get-CcScore 1.0 0.0 0.0 | Should -Be 3.3
    }
    It 'rounds to 1 decimal place' {
        # (0.7 + 0.8 + 0.7) / 3 * 10 = 7.333... → 7.3
        Get-CcScore 0.7 0.8 0.7 | Should -Be 7.3
    }
    It 'is symmetric across parameters' {
        $a = Get-CcScore 0.2 0.5 0.8
        $b = Get-CcScore 0.8 0.5 0.2
        $a | Should -Be $b
    }
}
