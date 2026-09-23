#requires -Version 7
<#
.SYNOPSIS
    Pester suite for scripts/security-audit-mcp.ps1 (P0-2 Slice 1).
.DESCRIPTION
    Pins audit behavior: SSRF allowlist, secret scan, version pin,
    CBM_ALLOWED_ROOT scoping, disabled hygiene, and repo non-mutation.
    Hermetic per GAP-4: GUID sandbox fixtures, GIT_* strip, PESTER_TEST=1.
.NOTES
    P0-2 (id:857) Slice 1 — tests-only slice over behavior from feb0a4f8.
    The audit script resolves its config from <sandbox>/opencode.json
    when copied to <sandbox>/scripts/, so fixtures never touch the repo.
#>

Describe "security-audit-mcp.ps1 (P0-2)" {
    BeforeAll {
        $script:AuditPath = Join-Path (Join-Path $PSScriptRoot ".." "scripts") "security-audit-mcp.ps1"
        $script:OldPesterTest = $env:PESTER_TEST
        $env:PESTER_TEST = "1"
        $script:StashedGit = @{}
        foreach ($v in @("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")) {
            if (Test-Path "env:$v") {
                $script:StashedGit[$v] = (Get-Item "env:$v").Value
                Remove-Item "env:$v"
            }
        }
        $script:Sandbox = Join-Path ([IO.Path]::GetTempPath()) ("mcp-audit-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path (Join-Path $script:Sandbox "scripts") -Force | Out-Null
        Copy-Item -LiteralPath $script:AuditPath -Destination (Join-Path $script:Sandbox "scripts" "security-audit-mcp.ps1")

        function New-FixtureConfig([hashtable]$Mcp) {
            # Baseline satisfies the audit script's StrictMode direct property
            # reads (codebase-memory-mcp, engram); the case under test merges over it.
            $merged = @{
                "codebase-memory-mcp"   = @{ enabled = $true; type = "local"; command = @("codebase-memory-mcp"); environment = @{ CBM_ALLOWED_ROOT = "{env:GENTLEMAN_AGENT_ROOT}" } }
                "engram"                = @{ enabled = $true; type = "local"; command = @("engram") }
                "headroom"              = @{ enabled = $false; type = "local"; command = @("node", "headroom.js") }
                "chrome-devtools-mcp"   = @{ enabled = $false; type = "local"; command = @("npx", "-y", "chrome-devtools-mcp@1.6.0", "--no-usage-statistics") }
            }
            foreach ($k in $Mcp.Keys) { $merged[$k] = $Mcp[$k] }
            $obj = [pscustomobject]@{ mcp = [pscustomobject]$merged }
            $obj | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $script:Sandbox "opencode.json") -Encoding utf8
        }
        function Invoke-FixtureAudit {
            # *>&1: audit reports via Write-Host (information stream), not stdout
            $out = & (Join-Path $script:Sandbox "scripts" "security-audit-mcp.ps1") *>&1
            return ($out -join "`n")
        }
    }
    AfterAll {
        if ($null -ne $script:OldPesterTest) { $env:PESTER_TEST = $script:OldPesterTest } else { Remove-Item "env:PESTER_TEST" -ErrorAction SilentlyContinue }
        foreach ($kv in $script:StashedGit.GetEnumerator()) { Set-Item "env:$($kv.Key)" $kv.Value }
        if (Test-Path -LiteralPath $script:Sandbox) { Remove-Item -LiteralPath $script:Sandbox -Recurse -Force }
    }

    Context "Behavior pins (static)" {
        BeforeAll {
            $script:Src = Get-Content -LiteralPath $script:AuditPath -Raw
        }

        It "Audit script exists" {
            Test-Path -LiteralPath $script:AuditPath | Should -Be $true
        }

        It "Declares the SSRF allowlist with the context7 url" {
            $script:Src | Should -Match "https://mcp\.context7\.com/mcp"
        }

        It "Scans env values with a secret pattern" {
            $script:Src | Should -Match "secret\|token\|password"
        }

        It "Excludes scope roots from the secret scan" {
            $script:Src | Should -Match "CBM_ALLOWED_ROOT"
        }

        It "Requires npx @version pins (supply-chain)" {
            $script:Src | Should -Match "@version pin"
        }

        It "Fails closed on filesystem-root scoping" {
            $script:Src | Should -Match "filesystem root"
        }

        It "Declares never-mutates semantics (PESTER_TEST-aware)" {
            $script:Src | Should -Match "never mutates"
        }
    }

    Context "SSRF remote allowlist (hermetic fixtures)" {
        It "FAILS a non-allowlisted remote url" {
            New-FixtureConfig @{ "evil-remote" = @{ enabled = $true; type = "remote"; url = "https://evil.example.com/mcp" } }
            Invoke-FixtureAudit | Should -Match "NOT allowlisted"
        }

        It "PASSES the allowlisted context7 url" {
            New-FixtureConfig @{ "ctx7" = @{ enabled = $true; type = "remote"; url = "https://mcp.context7.com/mcp" } }
            Invoke-FixtureAudit | Should -Match "allowlisted"
        }

        It "PASSES with no remote-enabled servers" {
            New-FixtureConfig @{ "local-only" = @{ enabled = $true; type = "local"; command = @("node", "srv.js") } }
            Invoke-FixtureAudit | Should -Match "SSRF surface: none"
        }
    }

    Context "Secret scan and version pin (hermetic fixtures)" {
        It "WARNS on a secret-looking env value" {
            New-FixtureConfig @{ "leaky" = @{ enabled = $true; type = "local"; command = @("node", "srv.js"); environment = @{ API_KEY = "sk-live-abc123" } } }
            Invoke-FixtureAudit | Should -Match "looks like a secret"
        }

        It "Does NOT warn on scope-root placeholders" {
            New-FixtureConfig @{ "scoped" = @{ enabled = $true; type = "local"; command = @("node", "srv.js"); environment = @{ PATH_HINT = "GENTLEMAN_AGENT_ROOT api_key placeholder" } } }
            Invoke-FixtureAudit | Should -Not -Match "looks like a secret"
        }

        It "FAILS npx without a version pin" {
            New-FixtureConfig @{ "unpinned" = @{ enabled = $true; type = "local"; command = @("npx", "-y", "some-pkg") } }
            Invoke-FixtureAudit | Should -Match "without @version pin"
        }

        It "PASSES npx with a version pin" {
            New-FixtureConfig @{ "pinned" = @{ enabled = $true; type = "local"; command = @("npx", "-y", "some-pkg@1.2.3") } }
            Invoke-FixtureAudit | Should -Match "version pinned"
        }

        It "FAILS CBM_ALLOWED_ROOT resolving to filesystem root" {
            New-FixtureConfig @{ "codebase-memory-mcp" = @{ enabled = $true; type = "local"; command = @("codebase-memory-mcp"); environment = @{ CBM_ALLOWED_ROOT = "C:\" } } }
            Invoke-FixtureAudit | Should -Match "filesystem root"
        }
    }

    Context "Disabled hygiene (hermetic fixtures)" {
        It "PASSES a disabled risky server" {
            New-FixtureConfig @{ "headroom" = @{ enabled = $false; type = "local"; command = @("node", "headroom.js") } }
            Invoke-FixtureAudit | Should -Match "disabled \(correct"
        }

        It "WARNS on an enabled risky server" {
            New-FixtureConfig @{ "headroom" = @{ enabled = $true; type = "local"; command = @("node", "headroom.js") } }
            Invoke-FixtureAudit | Should -Match "ENABLED"
        }
    }

    Context "Live repo audit (read-only)" {
        It "PASSes on the real opencode.json with exit 0" {
            git --version | Out-Null
            $out = & $script:AuditPath *>&1
            $LASTEXITCODE | Should -Be 0
            ($out -join "`n") | Should -Match "Result: PASS"
        }

        It "Does not mutate .project.json or history.jsonl (GAP-4)" {
            $before = git status --porcelain -- ".project.json" "docs/metricas/history.jsonl"
            & $script:AuditPath | Out-Null
            $after = git status --porcelain -- ".project.json" "docs/metricas/history.jsonl"
            $after | Should -Be $before
        }
    }
}
