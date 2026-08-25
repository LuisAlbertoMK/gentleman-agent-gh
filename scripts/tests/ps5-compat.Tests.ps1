#requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for PowerShell 5.1 / 7 cross-compatibility of gentleman-vmk setup path.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'PS5/7 Compat — platform.ps1 shim' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $libDir   = Join-Path $repoRoot 'lib'
    }

    It 'T1: platform.ps1 #requires -Version 5.1' {
        $path = Join-Path $libDir 'platform.ps1'
        $head = Get-Content $path -TotalCount 1
        $head | Should -Match '#requires -Version 5\.1'
    }

    It 'T2: platform.ps1 contains $IsLinux / $IsMacOS / $IsWindows shim' {
        $path = Join-Path $libDir 'platform.ps1'
        $content = Get-Content $path -Raw
        $content | Should -Match 'Test-Path Variable:\\IsWindows'
        $content | Should -Match 'Test-Path Variable:\\IsLinux'
        $content | Should -Match 'Test-Path Variable:\\IsMacOS'
        $content | Should -Match 'RuntimeInformation'
    }

    It 'T3: shim guards with -not (Test-Path) so it does not clobber PS7 auto-vars' {
        $path = Join-Path $libDir 'platform.ps1'
        $content = Get-Content $path -Raw
        $content | Should -Match 'if \(-not \(Test-Path Variable:\\IsWindows\)'
        $content | Should -Match 'if \(-not \(Test-Path Variable:\\IsLinux\)'
        $content | Should -Match 'if \(-not \(Test-Path Variable:\\IsMacOS\)'
    }

    It 'T4: platform.ps1 dot-sourced in clean scope defines $Is* + Get-GlobalConfigDir works' {
        $path = Join-Path $libDir 'platform.ps1'
        $job = Start-Job -ScriptBlock {
            param($libPath)
            . $libPath
            [PSCustomObject]@{
                GlobalConfig = Get-GlobalConfigDir
                IsWindows    = $IsWindows
                IsLinux      = $IsLinux
                IsMacOS      = $IsMacOS
            }
        } -ArgumentList $path
        $result = Wait-Job $job | Receive-Job
        Remove-Job $job -Force

        $result.IsWindows      | Should -Be $true
        $result.IsLinux        | Should -Be $false
        $result.IsMacOS        | Should -Be $false
        $result.GlobalConfig   | Should -Match 'opencode'
    }
}

Describe 'PS5/7 Compat — #requires version declarations' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
        $criticalScripts = @(
            'setup-machine.ps1', 'setup-install.ps1', 'gentleman-init.ps1',
            'use-gentleman.ps1', 'sync-vmk.ps1', 'sync-all.ps1'
        )
        $criticalLibs = @(
            'lib\platform.ps1', 'lib\json-utils.ps1', 'lib\template-detection.ps1'
        )
    }

    It 'T5: Critical path scripts declare #requires -Version 5.1' {
        foreach ($script in $criticalScripts) {
            $path = Join-Path $repoRoot $script
            $head = (Get-Content $path -TotalCount 1) -join "`n"
            $head | Should -Match '#requires -Version 5\.1' -Because "$script should be PS5-compatible"
        }
    }

    It 'T6: Critical path libs declare #requires -Version 5.1' {
        foreach ($lib in $criticalLibs) {
            $path = Join-Path $repoRoot $lib
            $head = (Get-Content $path -TotalCount 1) -join "`n"
            $head | Should -Match '#requires -Version 5\.1' -Because "$lib should be PS5-compatible"
        }
    }
}

Describe 'PS5/7 Compat — no @args splatting in critical path' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
    }

    It 'T7: No @args in setup-machine.ps1 and gentleman-init.ps1 (PS7.1+ only)' {
        foreach ($script in @('setup-machine.ps1', 'gentleman-init.ps1')) {
            $path = Join-Path $repoRoot $script
            $content = Get-Content $path -Raw
            ($content -notmatch '@args') | Should -Be $true -Because "$script uses PS5-compatible `$args"
        }
    }

    It 'T8: setup-machine.ps1 shortcut template uses $args not @args' {
        $path = Join-Path $repoRoot 'setup-machine.ps1'
        $content = Get-Content $path -Raw
        $content | Should -Match 'gentleman-vMK \$args'
        $content | Should -Not -Match 'gentleman-vMK @args'
    }

    It 'T9: gentleman-init.ps1 forwards $args (not @args)' {
        $path = Join-Path $repoRoot 'gentleman-init.ps1'
        $content = Get-Content $path -Raw
        $content | Should -Match '\$args'
        $content | Should -Not -Match '@args'
    }
}

Describe 'PS5/7 Compat — gentleman-vmk.bat wrapper' {
    BeforeAll {
        $repoRoot = Split-Path $PSScriptRoot -Parent
    }

    It 'T10: scripts/gentleman-vmk.bat exists' {
        $path = Join-Path $repoRoot 'gentleman-vmk.bat'
        Test-Path $path | Should -Be $true
    }

    It 'T11: gentleman-vmk.bat has pwsh + powershell fallback pattern' {
        $path = Join-Path $repoRoot 'gentleman-vmk.bat'
        $content = Get-Content $path -Raw
        $content | Should -Match 'pwsh\.exe'
        $content | Should -Match 'powershell\.exe'
        $content | Should -Match 'opencode --agent gentleman-vMK'
    }

    It 'T12: setup-machine.ps1 installs .bat shortcut from scripts/$($sc.BatCmd).bat' {
        $path = Join-Path $repoRoot 'setup-machine.ps1'
        $content = Get-Content $path -Raw
        # v2 loop-based shortcuts resolve the source .bat generically via the
        # BatCmd table entry instead of a hardcoded 'gentleman-vmk.bat' string.
        $content | Should -Match ('gentleman-vmk\.bat|BatCmd\s*=\s*[\"'']?gentleman-vmk')
        $content | Should -Match 'sc\.BatCmd'
        $content | Should -Match 'Copy-Item.*srcBat'
    }
}
