#requires -Version 7
<#
.SYNOPSIS
    Unit tests for mejoras-index-check.ps1 freshness gate.
.DESCRIPTION
    Tests candidate discovery, README substring matching, exclusion list,
    fail-closed paths, exit codes, and -Json output structure.
.NOTES
    All fixtures built under $TestDrive; -MejorasDir passed explicitly.
#>

Describe "mejoras-index-check.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot "..\scripts\mejoras-index-check.ps1"
    }

    Context "Happy path — all candidates indexed" {
        BeforeAll {
            $dir = Join-Path $TestDrive "happy"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir "README.md") -Value @"
# Index
| Doc | Status |
|-----|--------|
| alpha.md | done |
| beta.md  | done |
"@
            Set-Content -Path (Join-Path $dir "alpha.md") -Value "# Alpha"
            Set-Content -Path (Join-Path $dir "beta.md") -Value "# Beta"
        }

        It "Exits 0 when every candidate appears in README" {
            $null = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 0
        }

        It "Prints OK summary line" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $output = $result | Out-String
            $output | Should -Match "OK\s+2/2 analysis docs indexed"
        }
    }

    Context "Missing candidate — NOT INDEXED" {
        BeforeAll {
            $dir = Join-Path $TestDrive "missing"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir "README.md") -Value @"
# Index
| alpha.md | done |
"@
            Set-Content -Path (Join-Path $dir "alpha.md") -Value "# Alpha"
            Set-Content -Path (Join-Path $dir "gamma.md") -Value "# Gamma"
        }

        It "Exits 1 when a candidate is missing from README" {
            $null = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Prints NOT INDEXED line for the missing file" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $output = $result | Out-String
            $output | Should -Match "NOT INDEXED:\s+gamma\.md"
        }
    }

    Context "Exclusion list — only excluded files present" {
        BeforeAll {
            $dir = Join-Path $TestDrive "excluded"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir "README.md") -Value "# Top-level readme"
            Set-Content -Path (Join-Path $dir "plan-template.md") -Value "# Template"
            Set-Content -Path (Join-Path $dir "mejora-log.md") -Value "# Log"
        }

        It "Exits 0 with total 0 when all files are excluded" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 0
            $output = $result | Out-String
            $output | Should -Match "0/0 analysis docs indexed"
        }
    }

    Context "Fail-closed — directory does not exist" {
        BeforeAll {
            $dir = Join-Path $TestDrive "nonexistent-dir-$(Get-Random)"
        }

        It "Exits 1 when MejorasDir is missing" {
            $null = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Prints FAIL line mentioning the directory" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $output = $result | Out-String
            $output | Should -Match "FAIL.*directory not found"
        }
    }

    Context "Fail-closed — README.md missing but docs exist" {
        BeforeAll {
            $dir = Join-Path $TestDrive "no-readme"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir "alpha.md") -Value "# Alpha"
            Set-Content -Path (Join-Path $dir "beta.md") -Value "# Beta"
        }

        It "Exits 1 when README.md is absent" {
            $null = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 1
        }

        It "Prints FAIL line mentioning README.md" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $output = $result | Out-String
            $output | Should -Match "FAIL.*README\.md not found"
        }
    }

    Context "-Json output structure" {
        BeforeAll {
            $dir = Join-Path $TestDrive "json-ok"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir "README.md") -Value @"
# Index
| alpha.md | done |
"@
            Set-Content -Path (Join-Path $dir "alpha.md") -Value "# Alpha"
        }

        It "Emits parseable JSON with correct fields when all indexed" {
            $result = & $scriptPath -MejorasDir $dir -Json *>&1
            $output = $result | Out-String
            $json = $output | ConvertFrom-Json
            $json.indexed | Should -Be 1
            $json.total   | Should -Be 1
            $json.missing | Should -BeNullOrEmpty
            $json.valid   | Should -BeTrue
        }

        It "Emits parseable JSON with missing list when not all indexed" {
            $dir2 = Join-Path $TestDrive "json-miss"
            New-Item -Path $dir2 -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $dir2 "README.md") -Value "# Empty"
            Set-Content -Path (Join-Path $dir2 "lonely.md") -Value "# Lonely"

            $result = & $scriptPath -MejorasDir $dir2 -Json *>&1
            $output = $result | Out-String
            $json = $output | ConvertFrom-Json
            $json.indexed | Should -Be 0
            $json.total   | Should -Be 1
            $json.missing | Should -Contain "lonely.md"
            $json.valid   | Should -BeFalse
        }

        It "Emits fail-closed JSON when directory is missing" {
            $dir3 = Join-Path $TestDrive "json-nodir-$(Get-Random)"
            $result = & $scriptPath -MejorasDir $dir3 -Json *>&1
            $output = $result | Out-String
            $json = $output | ConvertFrom-Json
            $json.indexed | Should -Be 0
            $json.total   | Should -Be 0
            $json.valid   | Should -BeFalse
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context "Substring detection — backtick-wrapped filenames in table rows" {
        BeforeAll {
            $dir = Join-Path $TestDrive "backtick"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            # Single-quoted here-string to preserve literal backticks
            Set-Content -Path (Join-Path $dir "README.md") -Value @'
# Index

| Document | Description |
|----------|-------------|
| `alpha.md` | Analysis of alpha |
| `beta.md`  | Analysis of beta  |
'@
            Set-Content -Path (Join-Path $dir "alpha.md") -Value "# Alpha"
            Set-Content -Path (Join-Path $dir "beta.md") -Value "# Beta"
        }

        It "Exits 0 — backtick-wrapped filenames are matched" {
            $null = & $scriptPath -MejorasDir $dir *>&1
            $LASTEXITCODE | Should -Be 0
        }

        It "Prints OK summary confirming both docs indexed" {
            $result = & $scriptPath -MejorasDir $dir *>&1
            $output = $result | Out-String
            $output | Should -Match "OK\s+2/2 analysis docs indexed"
        }
    }
}
