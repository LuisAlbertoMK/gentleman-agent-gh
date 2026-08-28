#requires -Version 7

<#
.SYNOPSIS
    Tests for remove-semi-agents.ps1 — removes deprecated *-semi agents from OpenCode config.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'remove-semi-agents.ps1'

    # Helper: create a temp config file with optional semi agents
    function New-TempConfig {
        param(
            [hashtable]$AgentSection = $null
        )
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "remove-semi-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $tempConfig = Join-Path $tempDir "opencodec.json"

        $config = if ($AgentSection) {
            @{ agent = $AgentSection } | ConvertTo-Json -Depth 10
        } else {
            '{}'
        }
        Set-Content -Path $tempConfig -Value $config -Encoding UTF8
        return $tempConfig
    }

    # Helper: read agent property names from config
    function Get-AgentNames {
        param([string]$ConfigPath)
        $cfg = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.PSObject.Properties.Name -notcontains 'agent') {
            return @()
        }
        return $cfg.agent.PSObject.Properties.Name
    }
}

Describe "remove-semi-agents.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        @($errors).Count | Should -Be 0
    }
}

Describe "remove-semi-agents.ps1 — DryRun mode" {
    It "does not modify config in DryRun mode" {
        $semiAgents = @{
            "gentleman-deep-semi"          = @{ type = "extended" }
            "gentleman-quick-semi"         = @{ type = "extended" }
            "gentleman-codex-semi"         = @{ type = "extended" }
            "gentleman-implementer-semi"   = @{ type = "extended" }
            "gentleman-aem-semi"           = @{ type = "extended" }
            "gentleman-vMK-semi"           = @{ type = "extended" }
            "gentleman-deep"               = @{ type = "extended" }
            "gentleman-quick"              = @{ type = "extended" }
        }
        $configPath = New-TempConfig -AgentSection $semiAgents
        try {
            $agentsBefore = Get-AgentNames $configPath
            @($agentsBefore).Count | Should -Be 8

            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath' -DryRun" 2>&1
            $LASTEXITCODE | Should -Be 0

            $agentsAfter = Get-AgentNames $configPath
            @($agentsAfter).Count | Should -Be 8
            $agentsAfter | Should -Contain "gentleman-deep-semi"
            $agentsAfter | Should -Contain "gentleman-deep"
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not create backup in DryRun mode" {
        $configPath = New-TempConfig -AgentSection @{ "gentleman-deep-semi" = @{ type = "extended" } }
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath' -DryRun" 2>&1
            $backup = Get-ChildItem -Path (Split-Path $configPath -Parent) -Filter "*.bak.*" -ErrorAction SilentlyContinue
            $backup | Should -BeNullOrEmpty
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "remove-semi-agents.ps1 — actual removal" {
    It "removes all 6 semi agents but preserves non-semi agents" {
        $semiAgents = @{
            "gentleman-deep-semi"          = @{ type = "extended" }
            "gentleman-quick-semi"         = @{ type = "extended" }
            "gentleman-codex-semi"         = @{ type = "extended" }
            "gentleman-implementer-semi"   = @{ type = "extended" }
            "gentleman-aem-semi"           = @{ type = "extended" }
            "gentleman-vMK-semi"           = @{ type = "extended" }
            "gentleman-deep"               = @{ type = "extended" }
            "gentleman-quick"              = @{ type = "extended" }
            "gentleman-implementer"        = @{ type = "extended" }
        }
        $configPath = New-TempConfig -AgentSection $semiAgents
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath'" 2>&1
            $LASTEXITCODE | Should -Be 0

            $agentsAfter = Get-AgentNames $configPath
            @($agentsAfter).Count | Should -Be 3
            $agentsAfter | Should -Contain "gentleman-deep"
            $agentsAfter | Should -Contain "gentleman-quick"
            $agentsAfter | Should -Contain "gentleman-implementer"
            $agentsAfter | Should -Not -Contain "gentleman-deep-semi"
            $agentsAfter | Should -Not -Contain "gentleman-vMK-semi"
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "creates backup file before removing" {
        $configPath = New-TempConfig -AgentSection @{ "gentleman-deep-semi" = @{ type = "extended" } }
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath'" 2>&1
            $LASTEXITCODE | Should -Be 0
            $backup = Get-ChildItem -Path (Split-Path $configPath -Parent) -Filter "*.bak.*" | Select-Object -First 1
            $backup | Should -Not -BeNullOrEmpty
            $backup.Name | Should -Match 'opencodec\.json\.bak\.\d{8}-\d{6}'
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "remove-semi-agents.ps1 — idempotency" {
    It "exits 0 when no semi agents are present" {
        $configPath = New-TempConfig -AgentSection @{ "gentleman-deep" = @{ type = "extended" } }
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath'" 2>&1
            $LASTEXITCODE | Should -Be 0

            $agents = Get-AgentNames $configPath
            @($agents).Count | Should -Be 1
            $agents | Should -Contain "gentleman-deep"
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "remove-semi-agents.ps1 — error handling" {
    It "exits 1 when config path does not exist" {
        $fakePath = "C:\nonexistent\path\fake-config.json"
        $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$fakePath'" 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It "exits 0 when config has no agent block" {
        $configPath = New-TempConfig
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath'" 2>&1
            $LASTEXITCODE | Should -Be 0
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "remove-semi-agents.ps1 — summary output" {
    It "outputs summary with removed and skipped counts" {
        $semiAgents = @{
            "gentleman-deep-semi"  = @{ type = "extended" }
            "gentleman-deep"      = @{ type = "extended" }
        }
        $configPath = New-TempConfig -AgentSection $semiAgents
        try {
            $output = & pwsh -NoProfile -Command "& '$scriptPath' -ConfigPath '$configPath'" 2>&1
            $joined = ($output | Where-Object { $_ -is [string] }) -join "`n"
            $joined | Should -Match 'Removed: 1 agents'
            $joined | Should -Match 'gentleman-quick-semi'
            $joined | Should -Match 'gentleman-codex-semi'
        }
        finally {
            Remove-Item (Split-Path $configPath -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
