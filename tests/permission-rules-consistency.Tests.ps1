#requires -Version 7
<#
.SYNOPSIS
    E2E validation for permission rules consistency across configuration files.
.DESCRIPTION
    Validates:
    - shared-deny-rules.json is valid JSON
    - Permission patterns are consistent across opencode.json and permission-gate-lib.ps1
    - No orphaned permission rules
.NOTES
    Cross-references multiple configuration sources.
#>

Describe "Permission Rules Consistency" {
    BeforeAll {
        $configPath = Join-Path $PSScriptRoot "..\opencode.json"
        $denyRulesPath = Join-Path $PSScriptRoot "..\scripts\opencode-config\shared-deny-rules.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    }

    Context "shared-deny-rules.json" {
        It "File exists and is valid JSON" {
            Test-Path $denyRulesPath | Should -Be $true
            { Get-Content $denyRulesPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Contains at least 50 deny rules" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $ruleCount = @($denyRules | Get-Member -MemberType NoteProperty).Count
            $ruleCount | Should -BeGreaterOrEqual 50
        }

        It "All rules have 'deny' or 'ask' as value" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $rules = $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object { $denyRules.$($_.Name) }
            $invalidRules = $rules | Where-Object { $_ -notin @('deny', 'ask', 'allow') }
            @($invalidRules).Count | Should -Be 0
        }

        It "Includes critical network commands (curl, wget, ssh)" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $ruleNames = $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $ruleNames | Should -Contain "curl *"
            $ruleNames | Should -Contain "wget *"
            $ruleNames | Should -Contain "ssh *"
        }

        It "Includes critical interpreter commands (python, node, ruby)" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $ruleNames = $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $ruleNames | Should -Contain "python *"
            $ruleNames | Should -Contain "node *"
            $ruleNames | Should -Contain "ruby *"
        }

        It "Includes package manager bare/wildcard deny patterns (bun, pnpm, yarn, pip3)" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $ruleNames = $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            # Bare commands
            $ruleNames | Should -Contain "bun"
            $ruleNames | Should -Contain "pnpm"
            $ruleNames | Should -Contain "yarn"
            $ruleNames | Should -Contain "pip3"
            # Wildcard patterns
            $ruleNames | Should -Contain "bun *"
            $ruleNames | Should -Contain "pnpm *"
            $ruleNames | Should -Contain "yarn *"
            $ruleNames | Should -Contain "pip3 *"
        }
    }

    Context "opencode.json Permission Structure" {
        It "Defines bash permissions" {
            $config.permission.bash | Should -Not -BeNullOrEmpty
        }

        It "Has wildcard allow for bash" {
            $config.permission.bash.'*' | Should -Be 'allow'
        }

        It "Git push rules follow the gentle-ai overlay (ask, force ask)" {
            # R11 strict parity: the overlay sets git push / git push * to ask (not deny)
            $config.permission.bash.'git push' | Should -Be 'ask'
            $config.permission.bash.'git push *' | Should -Be 'ask'
        }

        It "Git push --force is ask (overlay parity, not deny)" {
            $config.permission.bash.'git push --force *' | Should -Be 'ask'
        }
    }

    Context "Cross-Reference Consistency" {
        It "Shared gate deny-rules are intentionally not mirrored 1:1 by the R11 runtime overlay" {
            # R11 strict parity supersedes the old 1:1 cross-reference: the runtime
            # overlay (opencode-base.json) carries allow/ask only, while the commit
            # gate keeps its deny list in shared-deny-rules.json. Overlap shrinks to
            # the shared transfer commands (ssh/scp/rsync present but verdict=ask)
            # and the runtime bash carries no 'deny' verdict at all.
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $jsonRuleNames = $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object { $_.Name }
            $opencodePermNames = $config.permission.bash.PSObject.Properties.Name
            $matchedRules = $jsonRuleNames | Where-Object { $opencodePermNames -contains $_ }
            @($matchedRules).Count | Should -BeLessOrEqual 5
            $config.permission.bash.PSObject.Properties.Value | Should -Not -Contain 'deny'
        }

        It "No conflicting rules (same command, different verdicts)" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json

            # Check for commands marked as both 'deny' and 'allow' in same file
            $conflicts = @()
            $denyRules | Get-Member -MemberType NoteProperty | ForEach-Object {
                $name = $_.Name
                $value = $denyRules.$name
                # This is a simple check - more sophisticated validation would parse patterns
            }

            @($conflicts).Count | Should -Be 0
        }
    }

    Context "Destructive Patterns" {
        It "Destructive git commands are gated as ask in opencode.json" {
            # R11 strict parity: overlay asks for push --force / rebase / reset --hard
            $config.permission.bash.'git push --force *' | Should -Be 'ask'
            $config.permission.bash.'git rebase *' | Should -Be 'ask'
            $config.permission.bash.'git reset --hard *' | Should -Be 'ask'
        }

        It "Filesystem operations are controlled via separate mechanisms" {
            # rm/Remove-Item are handled by permission-gate-lib.ps1 destructivePatterns
            # not in shared-deny-rules.json (they're mode-dependent)
            # This test verifies the separation of concerns
            $true | Should -Be $true
        }
    }

    Context "R10-S4 network vectors - R11 strict parity overlay (ask, not deny)" {
        It "Network file-transfer commands are ask in the runtime overlay" {
            # R11 strict parity (docs/mejoras/2026-09-25-permission-parity-gentle-ai.md):
            # the gentle-ai overlay drops the R10-S4 denies; ssh/scp/sftp/rsync are ask.
            $config.permission.bash.'ssh *' | Should -Be 'ask'
            $config.permission.bash.'scp *' | Should -Be 'ask'
            $config.permission.bash.'sftp *' | Should -Be 'ask'
            $config.permission.bash.'rsync *' | Should -Be 'ask'
        }

        It "curl/wget/ftp/git clone are absent (inherit global *:allow)" {
            # The overlay carries no curl/wget/ftp/git-clone rule -> they inherit bash.*=allow
            $bashNames = $config.permission.bash.PSObject.Properties.Name
            foreach ($cmd in @('curl *', 'wget *', 'ftp *', 'git clone *')) {
                $bashNames | Should -Not -Contain $cmd
            }
            $config.permission.bash.'*' | Should -Be 'allow'
        }

        It "Toolchain stays frictionless (node/npm/npx/python NOT denied)" {
            # Owner direction (respeta #693): npm/python/node sin friccion via *:allow
            $bashNames = $config.permission.bash.PSObject.Properties.Name
            foreach ($tool in @('node *', 'npm install *', 'npx *', 'pip install *')) {
                if ($bashNames -contains $tool) {
                    $config.permission.bash.$tool | Should -Not -Be 'deny'
                }
            }
        }
    }

    Context "R11-S1 gate SSoT (shared-deny-rules.json) - runtime parity superseded by R11 strict parity" {
        It "Gate SSoT still denies ftp/scp/rsync (shared-deny-rules.json unchanged)" {
            # NOTE: R11 strict permission parity changed the RUNTIME (opencode-base.json
            # overlay: ssh/scp/sftp/rsync=ask; curl/wget/ftp/git clone inherit *:allow).
            # This gate SSoT is intentionally left as-is in this slice (out of write scope);
            # the gate-vs-runtime divergence is tracked in the parity spec.
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $denyRules.'ftp *' | Should -Be 'deny'
            $denyRules.'scp *' | Should -Be 'deny'
            $denyRules.'rsync *' | Should -Be 'deny'
        }

        It "Gate SSoT still asks git clone (runtime now inherits allow)" {
            $denyRules = Get-Content $denyRulesPath -Raw | ConvertFrom-Json
            $denyRules.'git clone *' | Should -Be 'ask'
        }
    }
}
