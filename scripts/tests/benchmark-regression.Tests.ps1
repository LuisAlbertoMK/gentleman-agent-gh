#requires -Version 7

<#
.SYNOPSIS
    Tests for benchmark-regression.ps1 — statistical performance regression gate.

.DESCRIPTION
    Regression guard born from the perf-regression.yml CI failure (2026-08-25):
    the script had never been executed end-to-end before landing. Two latent
    bugs shipped undetected:
      1. $Quiet referenced at line 88 without existing in param() — instant
         death under Set-StrictMode -Version Latest.
      2. Array splatting (@scriptArgs) bound '-DryRun' as a positional VALUE
         instead of a switch (sync-vmk.ps1 Target ValidateSet rejection).
    These tests execute the REAL command used by .github/workflows/perf-regression.yml
    so any future breakage surfaces locally, not just in CI.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'benchmark-regression.ps1'
}

Describe "benchmark-regression.ps1 — JSON contract" {
    It "emits parseable JSON with required fields (guards StrictMode $Quiet crash)" {
        $output = & $scriptPath -Command "sync-vmk.ps1 -DryRun -Json" -Runs 5 -Json 2>&1
        $joined = ($output | Where-Object { $_ -is [string] }) -join "`n"
        $json = $joined | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNullOrEmpty -Because "workflow exits 1 when no JSON is produced"
        $json.runs | Should -Be 5
        $json.median_ms | Should -BeGreaterThan 0
        $json.status | Should -BeIn @('OK', 'BASELINE_CREATED', 'REGRESSION')
    }

    It "switch arguments bind correctly through the Command string" {
        # '-DryRun' must reach sync-vmk.ps1 as a SWITCH, not a positional value
        # (positional binding hits Target ValidateSet("global") and errors).
        $output = & $scriptPath -Command "sync-vmk.ps1 -DryRun -Json" -Runs 5 -Json 2>&1
        $stderr = ($output | Where-Object { $_ -isnot [string] }) | Out-String
        $stderr | Should -Not -Match 'ValidateSet|Cannot validate argument'
    }

    It "exit code is 0 when no regression detected" {
        & $scriptPath -Command "sync-vmk.ps1 -DryRun -Json" -Runs 5 -Json *> $null
        $LASTEXITCODE | Should -Be 0
    }
}
