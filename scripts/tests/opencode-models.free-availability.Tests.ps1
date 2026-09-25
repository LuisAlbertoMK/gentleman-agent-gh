#requires -Version 7

<#
.SYNOPSIS
    Tests for upstream v3.7.0 adapted — editable general/explore models
    with fallback to defaults when the saved model does not exist.
#>

BeforeAll {
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $canonicalPath = Join-Path $repoRoot 'opencode.json'
    $config = Get-Content -LiteralPath $canonicalPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # Mirrors the fallback check in scripts/check-config-drift.ps1:
    # a saved model that is missing or unresolvable falls back to the
    # default without failing.
    # Single-model (ADR-050): opencode.json no longer carries
    # models.general / models.explore / reviewer.fallback keys; the drift
    # script tolerates their absence and falls back to its hardcoded
    # $modelFallbackDefault. The test reads that default from the drift
    # script so both stay in sync.
    $driftScript = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\check-config-drift.ps1') -Raw -Encoding UTF8
    $m = [regex]::Match($driftScript, '\$modelFallbackDefault\s*=\s*"([^"]+)"')
    if (-not $m.Success) { throw "contract: check-config-drift.ps1 no longer defines `$modelFallbackDefault" }
    $driftDefault = $m.Groups[1].Value

    $reviewerFallback = $null
    if (($null -ne $config.PSObject.Properties['reviewer']) -and ($null -ne $config.reviewer.PSObject.Properties['fallback'])) {
        $reviewerFallback = $config.reviewer.fallback
    }
    $effectiveDefault = if ([string]::IsNullOrWhiteSpace($reviewerFallback)) { $driftDefault } else { $reviewerFallback }

    function Resolve-ModelWithFallback {
        param([string]$Saved, [string[]]$Available, [string]$Default)
        if ([string]::IsNullOrWhiteSpace($Saved)) { return $Default }
        if ($Available -notcontains $Saved) { return $Default }
        return $Saved
    }
}

Describe "opencode-models free availability — general/explore fallback" {
    It "general falls back to effective default (reviewer.fallback removed per ADR-050; drift-script default) when the assigned model does not exist" {
        $effectiveDefault | Should -Not -BeNullOrEmpty
        $available = @($config.model, $effectiveDefault)
        $resolved = Resolve-ModelWithFallback -Saved 'opencode/does-not-exist-general-xyz' -Available $available -Default $effectiveDefault
        $resolved | Should -Be $effectiveDefault
    }

    It "explore falls back to effective default (reviewer.fallback removed per ADR-050; drift-script default) when the assigned model does not exist" {
        $effectiveDefault | Should -Not -BeNullOrEmpty
        $available = @($config.model, $effectiveDefault)
        $resolved = Resolve-ModelWithFallback -Saved 'opencode/does-not-exist-explore-xyz' -Available $available -Default $effectiveDefault
        $resolved | Should -Be $effectiveDefault
    }
}
