#requires -Version 7
<#
.SYNOPSIS
    Tests for babyagi-loop.ps1 async push notification (no polling).

    Verifies that BabyAGI's Invoke-TaskAsync uses the push-callback path:
    - Registers task in delegation-registry
    - Creates a temp callback script
    - Passes -CompletionCallback to post-delegation-check
    - Uses FileSystemWatcher + Wait-Event (NOT Start-Sleep polling)
    - Cleans up signal file and temp callback

    Run: Invoke-Pester scripts\tests\babyagi-async-push.Tests.ps1
#>

Describe "BabyAGI async push notification" {
    BeforeAll {
        $root  = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $sdir  = Join-Path $root 'scripts'
        $babyagi = Join-Path $sdir 'babyagi-loop.ps1'
        $src = Get-Content $babyagi -Raw
    }

    It "syntax OK (0 parser errors)" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($babyagi, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "Invoke-TaskAsync registers task in delegation-registry" {
        $src | Should -Match 'delegation-registry'
        $src | Should -Match 'register'
    }

    It "Invoke-TaskAsync creates temp callback script" {
        $src | Should -Match 'callbackScript'
        $src | Should -Match 'gentleman-callback'
        $src | Should -Match 'Set-Content'
    }

    It "Invoke-TaskAsync passes CompletionCallback to post-delegation-check" {
        $src | Should -Match 'CompletionCallback'
        # Must be passed in the PostDelegation invocation, not just defined
        $src | Should -Match '-CompletionCallback \$callbackScript'
    }

    It "Invoke-TaskAsync passes TaskId to post-delegation-check" {
        $src | Should -Match '-TaskId \$taskId'
    }

    It "Invoke-TaskAsync uses FileSystemWatcher (not polling)" {
        $src | Should -Match 'FileSystemWatcher'
        $src | Should -Match 'Register-ObjectEvent'
    }

    It "Invoke-TaskAsync uses Wait-Event for blocking wait (not Start-Sleep loop)" {
        $src | Should -Match 'Wait-Event'
        # Must NOT have the old polling while-loop pattern
        $src | Should -Not -Match 'while \(-not \(Test-Path \$resultFile\)'
    }

    It "Invoke-TaskAsync has 300s timeout on Wait-Event" {
        # $maxWait = 300 sets the timeout; Wait-Event uses -Timeout $maxWait
        ($src -match '\$maxWait\s*=\s*300') | Should -BeTrue
        ($src -match 'Wait-Event.*-Timeout.*\$maxWait') | Should -BeTrue
    }

    It "Invoke-TaskAsync cleans up signal file + temp callback" {
        $src | Should -Match 'Remove-Item.*signalFile'
        $src | Should -Match 'Remove-Item.*callbackScript'
    }

    It "Invoke-TaskAsync uses Join-Path for absolute result file path (not relative)" {
        # The old code used "${taskRef}.async-result.json" (relative)
        # The new code should use Join-Path $RepoRoot for absolute path
        $src | Should -Match 'Join-Path.*RepoRoot.*async-result'
    }

    It "Script resolves RepoRoot and InvokeCallbackScript at module level" {
        $src | Should -Match '\$RepoRoot = Split-Path.*ScriptDir'
        $src | Should -Match '\$InvokeCallbackScript = Join-Path.*ScriptDir.*invoke-callback'
        $src | Should -Match '\$RegistryScript = Join-Path.*ScriptDir.*delegation-registry'
    }

    It "Script has Set-StrictMode -Version Latest" {
        $src | Should -Match 'Set-StrictMode -Version Latest'
    }
}
