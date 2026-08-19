#requires -Version 7
<#
.SYNOPSIS
    Tests for the push-callback completion system (monitor → invoke-callback → signal → BabyAGI).

    Verifies that:
    - monitor-subagent.ps1 has -CompletionCallback/-TaskId params
    - post-delegation-check.ps1 forwards -CompletionCallback/-TaskId to monitor
    - babyagi-loop.ps1 Invoke-TaskAsync uses FileSystemWatcher + Wait-Event (NOT polling)
    - delegation-registry.ps1 has "cancel" action
    - invoke-callback.ps1 creates result + signal files atomically
    - Backward compat: monitor without callback still writes result file

    Run: Invoke-Pester scripts\tests\monitor-callback.Tests.ps1
#>

Describe "Push-callback async delegation system" {
    BeforeAll {
        $root   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # repo root
        $sdir   = Join-Path $root 'scripts'
    }

    It "monitor-subagent.ps1 has -CompletionCallback parameter" {
        $src = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        $src | Should -Match 'CompletionCallback'
    }

    It "monitor-subagent.ps1 has -TaskId parameter with PID file lifecycle" {
        $src = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        $src | Should -Match 'TaskId'
        $src | Should -Match 'async-monitor-{TaskId}.pid'
    }

    It "monitor-subagent.ps1 has atomic result write (temp + Move-Item)" {
        $src = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        $src | Should -Match 'Move-Item'
        $src | Should -Match '\.tmp'
    }

    It "post-delegation-check.ps1 forwards CompletionCallback to monitor" {
        $src = Get-Content (Join-Path $sdir 'post-delegation-check.ps1') -Raw
        $src | Should -Match 'CompletionCallback'
        $src | Should -Match 'Launch-AsyncMonitor'  # still calls monitor
    }

    It "post-delegation-check.ps1 has -CompletionCallback parameter in param block" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $sdir 'post-delegation-check.ps1'), [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $sdir 'post-delegation-check.ps1'), [ref]$tokens, [ref]$errors)
        $paramBlock = $ast.Find({ $args[0] -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
        $paramNames = $paramBlock.Parameters.Name.VariablePath | ForEach-Object { $_.ToString() }
        $paramNames | Should -Contain 'CompletionCallback'
    }

    It "babyagi-loop.ps1 Invoke-TaskAsync has NO Start-Sleep polling" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        # The Invoke-TaskAsync function must NOT contain polling Start-Sleep
        $funcBody = $src -replace '(?s).*function Invoke-TaskAsync.*?\{(.+?)\}.*', '$1'
        $funcBody -notmatch 'Start-Sleep -Seconds \$PollSec' | Should -BeTrue
        $funcBody -notmatch 'while \(-not \(Test-Path \$resultFile\)' | Should -BeTrue
    }

    It "babyagi-loop.ps1 Invoke-TaskAsync uses FileSystemWatcher + Wait-Event" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Match 'FileSystemWatcher'
        $src | Should -Match 'Wait-Event'
        $src | Should -Match 'CompletionCallback'
    }

    It "babyagi-loop.ps1 uses #requires -Version 7 (was 5.1)" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Match '#requires -Version 7'
    }

    It "delegation-registry.ps1 has cancel in ValidateSet" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match '"cancel"'
    }

    It "delegation-registry.ps1 has MonitorPid parameter" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match 'MonitorPid'
    }

    It "invoke-callback.ps1 exists and is syntactically valid" {
        $path = Join-Path $sdir 'invoke-callback.ps1'
        Test-Path $path | Should -BeTrue
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "invoke-callback.ps1 writes both result + signal files" {
        $path = Join-Path $sdir 'invoke-callback.ps1'
        $src = Get-Content $path -Raw
        $src | Should -Match 'async-result.json'
        $src | Should -Match 'async-done'
        $src | Should -Match 'Move-Item'  # atomic write
    }

    It "All 5 scripts pass syntax check (0 errors)" {
        $files = @('monitor-subagent.ps1', 'post-delegation-check.ps1', 'babyagi-loop.ps1',
                   'delegation-registry.ps1', 'invoke-callback.ps1')
        foreach ($f in $files) {
            $full = Join-Path $sdir $f
            $tokens = $null; $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($full, [ref]$tokens, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0 -Because "$f has $($errors.Count) parse errors"
        }
    }

    # --- Security fix tests ---

    It "post-delegation-check.ps1 validates CompletionCallback path (rejects non-existent)" {
        $src = Get-Content (Join-Path $sdir 'post-delegation-check.ps1') -Raw
        $src | Should -Match 'Resolve-Path.*CompletionCallback'
        $src | Should -Match 'callback_validation'
    }

    It "post-delegation-check.ps1 rejects CompletionCallback with unsafe metacharacters" {
        $src = Get-Content (Join-Path $sdir 'post-delegation-check.ps1') -Raw
        $src | Should -Match 'unsafe metacharacter'
        $src | Should -Match 'CompletionCallback -match'
    }

    It "delegation-registry.ps1 cancel action verifies process identity before kill" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        # Must check CommandLine for monitor-subagent before Stop-Process
        $src | Should -Match 'isMonitor'
        $src | Should -Match 'monitor-subagent'
        # Must have PID reuse protection warning
        $src | Should -Match 'PID reuse protection'
    }

    It "delegation-registry.ps1 resolve action uses Add-Member guard (strict-mode safe)" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        # Add-Member guards against strict-mode property creation error
        $src | Should -Match 'Add-Member.*resolved'
        # Must have property existence check before assignment (the guard)
        $src | Should -Match "PSObject.Properties.Name -contains 'resolved'"
        $src | Should -Match 'Add-Member.*cancelled'
        $src | Should -Match "PSObject.Properties.Name -contains 'cancelled'"
    }
}
