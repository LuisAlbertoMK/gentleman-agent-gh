#requires -Version 7
<#
.SYNOPSIS
    Ronda 7 S1 — boot-budget gate + medición base (esencial <= 8192B FAIL).
.DESCRIPTION
    T1: live read-only gate of the 3 editable boot files vs budgets.
    T2: hermetic TestDrive fixtures proving the logic passes/fails.
    INFO only: total with generated opencode.json (measured, never gated).
.NOTES
    Baseline 2026-09-24 @ 52fc0dd3: 4987+4870+2292 = esencial 12149B > 8192B
    → T1 FAIL-inicial documentado (consciente). Fixed by S2/S3, never here.
#>

Describe 'Boot budget — arranque esencial (Ronda 7 S1)' {
    BeforeAll {
        $repoRoot = Join-Path $PSScriptRoot '..'
        $budgetEssential = 8192
        $budgets = @(
            @{ Name = 'AGENTS.md'; Path = Join-Path $repoRoot 'AGENTS.md'; Budget = 2800 }
            @{ Name = 'SKILLS-INDEX.md'; Path = Join-Path $repoRoot 'SKILLS-INDEX.md'; Budget = 3000 }
            @{ Name = 'prompts/gentle-MK.md'; Path = Join-Path $repoRoot 'prompts\gentle-MK.md'; Budget = 1200 }
        )
        $configPath = Join-Path $repoRoot 'opencode.json'
        function Get-BootByte {
            param([string]$LiteralPath)
            (Get-Item -LiteralPath $LiteralPath).Length
        }
        function New-BootFile {
            param([string]$Dir, [int[]]$ByteSizes)
            New-Item -ItemType Directory -Path $Dir | Out-Null
            for ($i = 0; $i -lt $ByteSizes.Count; $i++) {
                [System.IO.File]::WriteAllBytes((Join-Path $Dir "f$($i).md"), [byte[]]::new($ByteSizes[$i]))
            }
            $total = 0
            foreach ($f in Get-ChildItem -LiteralPath $Dir) { $total += $f.Length }
            return $total
        }
    }
    Context 'T1 — Live gate (read-only, FAIL-inicial consciente: baseline 12149B > 8192B)' {
        It 'esencial <= 8192B (AGENTS + SKILLS-INDEX + gentle-MK)' {
            $total = 0
            foreach ($b in $budgets) { $total += Get-BootByte $b.Path }
            ($total -le $budgetEssential) | Should -BeTrue
        }
        It 'AGENTS.md <= 2800B (violador: AGENTS.md)' {
            ((Get-BootByte $budgets[0].Path) -le $budgets[0].Budget) | Should -BeTrue
        }
        It 'SKILLS-INDEX.md <= 3000B (violador: SKILLS-INDEX.md)' {
            ((Get-BootByte $budgets[1].Path) -le $budgets[1].Budget) | Should -BeTrue
        }
        It 'prompts/gentle-MK.md <= 1200B (violador: prompts/gentle-MK.md)' {
            ((Get-BootByte $budgets[2].Path) -le $budgets[2].Budget) | Should -BeTrue
        }
        It 'INFO: total con opencode.json (generado, solo informativo)' {
            $essential = 0
            foreach ($b in $budgets) { $essential += Get-BootByte $b.Path }
            $config = Get-BootByte $configPath
            Write-Host "INFO boot-total=$($essential + $config)B (esencial=${essential}B + opencode.json=${config}B)"
            $true | Should -BeTrue
        }
    }
    Context 'T2 — Fixtures hermeticas (TestDrive, sin tocar el repo)' {
        It 'PASS: esencial ficticio bajo budget' {
            $total = New-BootFile (Join-Path $TestDrive 'pass') @(1000, 2000, 500)
            ($total -le $budgetEssential) | Should -BeTrue
        }
        It 'FAIL: esencial ficticio sobre budget (logica detecta exceso)' {
            $total = New-BootFile (Join-Path $TestDrive 'fail') @(4987, 4870, 2292)
            ($total -gt $budgetEssential) | Should -BeTrue
        }
    }
}
