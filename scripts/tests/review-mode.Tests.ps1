#requires -Version 5.1
<#
.SYNOPSIS
    Tests for review-mode-status/disable + last_synced_at (upstream v3.5.0 adaptado).
.DESCRIPTION
    Pester 5 dash-style. Hermetico via env RDD_MODE / RDD_MODE_FILE y -StatePath
    explicito (sin tocar el repo real ni el user env). Requiere Pester 5.5+ en pwsh.
#>

BeforeAll {
    $statusPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'review-mode-status.ps1'
    $disablePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'review-mode-disable.ps1'
    # PS-CI-03 remediation: allowlist validation — only .ps1 directly under scripts/
    $scriptsDir = Resolve-Path -LiteralPath (Split-Path $PSScriptRoot -Parent) -ErrorAction Stop
    foreach ($p in @($statusPath, $disablePath)) {
        $resolved = Resolve-Path -LiteralPath $p -ErrorAction Stop
        if ([System.IO.Path]::GetExtension($resolved.Path) -ne '.ps1') { throw "Blocked: allowlist requires .ps1 ($p)" }
        if (-not $resolved.Path.StartsWith($scriptsDir.Path, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Blocked: path outside scripts/ ($p)" }
    }
    $statusPath = (Resolve-Path -LiteralPath $statusPath -ErrorAction Stop).Path
    $disablePath = (Resolve-Path -LiteralPath $disablePath -ErrorAction Stop).Path

    $script:oldRddMode = $env:RDD_MODE
    $script:oldRddModeFile = $env:RDD_MODE_FILE
    $script:oldPesterTest = $env:PESTER_TEST
    $env:PESTER_TEST = '1'
    . (Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-vmk.ps1')
    if ($null -eq $script:oldPesterTest) {
        Remove-Item Env:PESTER_TEST -ErrorAction SilentlyContinue
    }
    else {
        $env:PESTER_TEST = $script:oldPesterTest
    }

    $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pester-reviewmode-" + (Get-Random))
    New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null
}

AfterAll {
    if ($null -eq $script:oldRddMode) {
        Remove-Item Env:RDD_MODE -ErrorAction SilentlyContinue
    }
    else {
        $env:RDD_MODE = $script:oldRddMode
    }
    if ($null -eq $script:oldRddModeFile) {
        Remove-Item Env:RDD_MODE_FILE -ErrorAction SilentlyContinue
    }
    else {
        $env:RDD_MODE_FILE = $script:oldRddModeFile
    }
    if (Test-Path $script:tempRoot) {
        Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'review-mode-status.ps1' {
    AfterEach {
        Remove-Item Env:RDD_MODE -ErrorAction SilentlyContinue
        Remove-Item Env:RDD_MODE_FILE -ErrorAction SilentlyContinue
    }

    It 'defaults to on with source default when no override exists' {
        $env:RDD_MODE_FILE = Join-Path $script:tempRoot 'missing-rdd-mode.json'
        $line = & "$statusPath" | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $line | ConvertFrom-Json
        $json.mode | Should -Be 'on'
        $json.source | Should -Be 'default'
    }

    It 'honors clone override off' {
        $clone = Join-Path $script:tempRoot 'clone-rdd-mode.json'
        '{"mode":"off"}' | Set-Content -LiteralPath $clone -Encoding UTF8
        $env:RDD_MODE_FILE = $clone
        $line = & "$statusPath" | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $line | ConvertFrom-Json
        $json.mode | Should -Be 'off'
        $json.source | Should -Be 'clone'
    }

    It 'prefers global override over clone' {
        $clone = Join-Path $script:tempRoot 'clone-beaten.json'
        '{"mode":"off"}' | Set-Content -LiteralPath $clone -Encoding UTF8
        $env:RDD_MODE_FILE = $clone
        $env:RDD_MODE = 'on'
        $line = & "$statusPath" | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $line | ConvertFrom-Json
        $json.mode | Should -Be 'on'
        $json.source | Should -Be 'global'
    }
}

Describe 'review-mode-disable.ps1' {
    AfterEach {
        Remove-Item Env:RDD_MODE -ErrorAction SilentlyContinue
        Remove-Item Env:RDD_MODE_FILE -ErrorAction SilentlyContinue
        Remove-Item Env:RDD_AUDIT_FILE -ErrorAction SilentlyContinue
    }

    It 'writes off to the clone file and appends audit' {
        $clone = Join-Path $script:tempRoot 'disable-rdd-mode.json'
        $env:RDD_MODE_FILE = $clone
        $env:RDD_AUDIT_FILE = Join-Path $script:tempRoot 'audit.log'
        & "$disablePath" -Scope clone -Confirm:$false | Out-Null
        $saved = Get-Content -LiteralPath $clone -Raw -Encoding UTF8 | ConvertFrom-Json
        $saved.mode | Should -Be 'off'
        Test-Path -LiteralPath $env:RDD_AUDIT_FILE | Should -Be $true
        $audit = Get-Content -LiteralPath $env:RDD_AUDIT_FILE -Raw -Encoding UTF8
        $audit | Should -Match 'scope=clone'
        $audit | Should -Match 'action=review-mode-disable'
        $line = & "$statusPath" | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        $json = $line | ConvertFrom-Json
        $json.mode | Should -Be 'off'
        $json.source | Should -Be 'clone'
    }

    It 'does not write when -WhatIf is used' {
        $clone = Join-Path $script:tempRoot 'whatif-rdd-mode.json'
        $env:RDD_MODE_FILE = $clone
        $env:RDD_AUDIT_FILE = Join-Path $script:tempRoot 'whatif-audit.log'
        & "$disablePath" -Scope clone -WhatIf -Confirm:$false | Out-Null
        Test-Path -LiteralPath $clone | Should -Be $false
        Test-Path -LiteralPath $env:RDD_AUDIT_FILE | Should -Be $false
    }
}

Describe 'last_synced_at' {
    It 'is written on success and preserves the prior value on skip/fail' {
        $state = Join-Path $script:tempRoot 'state.json'
        if (Test-Path -LiteralPath $state) {
            Remove-Item -LiteralPath $state -Force
        }
        $missing = Join-Path $script:tempRoot 'nonexistent.json'
        Sync-Config -TargetPath $missing -Label 'missing' -PreserveMCP $false
        Test-Path -LiteralPath $state | Should -Be $false
        Write-LastSyncedAt -StatePath $state
        $after = Get-Content -LiteralPath $state -Raw -Encoding UTF8 | ConvertFrom-Json
        $after.last_synced_at | Should -Not -BeNullOrEmpty
        { [datetime]$after.last_synced_at | Out-Null } | Should -Not -Throw
        $before = Get-Content -LiteralPath $state -Raw -Encoding UTF8
        Sync-Config -TargetPath $missing -Label 'missing' -PreserveMCP $false
        $now = Get-Content -LiteralPath $state -Raw -Encoding UTF8
        $now | Should -Be $before
    }
}
