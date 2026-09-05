#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-global.ps1'
}
Describe 'sync-global.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
    It 'propagates skills from project config (drift C-a)' {
        $c = Get-Content $scriptPath -Raw
        $c | Should -Match '\$cfg\.skills'
        $c | Should -Match '\.agents/skills'
    }
    It 'propagates full permission map incl write+edit (drift C-b)' {
        $c = Get-Content $scriptPath -Raw
        $c | Should -Match "Match\('permission'\)"
        $c | Should -Match '\$cfg\.permission=\$pc'
    }
    It 'prunes *-semi agents absent from canonical (drift C-c)' {
        $c = Get-Content $scriptPath -Raw
        $c | Should -Match "-like '\*-semi'"
        $c | Should -Match 'Properties\.Remove'
    }
}
