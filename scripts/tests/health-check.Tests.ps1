#requires -Version 5.1
<#
.SYNOPSIS
    Pester tests for health-check.ps1 — Test-Junction and Repair-Junction.
    Uses temp directories and real junctions for filesystem-level testing.
.NOTES
    ponytail: filesystem tests — uses temp dirs, cleaned up after.
    Functions defined inline (Pester v6 BeforeAll scoping).
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    # Define functions inline (same logic as health-check.ps1 L63-114)
    # This avoids dot-sourcing the script which runs main code (junction checks, cache writes).

    function Test-Junction {
        param([string]$Path, [string]$ExpectedTarget, [string]$Label)
        $result = @{check = $Label; status = "OK"; detail = ""}
        if (Test-Path $Path) {
            $item = Get-Item -LiteralPath $Path -Force
            if ($item.LinkType -ne "Junction") {
                $result.status = "WARN"
                $result.detail = "Exists but not a junction (real file/dir)"
                return $result
            }
            if (-not (Test-Path $item.Target)) {
                $result.status = "FAIL"
                $result.detail = "Target missing: $($item.Target)"
                return $result
            }
            if ($item.Target -ne (Resolve-Path $ExpectedTarget).Path) {
                $result.status = "WARN"
                $result.detail = "Target mismatch: $($item.Target) → expected $ExpectedTarget"
                return $result
            }
            $result.detail = "$($item.Target) OK"
        } else {
            $result.status = "FAIL"
            $result.detail = "Missing"
        }
        return $result
    }

    function Repair-Junction {
        param([string]$Path, [string]$Target, [string]$Label)
        if (Test-Path $Path) {
            $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
            if ($item -and $item.LinkType -eq 'Junction') {
                Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue
            } elseif ($item -and $item.LinkType) {
                Write-Warning "[repair] skipping $($Path): existing LinkType $($item.LinkType) is not Junction"
                if (-not $Quiet) { Write-Output "[skipped] $Label (not a junction)" }
                return
            }
            elseif ($item) {
                Write-Warning "[repair] refusing to remove $($Path): real entry, not a junction"
                if (-not $Quiet) { Write-Output "[refused] $Label (real entry)" }
                return
            }
        }
        $parent = Split-Path $Path -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null
        if (-not $Quiet) { Write-Output "[repair] $Label → $Target" }
    }
}

# ============================================================
Describe 'Test-Junction' {
    BeforeAll {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "pester-healthcheck-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        $script:targetDir = Join-Path $script:tempRoot "target"
        New-Item -ItemType Directory -Path $script:targetDir -Force | Out-Null
        Set-Content -Path (Join-Path $script:tempRoot "target\file.txt") -Value "test"

        $script:junctionDir = Join-Path $script:tempRoot "junction"
        New-Item -ItemType Junction -Path $script:junctionDir -Target $script:targetDir -Force | Out-Null

        $script:realDir = Join-Path $script:tempRoot "real-dir"
        New-Item -ItemType Directory -Path $script:realDir -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $script:tempRoot) {
            Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns OK for a valid junction with correct target' {
        $result = Test-Junction -Path $script:junctionDir -ExpectedTarget $script:targetDir -Label "test-junction"
        $result.status | Should -Be "OK"
        $result.check | Should -Be "test-junction"
    }

    It 'returns FAIL for a missing path' {
        $missing = Join-Path $script:tempRoot "nonexistent"
        $result = Test-Junction -Path $missing -ExpectedTarget $script:targetDir -Label "missing"
        $result.status | Should -Be "FAIL"
        $result.detail | Should -Be "Missing"
    }

    It 'returns WARN for a real directory (not a junction)' {
        $result = Test-Junction -Path $script:realDir -ExpectedTarget $script:targetDir -Label "real-dir"
        $result.status | Should -Be "WARN"
        $result.detail | Should -Match "not a junction"
    }

    It 'returns WARN for a junction with wrong target' {
        $wrongTarget = Join-Path $script:tempRoot "wrong-target"
        New-Item -ItemType Directory -Path $wrongTarget -Force | Out-Null
        $result = Test-Junction -Path $script:junctionDir -ExpectedTarget $wrongTarget -Label "wrong-target"
        $result.status | Should -Be "WARN"
        $result.detail | Should -Match "mismatch"
    }

    It 'returns the label in the result' {
        $result = Test-Junction -Path $script:junctionDir -ExpectedTarget $script:targetDir -Label "my-label"
        $result.check | Should -Be "my-label"
    }
}

# ============================================================
Describe 'Repair-Junction' {
    BeforeAll {
        $script:tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "pester-repair-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:tempRoot -Force | Out-Null

        $script:targetDir = Join-Path $script:tempRoot "target"
        New-Item -ItemType Directory -Path $script:targetDir -Force | Out-Null
    }

    AfterAll {
        if (Test-Path $script:tempRoot) {
            Remove-Item -Path $script:tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'creates a junction when path does not exist' {
        $junctionPath = Join-Path $script:tempRoot "new-junction"
        Repair-Junction -Path $junctionPath -Target $script:targetDir -Label "new"
        Test-Path $junctionPath | Should -Be $true
        [System.IO.Directory]::Exists($junctionPath) | Should -Be $true
    }

    It 'replaces an existing broken junction' {
        $brokenPath = Join-Path $script:tempRoot "broken-junction"
        $tempTarget = Join-Path $script:tempRoot "temp-target"
        New-Item -ItemType Directory -Path $tempTarget -Force | Out-Null
        New-Item -ItemType Junction -Path $brokenPath -Target $tempTarget -Force | Out-Null
        Remove-Item -Path $tempTarget -Recurse -Force

        Repair-Junction -Path $brokenPath -Target $script:targetDir -Label "fixed"
        Test-Path $brokenPath | Should -Be $true
        [System.IO.Directory]::Exists($brokenPath) | Should -Be $true
    }

    It 'skips if path is a real directory (not a junction)' {
        $realDir = Join-Path $script:tempRoot "real-entry"
        New-Item -ItemType Directory -Path $realDir -Force | Out-Null

        { Repair-Junction -Path $realDir -Target $script:targetDir -Label "safe-skip" } | Should -Not -Throw
        Test-Path $realDir | Should -Be $true
    }
}
