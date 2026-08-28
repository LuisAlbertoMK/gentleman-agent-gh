#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'score-auto.ps1'
}
Describe 'score-auto.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}
