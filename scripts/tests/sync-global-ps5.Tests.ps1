#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-global-ps5.ps1'
    $raw = Get-Content $scriptPath -Raw -EA SilentlyContinue
}
Describe 'sync-global-ps5.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
    It 'contains opencode binary health (ADR-048)' {
        $raw | Should -Match 'opencode binary health'
    }
    It 'contains autoupdate patch' {
        $raw | Should -Match 'autoupdate'
    }
    It 'contains Depth 100' {
        $raw | Should -Match '-Depth 100'
    }
    It 'contains Get-Command pwsh' {
        $raw | Should -Match 'Get-Command pwsh'
    }
    It 'contains no Stop-Process' {
        $raw | Should -Not -Match 'Stop-Process'
    }
    It '$configFiles array does NOT contain opencode.json' {
        $cfgLine = ($raw -split "`n" | Where-Object { $_ -match '\$configFiles\s*=' })
        $cfgLine | Should -Not -Match 'opencode\.json'
    }
    It 'contains bootstrap-only guard pattern' {
        $raw | Should -Match '-not\s*\(Test-Path \$dst\)'
        $idx = $raw.IndexOf('bootstrap-only')
        $idx | Should -BeGreaterThan -1
        $region = $raw.Substring($idx, [Math]::Min(800, $raw.Length - $idx))
        $region | Should -Match '-not\s*\(Test-Path \$dst\)'
    }
    It 'contains bootstrap-only comment marker' {
        $raw | Should -Match 'bootstrap-only'
    }
}
