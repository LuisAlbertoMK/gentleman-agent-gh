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
    function Resolve-ModelWithFallback {
        param([string]$Saved, [string[]]$Available, [string]$Default)
        if ([string]::IsNullOrWhiteSpace($Saved)) { return $Default }
        if ($Available -notcontains $Saved) { return $Default }
        return $Saved
    }
}

Describe "opencode-models free availability — general/explore fallback" {
    It "general falls back to reviewer.fallback default when the assigned model does not exist" {
        $default = $config.reviewer.fallback
        $default | Should -Not -BeNullOrEmpty
        $available = @($config.model, $config.models.general, $config.models.explore, $config.reviewer.fallback)
        $resolved = Resolve-ModelWithFallback -Saved 'opencode/does-not-exist-general-xyz' -Available $available -Default $default
        $resolved | Should -Be $default
    }

    It "explore falls back to reviewer.fallback default when the assigned model does not exist" {
        $default = $config.reviewer.fallback
        $default | Should -Not -BeNullOrEmpty
        $available = @($config.model, $config.models.general, $config.models.explore, $config.reviewer.fallback)
        $resolved = Resolve-ModelWithFallback -Saved 'opencode/does-not-exist-explore-xyz' -Available $available -Default $default
        $resolved | Should -Be $default
    }
}
