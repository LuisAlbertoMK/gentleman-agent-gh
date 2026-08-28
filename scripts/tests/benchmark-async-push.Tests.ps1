#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'benchmark-async-push.ps1'
}
Describe 'benchmark-async-push.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}
