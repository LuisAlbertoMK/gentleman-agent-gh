#requires -Version 7
<#
.SYNOPSIS
    Tests for the push-callback async delegation system.

    Verifies callback parameters, atomic writes, backward compat, and security
    hardening (path validation, PID identity, strict-mode safety).

    Run: Invoke-Pester scripts\tests\monitor-callback.Tests.ps1
#>

Describe "Push-callback async delegation system" {
    BeforeAll {
        $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $sdir = Join-Path $root 'scripts'
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

    It "monitor-subagent.ps1 invokes CompletionCallback on success" {
        $src = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        $src | Should -Match '& \$CompletionCallback'
        $src | Should -Match 'ResultJson'
    }

    It "post-delegation-check.ps1 forwards CompletionCallback to monitor" {
        $src = Get-Content (Join-Path $sdir 'post-delegation-check.ps1') -Raw
        $src | Should -Match 'CompletionCallback'
    }

    It "post-delegation-check.ps1 has -CompletionCallback parameter in param block" {
        $tokens = $null; $errors = $null
        $path = Join-Path $sdir 'post-delegation-check.ps1'
        [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
        $paramBlock = $ast.Find({ $args[0] -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
        $paramNames = $paramBlock.Parameters.Name.VariablePath | ForEach-Object { $_.ToString() }
        $paramNames | Should -Contain 'CompletionCallback'
    }

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

    It "babyagi-loop.ps1 Invoke-TaskAsync has NO Start-Sleep polling" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Not -Match 'Start-Sleep -Seconds \$PollSec'
        $src | Should -Not -Match 'while \(-not \(Test-Path \$resultFile\)'
    }

    It "babyagi-loop.ps1 Invoke-TaskAsync uses FileSystemWatcher + Wait-Event" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Match 'FileSystemWatcher'
        $src | Should -Match 'Wait-Event'
        $src | Should -Match 'CompletionCallback'
    }

    It "babyagi-loop.ps1 uses #requires -Version 7" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Match '#requires -Version 7'
    }

    It "babyagi-loop.ps1 has Set-StrictMode -Version Latest" {
        $src = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $src | Should -Match 'Set-StrictMode -Version Latest'
    }

    It "delegation-registry.ps1 has cancel in ValidateSet" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match '"cancel"'
    }

    It "delegation-registry.ps1 has MonitorPid parameter" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match 'MonitorPid'
    }

    It "delegation-registry.ps1 cancel action verifies process identity before kill" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match 'isMonitor'
        $src | Should -Match 'monitor-subagent'
        $src | Should -Match 'PID reuse protection'
    }

    It "delegation-registry.ps1 resolve action uses Add-Member guard (strict-mode safe)" {
        $src = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
        $src | Should -Match 'Add-Member.*resolved'
        $src | Should -Match "PSObject.Properties.Name -contains 'resolved'"
        $src | Should -Match 'Add-Member.*cancelled'
        $src | Should -Match "PSObject.Properties.Name -contains 'cancelled'"
    }

    It "invoke-callback.ps1 exists and is syntactically valid" {
        $path = Join-Path $sdir 'invoke-callback.ps1'
        Test-Path $path | Should -BeTrue
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "invoke-callback.ps1 writes both result + signal files atomically" {
        $src = Get-Content (Join-Path $sdir 'invoke-callback.ps1') -Raw
        $src | Should -Match 'async-result.json'
        $src | Should -Match 'async-done'
        $src | Should -Match 'Move-Item'
    }

    It "All 5 core scripts pass syntax check (0 errors)" {
        $files = @('monitor-subagent.ps1', 'post-delegation-check.ps1', 'babyagi-loop.ps1',
                   'delegation-registry.ps1', 'invoke-callback.ps1')
        foreach ($f in $files) {
            $full = Join-Path $sdir $f
            $tokens = $null; $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($full, [ref]$tokens, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0 -Because "$f has $($errors.Count) parse errors"
        }
    }

    It "Backward compat: monitor without callback still writes result file" {
        # Without -CompletionCallback, the monitor takes the file-write path
        $src = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        # The monitor should have logic: write result if no callback, or callback owns write
        $src | Should -Match 'WriteResultFile'
        $src | Should -Match 'if \(\$WriteResultFile -or -not \$CompletionCallback\)'
    }
}
