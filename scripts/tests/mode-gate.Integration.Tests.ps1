#requires -Version 7
<#
.SYNOPSIS
    Integration tests for mode-gate.ps1 — single-mode (Refactor-AP S2).
.DESCRIPTION
    New expectations: every target is ALLOWED; `-auto`/`-semi` are compat
    aliases (ALLOWED + warning); `.gentleman-mode` / `-Mode` are no-ops
    (always effective 'manual', fallback 'manual').
.NOTES
    Tests run against a per-run temp mode file (-ModeFilePath) — the repo's
    real .gentleman-mode is never read or written. Safe to run in parallel
    with permission-gate.Tests.ps1 (each uses its own temp file).
#>

BeforeAll {
    $scriptsRoot = Resolve-Path "$PSScriptRoot/.."
    $scriptPath = "$scriptsRoot/mode-gate.ps1"
    $realModeFile = "$scriptsRoot/../.gentleman-mode"
    $modeFilePath = Join-Path ([System.IO.Path]::GetTempPath()) ("gentleman-mode-test-{0}.txt" -f ([guid]::NewGuid().ToString("N")))
    $realMode = if (Test-Path -LiteralPath $realModeFile) { (Get-Content -LiteralPath $realModeFile -Raw).Trim() } else { 'manual' }
    Set-Content -LiteralPath $modeFilePath -Value $realMode -NoNewline -Encoding ASCII -Force

    function Invoke-ModeGate {
        param(
            [string]$TargetAgent,
            [string]$Mode = "",
            [switch]$Json
        )
        $invoke = @{ TargetAgent = $TargetAgent; ModeFilePath = $modeFilePath }
        if ($Mode) { $invoke.Mode = $Mode }
        if ($Json) { $invoke.Json = $true }
        & $scriptPath @invoke 2>&1
    }

    function Invoke-ModeGateWarning {
        param(
            [string]$TargetAgent,
            [string]$Mode = ""
        )
        $invoke = @{ TargetAgent = $TargetAgent; ModeFilePath = $modeFilePath }
        if ($Mode) { $invoke.Mode = $Mode }
        & $scriptPath @invoke 3>&1 2>$null | Out-String
    }
}

AfterAll {
    if (Test-Path -LiteralPath $modeFilePath) {
        Remove-Item -LiteralPath $modeFilePath -Force
    }
}

Describe "Mode gate — single-mode base agents" {

    It "ALLOWS gentle-MK (default agent)" {
        $output = Invoke-ModeGate -TargetAgent "gentle-MK" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.mode | Should -Be "manual"
        $result.expected_suffix | Should -Be ""
        $LASTEXITCODE | Should -Be 0
    }

    It "ALLOWS base agent (no suffix)" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $LASTEXITCODE | Should -Be 0
    }

    It "ALLOWS read-only specialist" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-security" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
    }

    It "ALLOWS SDD sub-agent" {
        $output = Invoke-ModeGate -TargetAgent "sdd-apply" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
    }
}

Describe "Mode gate — compat aliases" {

    It "ALLOWS -auto suffixed agent as compat alias" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick-auto" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.reason | Should -Match "Compat alias"
        $LASTEXITCODE | Should -Be 0
    }

    It "ALLOWS -semi suffixed agent as compat alias" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick-semi" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.reason | Should -Match "Compat alias"
        $LASTEXITCODE | Should -Be 0
    }

    It "ALLOWS gentle-MK-auto as compat alias" {
        $output = Invoke-ModeGate -TargetAgent "gentle-MK-auto" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $LASTEXITCODE | Should -Be 0
    }

    It "emits a warning for suffixed aliases" {
        $text = Invoke-ModeGateWarning -TargetAgent "gentleman-quick-auto"
        $text | Should -Match "compat alias"
    }
}

Describe "Mode gate — mode file and -Mode are no-ops" {

    It "treats mode file 'auto' as manual" {
        Set-Content -LiteralPath $modeFilePath -Value "auto" -NoNewline -Encoding ASCII -Force
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.mode | Should -Be "manual"
    }

    It "treats mode file 'semi' as manual" {
        Set-Content -LiteralPath $modeFilePath -Value "semi" -NoNewline -Encoding ASCII -Force
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick" -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.mode | Should -Be "manual"
    }

    It "ALLOWS with -Mode auto override (no-op)" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-deep" -Mode auto -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.mode | Should -Be "manual"
    }

    It "ALLOWS with -Mode semi override (no-op)" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-deep-semi" -Mode semi -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
        $result.mode | Should -Be "manual"
    }

    It "ALLOWS with -Mode manual override" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-deep" -Mode manual -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.allowed | Should -Be $true
    }
}

Describe "Mode gate — edge cases" {

    It "falls back to manual when .gentleman-mode missing" {
        # Rename mode file temporarily
        $backup = Join-Path ([System.IO.Path]::GetTempPath()) "gentleman-mode-bak-$(Get-Random)"
        Move-Item -LiteralPath $modeFilePath -Destination $backup -Force
        try {
            $output = Invoke-ModeGate -TargetAgent "gentleman-quick" -Json
            $result = $output | Out-String | ConvertFrom-Json
            $result.mode | Should -Be "manual"
            $result.allowed | Should -Be $true
        } finally {
            Move-Item -LiteralPath $backup -Destination $modeFilePath -Force
        }
    }

    It "outputs expected JSON fields" {
        $output = Invoke-ModeGate -TargetAgent "gentleman-quick" -Mode manual -Json
        $result = $output | Out-String | ConvertFrom-Json
        $result.action | Should -Be "mode-gate"
        $result | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name } | Sort-Object
        $expectedFields = @('action', 'mode', 'target_agent', 'expected_suffix', 'allowed', 'reason')
        $actualFields = ($result | Get-Member -MemberType NoteProperty).Name
        foreach ($f in $expectedFields) {
            $f -in $actualFields | Should -Be $true
        }
    }
}
