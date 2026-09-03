#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'update-opencode.ps1'
    $syncPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'sync-global.ps1'
    $raw = Get-Content $scriptPath -Raw -EA SilentlyContinue
    $syncRaw = Get-Content $syncPath -Raw -EA SilentlyContinue
}
Describe 'update-opencode.ps1' {
    It 'exists' {
        Test-Path $scriptPath | Should -BeTrue
    }
    It 'parses without errors' {
        $tokens=$null; $errors=$null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
    It 'contains HealOnly parameter' {
        $raw | Should -Match 'HealOnly'
    }
    It 'contains StopProcesses parameter' {
        $raw | Should -Match 'StopProcesses'
    }
    It 'contains npm prefix -g resolution' {
        $raw | Should -Match 'npm prefix -g'
    }
    It 'guards Stop-Process behind -StopProcesses (no unconditional kill)' {
        $raw | Should -Match 'Stop-Process'
        $raw | Should -Match 'if\s*\(\s*\$StopProcesses\s*\)'
        $unconditional = @([regex]::Matches($raw, '(?m)^\s*Stop-Process'))
        $unconditional.Count | Should -Be 0
        $guarded = [regex]::IsMatch($raw, '(?s)if\s*\(\s*\$StopProcesses\s*\).*?Stop-Process')
        $guarded | Should -BeTrue
    }
    It '-Json -HealOnly runs hermetically against healthy binary (status ok, healed false, version semver)' -Tag 'hermetic' {
        $out = & $scriptPath -HealOnly -Json 2>&1 | Out-String
        $json = $out | ConvertFrom-Json -EA Stop
        $json.status | Should -Be 'ok'
        $json.healed | Should -BeFalse
        $json.after_version | Should -Match '^\d+\.\d+\.\d+'
        $json.PSObject.Properties.Match('postinstall_path').Count | Should -BeGreaterThan 0
        $json.postinstall_path | Should -Match 'postinstall\.mjs$'
    }
}
Describe 'sync-global.ps1 ADR-048 integration' {
    It 'contains autoupdate=false (ADR-048)' {
        $syncRaw | Should -Match 'autoupdate'
    }
    It 'contains opencode binary health step' {
        $syncRaw | Should -Match 'opencode binary health'
    }
    It 'contains opencode_binary report key' {
        $syncRaw | Should -Match 'opencode_binary'
    }
    It 'Step 7 region enforces autoupdate guard and Depth 100 (ADR-048 region-bounded)' {
        $start = $syncRaw.IndexOf('opencode binary health')
        $start | Should -BeGreaterThan -1
        $end = $syncRaw.IndexOf('# Report', $start)
        $end | Should -BeGreaterThan $start
        $region = $syncRaw.Substring($start, $end - $start)
        $region | Should -Match '-or \$gcRaw\.autoupdate -eq \$true'
        $region | Should -Match 'ConvertTo-Json -Depth 100'
    }
}
Describe 'update-opencode.ps1 corrupt-binary heal path' {
    It 'heal path fails and reports manual remediation' {
        $tmpPrefix = Join-Path $env:TEMP "pester-fake-prefix-$(Get-Random)"
        $binDir = Join-Path $tmpPrefix "node_modules/opencode-ai/bin"
        $null = New-Item -ItemType Directory -Path $binDir -Force
        Set-Content -LiteralPath (Join-Path $binDir "opencode.exe") -Value "BADPE" -Encoding ascii -NoNewline
        $postDir = Join-Path $tmpPrefix "node_modules/opencode-ai"
        $null = New-Item -ItemType Directory -Path $postDir -Force -EA SilentlyContinue
        Set-Content -LiteralPath (Join-Path $postDir "postinstall.mjs") -Value "" -Encoding ascii
        $fakeBin = Join-Path $env:TEMP "pester-fakebin-$(Get-Random)"
        $null = New-Item -ItemType Directory -Path $fakeBin -Force
        Set-Content -LiteralPath (Join-Path $fakeBin "npm.cmd") -Value "@echo off`r`necho $tmpPrefix" -Encoding ascii
        Set-Content -LiteralPath (Join-Path $fakeBin "node.cmd") -Value "@echo off`r`nexit /b 0" -Encoding ascii
        $oldPath = $env:PATH; $env:PATH = "$fakeBin;$env:PATH"
        try{
            $out = & $scriptPath -HealOnly -Json 2>&1 | Out-String
            $code = $LASTEXITCODE
            $json = $out | ConvertFrom-Json -EA Stop
            $code | Should -Be 1
            $json.status | Should -Be 'fail'
            $json.healed | Should -BeFalse
            $json.PSObject.Properties.Match('postinstall_path').Count | Should -BeGreaterThan 0
            $json.postinstall_path | Should -Match 'postinstall\.mjs$'
            ($json.errors -join "`n") | Should -Match 'manual remediation'
        } finally { $env:PATH = $oldPath }
    }
    It 'timeout wrapper present' {
        $raw | Should -Match 'Wait-Job'
        $raw | Should -Match '-Timeout 180'
        $unconditional = @([regex]::Matches($raw, '(?m)^\s*Stop-Process'))
        $unconditional.Count | Should -Be 0
        $raw | Should -Match 'Stop-Job'
        $raw | Should -Not -Match '(?m)^\s*Stop-Process'
    }
}
