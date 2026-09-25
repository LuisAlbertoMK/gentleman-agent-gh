#requires -Version 7
<#
.SYNOPSIS
    E2E validation for opencode.json configuration structure and consistency.
.DESCRIPTION
    Validates:
    - Agent definitions have required fields
    - Permission rules are consistent across modes
    - Skill references are valid
    - No orphaned agent definitions
.NOTES
    Read-only validation, no side effects.
#>

Describe "opencode.json Configuration Validation" {
    BeforeAll {
        $configPath = Join-Path $PSScriptRoot "..\opencode.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    }

    Context "Agent Definitions" {
        It "Contains at least 40 agent definitions" {
            $agentCount = @($config.agent | Get-Member -MemberType NoteProperty).Count
            $agentCount | Should -BeGreaterOrEqual 40
        }

        It "All agents have 'model' field" {
            $agents = $config.agent | Get-Member -MemberType NoteProperty | ForEach-Object { $config.agent.$($_.Name) }
            $agentsWithoutModel = $agents | Where-Object { -not $_.model }
            @($agentsWithoutModel).Count | Should -Be 0
        }

        It "All agents have 'prompt' field or 'instructions'" {
            $agents = $config.agent | Get-Member -MemberType NoteProperty | ForEach-Object { $config.agent.$($_.Name) }
            $agentsWithoutPrompt = $agents | Where-Object { -not ($_.prompt -or $_.instructions) }
            @($agentsWithoutPrompt).Count | Should -Be 0
        }

        It "Orchestrator agent gentle-MK exists (single-mode, no -auto twin)" {
            ($null -ne $config.agent.PSObject.Properties['gentle-MK']) | Should -Be $true
            ($null -eq $config.agent.PSObject.Properties['gentle-MK-auto']) | Should -Be $true
        }

        It "Subagents have 'hidden: true' or 'mode: subagent'" {
            $subagents = @('gentleman-deep-sub', 'gentleman-quick-sub', 'gentleman-codex-sub', 'gentleman-implementer-sub')
            foreach ($name in $subagents) {
                $agent = $config.agent.$name
                if ($agent) {
                    ($agent.hidden -eq $true -or $agent.mode -eq 'subagent') | Should -Be $true
                }
            }
        }
    }

    Context "Permission Rules" {
        It "Defines permission object" {
            $config.permission | Should -Not -BeNullOrEmpty
        }

        It "Permission object has bash rules" {
            $config.permission.bash | Should -Not -BeNullOrEmpty
        }

        It "Has wildcard allow for bash" {
            $config.permission.bash.'*' | Should -Be 'allow'
        }

        It "Git push rules are defined" {
            $config.permission.bash.'git push' | Should -Not -BeNullOrEmpty
            $config.permission.bash.'git push *' | Should -Not -BeNullOrEmpty
        }

        It "Git push --force is asked (strict gentle-ai parity, not denied)" {
            $config.permission.bash.'git push --force *' | Should -Be 'ask'
        }

        It "bash is 1 allow wildcard + 14 asks, 0 denies (gentle-ai parity)" {
            $asks = @($config.permission.bash.PSObject.Properties | Where-Object { $_.Value -eq 'ask' }).Count
            $denies = @($config.permission.bash.PSObject.Properties | Where-Object { $_.Value -eq 'deny' }).Count
            $asks | Should -Be 14
            $denies | Should -Be 0
        }

        It "write/edit permission keys are absent (gentle-ai parity)" {
            ($null -eq $config.permission.PSObject.Properties['write']) | Should -BeTrue
            ($null -eq $config.permission.PSObject.Properties['edit']) | Should -BeTrue
        }

        It "read denies the 13 secret patterns (protection retained)" {
            $secrets = @(
                '*.env', '*.env.*', '**/.env', '**/.env.*', '**/secrets/**',
                '**/credentials.json', '**/.ssh/**', '**/.credentials/**',
                '**/Library/Keychains/**', '**/.aws/credentials',
                '**/.config/gh/hosts.yml', '**/*.pem', '**/*.key'
            )
            $denies = @($config.permission.read.PSObject.Properties | Where-Object { $_.Value -eq 'deny' })
            $denies.Count | Should -Be 13
            foreach ($k in $secrets) { $config.permission.read.$k | Should -Be 'deny' }
        }

        It "no agent carries a bash/read/write/edit delta (inherits global)" {
            $bad = @()
            foreach ($ap in $config.agent.PSObject.Properties) {
                $perm = $ap.Value.PSObject.Properties['permission']
                if ($null -eq $perm) { continue }
                foreach ($k in @('bash', 'read', 'write', 'edit')) {
                    if ($null -ne $perm.Value.PSObject.Properties[$k]) { $bad += "$($ap.Name).$k" }
                }
            }
            ($bad -join ', ') | Should -Be ''
        }
    }

    Context "MCP Configuration" {
        It "Defines MCP servers" {
            $config.mcp | Should -Not -BeNullOrEmpty
        }

        It "Includes context7 MCP server" {
            $config.mcp.context7 | Should -Not -BeNullOrEmpty
        }

        It "Includes engram MCP server" {
            $config.mcp.engram | Should -Not -BeNullOrEmpty
        }

        It "MCP servers have 'command' or 'type' field" {
            $servers = $config.mcp | Get-Member -MemberType NoteProperty | ForEach-Object { $config.mcp.$($_.Name) }
            $serversWithoutCommand = $servers | Where-Object { $null -eq $_.PSObject.Properties['command'] -and $null -eq $_.PSObject.Properties['type'] }
            @($serversWithoutCommand).Count | Should -Be 0
        }
    }

    Context "Consistency Checks" {
        It "No duplicate agent definitions" {
            $agentNames = $config.agent | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $uniqueNames = $agentNames | Select-Object -Unique
            @($agentNames).Count | Should -Be @($uniqueNames).Count
        }

        It "Agent mode variants follow naming convention (-semi, -auto)" {
            $agentNames = $config.agent | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $semiAgents = $agentNames | Where-Object { $_ -match '-semi$' }
            $autoAgents = $agentNames | Where-Object { $_ -match '-auto$' }

            # If there are -semi agents, there should be corresponding base agents
            foreach ($semi in $semiAgents) {
                $base = $semi -replace '-semi$', ''
                $agentNames | Should -Contain $base
            }

            # Single-mode (Refactor-AP S5): the -auto family was deleted (S1) — expect zero.
            @($autoAgents).Count | Should -Be 0
        }

        It "Subagent variants have matching base agents" {
            $agentNames = $config.agent | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $subAgents = $agentNames | Where-Object { $_ -match '-sub(-semi|-auto)?$' }

            foreach ($sub in $subAgents) {
                $base = $sub -replace '-sub(-semi|-auto)?$', '-sub'
                if ($base -ne $sub) {
                    $agentNames | Should -Contain $base
                }
            }
        }
    }
}
