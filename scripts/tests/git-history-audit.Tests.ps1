#requires -Version 5.1
<#
.SYNOPSIS
    Pester tests that scan git commit history for leaked credential literals.
.DESCRIPTION
    Uses `git log --all --diff-filter=A -p` to inspect every file-addition diff
    for hardcoded credential patterns. Known test fixtures and documentation
    examples are allowlisted. FAIL = real literal found in history.
.NOTES
    Gap: no existing Pester test scans git history for credential leaks.
    ODD Tier HIGH Cluster C.
    Patterns derived from scripts/verify.ps1:64-66 (canonical source).
#>
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'git-history-audit — credential pattern scan' {
    BeforeAll {
        $script:RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

        # Credential patterns — narrowed to catch real assignments, not variable names
        # (canonical: scripts/verify.ps1:64-66, adapted for git-history scope)
        $script:Patterns = @(
            'password\s*=\s*[''"`]',           # password = "..." (quoted value)
            'secret\s*=\s*[''"`]',             # secret = "..." (quoted value)
            'api[_-]?key\s*=\s*[''"`]',        # api_key = "..." (quoted value)
            'token\s*=\s*[''"`]',              # token = "..." (quoted value — not Token == "")
            'connection\s*string\s*=\s*[''"`]', # connection string = "..."
            'GH_TOKEN\s*=\s*[''"`<]',          # GH_TOKEN = "..." or GH_TOKEN=<...
            'GITHUB_TOKEN\s*=\s*[''"`<]',      # GITHUB_TOKEN = "..." or GITHUB_TOKEN=<...
            'ghp_[A-Za-z0-9]{10,}',            # GitHub PAT prefix with content
            'gho_[A-Za-z0-9]{10,}',            # GitHub OAuth prefix with content
            'ghs_[A-Za-z0-9]{10,}',            # GitHub Server-to-Server prefix
            'github_pat_[A-Za-z0-9]{10,}',     # GitHub fine-grained PAT prefix
            'ctx7sk_[A-Za-z0-9]{10,}',         # Context7 secret key prefix
            'AKIA[0-9A-Z]{10,}',               # AWS Access Key ID
            'xox[abprs]-[A-Za-z0-9]{10,}',     # Slack token prefix
            'sk-[a-zA-Z0-9]{20,}',             # OpenAI secret key
            '-----BEGIN\s+(RSA|EC|DSA|PRIVATE|OPENSSH)\s+KEY' # PEM private key
        )

        # Path-based allowlist — suppress known documentation / test / scanning-impl noise
        $script:AllowlistPaths = @(
            '\.md$',                            # markdown documentation
            'test',                             # _test.go, tests/, test/, etc.
            'example',
            'placeholder',
            'sample',
            'bench',                            # benchmark / synthetic credential files
            'e2e',                              # end-to-end test files
            '\.githooks',                       # git hook scanning implementations
            '\.github',                         # workflow files (often contain placeholder tokens)
            '\.gitleaks',                       # gitleaks config (defines patterns, not secrets)
            '\.pre-commit',                     # pre-commit config (defines patterns)
            'internal/assets/opencode/plugins'  # plugin files with route tokens
        )

        # File-based allowlist — files that IMPLEMENT or DEFINE credential scanning
        # (self-referential: these files contain the patterns as regex definitions)
        $script:AllowlistFiles = @(
            'check-mcp-security\.ps1$',
            'verify\.ps1$',
            'security-audit-mcp\.ps1$',
            'main\.go$',                        # cmd/gate/main.go, cmd/fast/main.go
            'detect\.go$'                       # internal/system/detect.go (LinuxDistro token)
        )

        # Commit-based allowlist: documented sample commits
        $script:AllowlistCommits = @(
            'd527b68'  # authToken sample — process.env.TURSO_TOKEN (documentation)
        )

        # Specific file:line allowlist (commit-agnostic)
        $script:AllowlistFileLines = @(
            @{ File = 'verify\.Tests\.ps1$'; Pattern = 'password=supersecret' }
        )

        # ---- Scan ----
        Push-Location $script:RepoRoot
        try {
            $commitCount = (& git rev-list --all --count 2>&1)
            $script:CommitCount = [int]$commitCount

            $raw = & git log --all --diff-filter=A -p --no-merges 2>&1 | Out-String
        }
        finally { Pop-Location }

        # Parse diffs into raw findings (before allowlist)
        $script:RawFindings = [System.Collections.ArrayList]::new()
        $lines = $raw -split "`n"
        $currentFile = ''
        $currentCommit = ''
        $inAddedHunk = $false

        foreach ($line in $lines) {
            if ($line -match '^commit\s+([0-9a-f]{7,40})') {
                $currentCommit = $Matches[1]
                $inAddedHunk = $false
            }
            elseif ($line -match '^\+\+\+\s+b/(.*)') {
                $currentFile = $Matches[1].Trim()
            }
            elseif ($line -match '^diff --git') {
                $inAddedHunk = $false
            }
            elseif ($line -match '^@@') {
                $inAddedHunk = $true
            }
            elseif ($inAddedHunk -and $line -match '^\+(.+)') {
                $addedLine = $Matches[1]
                foreach ($pat in $script:Patterns) {
                    if ($addedLine -match $pat) {
                        [void]$script:RawFindings.Add(@{
                            Commit  = $currentCommit
                            File    = $currentFile
                            Line    = $addedLine.Trim()
                            Pattern = $pat
                        })
                        break  # one match per line is enough
                    }
                }
            }
        }

        # ---- Apply allowlist → final filtered findings ----
        $script:FilteredFindings = @($script:RawFindings | Where-Object {
            $f = $_.File
            $allowed = $false

            # Path allowlist (substring match)
            foreach ($ap in $script:AllowlistPaths) {
                if ($f -match $ap) { $allowed = $true; break }
            }

            # File-based allowlist (scanning implementations)
            if (-not $allowed) {
                foreach ($af in $script:AllowlistFiles) {
                    if ($f -match $af) { $allowed = $true; break }
                }
            }

            # Commit allowlist
            if (-not $allowed) {
                foreach ($ac in $script:AllowlistCommits) {
                    if ($_.Commit -like "$ac*") { $allowed = $true; break }
                }
            }

            # File:line allowlist
            if (-not $allowed) {
                foreach ($fl in $script:AllowlistFileLines) {
                    if ($f -match $fl.File -and $_.Line -match $fl.Pattern) {
                        $allowed = $true; break
                    }
                }
            }

            -not $allowed
        })
    }

    It 'scans full git history (>=1 commit)' {
        $script:CommitCount | Should -BeGreaterThan 0
    }

    It 'detects pattern matches in git history (raw)' {
        # Sanity: the scan actually found something to filter
        # If zero raw matches, the allowlist tests below are vacuous
        $script:RawFindings.Count | Should -BeGreaterThan 0
    }

    Context 'allowlist filtering' {
        It 'suppresses all .md documentation findings' {
            $mdRaw = @($script:RawFindings | Where-Object { $_.File -match '\.md$' })
            $mdFiltered = @($script:FilteredFindings | Where-Object { $_.File -match '\.md$' })
            $mdRaw.Count | Should -BeGreaterThan 0   # .md files DO have pattern matches
            $mdFiltered.Count | Should -Be 0          # but they are ALL suppressed
        }

        It 'suppresses all test/example/placeholder/sample findings' {
            $noiseRaw = @($script:RawFindings | Where-Object {
                $f = $_.File
                @($script:AllowlistPaths | Where-Object { $f -match $_ }).Count -gt 0
            })
            $noiseFiltered = @($script:FilteredFindings | Where-Object {
                $f = $_.File
                @($script:AllowlistPaths | Where-Object { $f -match $_ }).Count -gt 0
            })
            $noiseRaw.Count | Should -BeGreaterThan 0
            $noiseFiltered.Count | Should -Be 0
        }

        It 'suppresses scanning-implementation files (if any match)' {
            # Scanning impl files may or may not have raw matches depending on pattern
            # specificity. Verify: any that DO match are suppressed.
            $implFiltered = @($script:FilteredFindings | Where-Object {
                $f = $_.File
                ($script:AllowlistFiles | Where-Object { $f -match $_ }).Count -gt 0
            })
            $implFiltered.Count | Should -Be 0
        }
    }

    Context 'real credential detection' {
        It 'finds ZERO unallowlisted credential literals in git history' {
            if ($script:FilteredFindings.Count -gt 0) {
                $detail = ($script:FilteredFindings | ForEach-Object {
                    "  $($_.Commit.Substring(0,7)) $($_.File): $($_.Line.Substring(0, [Math]::Min(100, $_.Line.Length)))"
                }) -join "`n"
                Write-Warning "Unallowlisted credential literals found in git history:`n$detail"
            }

            $script:FilteredFindings.Count | Should -Be 0
        }
    }
}
