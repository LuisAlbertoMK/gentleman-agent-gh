#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Validate internal refs (skills, SKILLS-INDEX, junctions, shared, README models).
.DESCRIPTION
  Checks cross-refs, anti-pattern refs, config refs, review-rules, agent consistency.
.PARAMETER RepoRoot
  Root of the repository. Defaults to parent of scripts/.
.PARAMETER Json
  Output results as JSON instead of colored text.
.PARAMETER Quiet
  Suppress console output. Implies -Json.
#>
param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$Json,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Quiet) { $Json = $true }

# --- State ---
$errors = @()
$warnings = @()
$skillsDir = Join-Path $RepoRoot ".agents\skills"
$globalSkills = Join-Path $(if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }) ".config/opencode/skills"

if (-not (Test-Path $skillsDir)) {
    if (-not $Quiet) { Write-Host "FATAL: missing $skillsDir" -ForegroundColor Red }
    exit 1
}

# --- Helper: Get non-shared skill directories ---
function Get-SkillDir {
    param([string]$Dir)
    (Get-ChildItem $Dir -Directory).Where({ $_.Name -ne '_shared' })
}

# --- Helper: Read SKILL.md content safely ---
function Read-SkillContent {
    param([string]$SkillPath)
    $md = Join-Path $SkillPath "SKILL.md"
    if (-not (Test-Path $md)) { return $null }
    try { return [IO.File]::ReadAllText($md) } catch { return $null }
}

# --- Helper: Parse comma/pipe/middot separated refs from SKILL.md ---
# Handles both ## Cross-Refs and ## Refs headers, inline or next-line values,
# and **skill**(context) bold-token format. Non-skill tokens (URLs, prose) are
# filtered by the strict skill-name regex. Bold tokens are matched
# case-insensitively and lower-cased to match the canonical skill-name set.
function Get-SkillRef {
    param([string]$Content, [string]$Pattern)
    if ($Content -match $Pattern) {
        $raw = $Matches[1]
        # multi-line format: refs live on the line AFTER a trailing-colon header.
        # Only fall back when the header itself ended with ':' — otherwise a bare
        # header (no value) must NOT swallow the next body line.
        if ([string]::IsNullOrWhiteSpace($raw) -and $Matches[0] -match ':\s*$') {
            $afterHeader = $Content.Substring($Matches[0].Length)
            $nextLine = ($afterHeader -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
            $raw = $nextLine
        }
        # bold-token format: **skill-name**(context) — case-insensitive, lower-cased
        $boldTokens = @([regex]::Matches($raw, '\*\*([a-z][a-z0-9_-]+)\*\*', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) |
            ForEach-Object { $_.Groups[1].Value.ToLower() })
        $hasBold = $boldTokens.Count -gt 0
        # strip bold tokens + their optional (context) — case-insensitively to match extraction
        $clean = [regex]::Replace($raw, '(?i)\*\*[a-z][a-z0-9_-]+\*\*(\s*\([^)]*\))?', ' ')
        $splitTokens = @()
        # In bold format the residual text must be separator-delimited; a lone
        # trailing word (e.g. "context") is prose, not a ref. In plain format a
        # single unseparated token is a valid inline ref.
        if ($clean -match '[·|,]' -or -not $hasBold) {
            $splitTokens = @($clean -split '\s*[·|,]\s*' |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -cmatch '^[a-z][a-z0-9_-]+$' } |
                ForEach-Object { $_.ToLower() })
        }
        return @($boldTokens + $splitTokens | Select-Object -Unique)
    }
    return @()
}

# --- Helper: Parse config_refs (file paths, NOT skill names) ---
# config_refs are repo-relative paths (e.g. .opencode/skills/foo/SKILL.md),
# so the strict skill-name filter must NOT apply. Split, trim, drop empties.
function Get-ConfigRef {
    param([string]$Content, [string]$Pattern)
    if ($Content -match $Pattern) {
        return @($Matches[1] -split '\s*[·|,]\s*' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ })
    }
    return @()
}

# [1/9] APC check
if (-not $Json -and -not $Quiet) { Write-Host "[1/9] APC..." -N }
$apcPath = Join-Path $RepoRoot "ANTI-PATTERN-CATALOG.md"
if (Test-Path $apcPath) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK" }
} else {
    $errors += "APC not found"
    if (-not $Json -and -not $Quiet) { Write-Host " FAIL" }
}

# [2/9] SKILL.md presence
if (-not $Json -and -not $Quiet) { Write-Host "[2/9] SKILL.md..." -N }
$missingSkills = [System.Collections.Generic.List[string]]::new()
$skillDirs = Get-SkillDir $skillsDir
foreach ($skill in $skillDirs) {
    if (-not (Test-Path (Join-Path $skill.FullName "SKILL.md"))) {
        $missingSkills.Add($skill.Name)
    }
}
if ($missingSkills.Count -eq 0) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK (all)" }
} else {
    $warnings += "Missing SKILL.md: $($missingSkills -join ', ')"
    if (-not $Json -and -not $Quiet) { Write-Host " WARN" }
}

# [3/9] INDEX count
if (-not $Json -and -not $Quiet) { Write-Host "[3/9] INDEX count..." -N }
$actualCount = $skillDirs.Count
$indexLine = Select-String -Path (Join-Path $RepoRoot "SKILLS-INDEX.md") -Pattern "all \d+ skills"
if ($indexLine -match "all (\d+) skills") {
    $declaredCount = [int]$Matches[1]
if ($declaredCount -eq $actualCount) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK ($actualCount)" }
} else {
    $errors += "INDEX says $declaredCount, has $actualCount"
    if (-not $Json -and -not $Quiet) { Write-Host " FAIL ($declaredCount vs $actualCount)" }
}
} else {
    $warnings += "INDEX header mismatch"
    if (-not $Json -and -not $Quiet) { Write-Host " WARN" }
}

# [4/9] Junctions
if (-not $Json -and -not $Quiet) { Write-Host "[4/9] junctions..." -N }
$missingJunctions = [System.Collections.Generic.List[string]]::new()
if (Test-Path $globalSkills) {
    foreach ($skill in $skillDirs) {
        $junctionPath = Join-Path $globalSkills $skill.Name
        if (-not (Test-Path $junctionPath)) {
            $missingJunctions.Add($skill.Name)
        }
    }
}
if ($missingJunctions.Count -eq 0) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK (all)" }
} else {
    $warnings += "Missing junctions: $($missingJunctions -join ', ')"
    if (-not $Json -and -not $Quiet) { Write-Host " WARN" }
}

# [5/9] _shared files
if (-not $Json -and -not $Quiet) { Write-Host "[5/9] _shared..." -N }
$requiredShared = @{
    'skill-resolver.md'     = Test-Path (Join-Path $skillsDir "_shared\skill-resolver.md")
    'sdd-phase-common.md'   = Test-Path (Join-Path $skillsDir "sdd\references\sdd-phase-common.md")
    'persistence-contract.md' = Test-Path (Join-Path $skillsDir "_shared\persistence-contract.md")
    'engram-convention.md'  = Test-Path (Join-Path $skillsDir "_shared\engram-convention.md")
}
$missingShared = @($requiredShared.GetEnumerator().Where({ -not $_.Value }).ForEach({ $_.Key }))
if ($missingShared.Count -eq 0) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK" }
} else {
    $errors += "Missing _shared: $($missingShared -join ', ')"
    if (-not $Json -and -not $Quiet) { Write-Host " FAIL" }
}

# [6/9] Cross-refs
if (-not $Json -and -not $Quiet) { Write-Host "[6/9] cross-refs..." -N }
$allSkillNames = @($skillDirs.ForEach({ $_.Name.ToLower() }))
$brokenRefs = [System.Collections.Generic.List[string]]::new()
$skillContentCache = @{}

foreach ($skill in $skillDirs) {
    $content = Read-SkillContent $skill.FullName
    if (-not $content) { continue }
    $skillContentCache[$skill.Name] = $content

    # Check Cross-Refs (accepts ## Cross-Refs and ## Refs, inline or next-line)
    $crossRefs = Get-SkillRef $content '(?im)^##\s*(?:Cross-)?Refs:?\s*(.*)$'
    foreach ($ref in $crossRefs) {
        if ($allSkillNames -notcontains $ref) {
            $brokenRefs.Add("$($skill.Name) cross-refs '$ref' missing")
        }
    }

    # Check Anti-Patterns
    $antiRefs = Get-SkillRef $content 'Anti-Patterns:\s*(.+)'
    foreach ($ref in $antiRefs) {
        if ($allSkillNames -notcontains $ref) {
            $brokenRefs.Add("$($skill.Name) anti-refs '$ref' missing")
        }
    }
}

if ($brokenRefs.Count -eq 0) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK" }
} else {
    $errors += $brokenRefs
    if (-not $Json -and -not $Quiet) { Write-Host " FAIL ($($brokenRefs.Count))" }
}

# [7/9] Config refs
if (-not $Json -and -not $Quiet) { Write-Host "[7/9] config_refs..." -N }
$missingConfigRefs = [System.Collections.Generic.List[string]]::new()

foreach ($skill in $skillDirs) {
    $content = $skillContentCache[$skill.Name]
    if (-not $content) { continue }

    $configRefs = Get-ConfigRef $content 'config_refs:\s*(.+)'
    foreach ($ref in $configRefs) {
        $refPath = Join-Path $RepoRoot $ref
        if (-not (Test-Path $refPath)) {
            $missingConfigRefs.Add("$($skill.Name) config_refs '$ref' missing at $refPath")
        }
    }
}

if ($missingConfigRefs.Count -eq 0) {
    if (-not $Json -and -not $Quiet) { Write-Host " OK" }
} else {
    $errors += $missingConfigRefs
    if (-not $Json -and -not $Quiet) { Write-Host " FAIL ($($missingConfigRefs.Count))" }
}

# [8/9] review-rules.jsonc
if (-not $Json -and -not $Quiet) { Write-Host "[8/9] review-rules.jsonc..." -N }
$rulesPath = Join-Path $RepoRoot "review-rules.jsonc"

if (Test-Path $rulesPath) {
    try {
        $raw = Get-Content $rulesPath -Raw -Encoding UTF8
        # Strip comments (JSONC -> JSON)
        $stripped = $raw `
            -replace '(?m)^\s*//.*$', '' `
            -replace '(?m)\s*//[^"\n]*$', '' `
            -replace '(?s)/\*.*?\*/', ''
        $parsed = $stripped | ConvertFrom-Json

        $zoneCount = $parsed.zones.PSObject.Properties.Name.Count
        $ctxCount = $parsed.context_zones.PSObject.Properties.Name.Count
        $modeCount = $parsed.modes.PSObject.Properties.Name.Count
        $profileCount = $parsed.jd_profiles.PSObject.Properties.Name.Count
        $selectorCount = $parsed.jd_profile_selector.Count

        $issues = @()
        if ($zoneCount -ne 3) { $issues += "zones $zoneCount" }
        if ($ctxCount -ne 4) { $issues += "ctx $ctxCount" }
        if ($modeCount -ne 5) { $issues += "modes $modeCount" }
        if ($profileCount -lt 1) { $issues += "profiles $profileCount" }
        if ($selectorCount -lt 1) { $issues += "selectors $selectorCount" }

        if ($issues.Count -eq 0) {
            if (-not $Json -and -not $Quiet) { Write-Host " OK (z$zoneCount c$ctxCount m$modeCount p$profileCount s$selectorCount)" }
        } else {
            $errors += "review-rules.jsonc: $($issues -join '; ')"
            if (-not $Json -and -not $Quiet) { Write-Host " FAIL" }
        }
    } catch {
        $errors += "review-rules.jsonc parse: $_"
        if (-not $Json -and -not $Quiet) { Write-Host " FAIL" }
    }
} else {
    $warnings += "review-rules.jsonc missing"
    if (-not $Json -and -not $Quiet) { Write-Host " WARN" }
}

# [9/9] README vs opencode.json agents
if (-not $Json -and -not $Quiet) { Write-Host "[9/9] README agents..." -N }
try {
    $oc = Get-Content (Join-Path $RepoRoot "opencode.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $readme = Get-Content (Join-Path $RepoRoot "README.md") -Raw -Encoding UTF8
    $ocAgents = $oc.agent.PSObject.Properties.Name.Where({ $_ -notlike 'sdd-*' }) | ForEach-Object { $_.ToLower() }

    $missingInReadme = [System.Collections.Generic.List[string]]::new()
    foreach ($agentName in $ocAgents) {
        if ($readme -notmatch [regex]::Escape($agentName)) {
            $missingInReadme.Add("README missing agent '$agentName' from opencode.json")
        }
    }

    if ($missingInReadme.Count -eq 0) {
        if (-not $Json -and -not $Quiet) { Write-Host " OK ($($ocAgents.Count) agents match)" }
    } else {
        $errors += $missingInReadme
        if (-not $Json -and -not $Quiet) { Write-Host " FAIL ($($missingInReadme.Count) missing)" }
    }
} catch {
    if (-not $Json -and -not $Quiet) { Write-Host " WARN (parse: $($_.Exception.Message))" }
}

# [10/9] semi-agents.json vs permission-gate.ps1 allowlist
if (-not $Json -and -not $Quiet) { Write-Host "[10/9] semi allowlist sync..." -N }
try {
    $semiPath = Join-Path $RepoRoot "scripts\opencode-config\semi-agents.json"
    $gatePath = Join-Path $RepoRoot "scripts\permission-gate.ps1"

    if ((Test-Path $semiPath) -and (Test-Path $gatePath)) {
        $semiContent = Get-Content $semiPath -Raw -Encoding UTF8
        $gateContent = Get-Content $gatePath -Raw -Encoding UTF8

        # Extract semi-agent allows: "xxx *" → xxx; "exact": "allow" → exact command
        $semiAllow = @(
            [regex]::Matches($semiContent, '"((?:\w+[ -]?)+) \*":\s*"allow"') | ForEach-Object { $_.Groups[1].Value }
            [regex]::Matches($semiContent, '"((?:\w+[ -]?)+)":\s*"allow"')   | ForEach-Object { $_.Groups[1].Value }
        )
        # Extract gate patterns: command name after '^ (word chars, dots, hyphens)
        $gatePatterns = [regex]::Matches($gateContent, "'\^([a-zA-Z][a-zA-Z0-9._-]+)") | ForEach-Object { $_.Groups[1].Value }

        # Normalize: add test runners using spaces in the name
        $gateCommands = @($gatePatterns | Where-Object { $_ -ne '' } | ForEach-Object { $_.ToLower() } | Sort-Object)
        $semiCommands = @($semiAllow | ForEach-Object { $_.ToLower() } | Sort-Object)

        # Check: every semi allow must exist in gate patterns (or be a superset)
        $missingInGate = @()
        $checked = @{}  # deduplicate
        foreach ($cmd in $semiCommands) {
            if ($checked.ContainsKey($cmd)) { continue }
            $checked[$cmd] = $true
            if ($cmd -notin $gateCommands -and $cmd -notmatch '^(Get-|Test-Path)') {
                $hasMatch = $gateCommands | Where-Object { $cmd -match "^$_" }
                if (-not $hasMatch) { $missingInGate += $cmd }
            }
        }

        $dedupedSemi = $checked.Keys.Count
        if ($missingInGate.Count -eq 0) {
            if (-not $Json -and -not $Quiet) { Write-Host " OK ($dedupedSemi unique semi allows across $($semiCommands.Count) entries, $($gateCommands.Count) gate patterns)" }
        } else {
            $warnings += "semi-agents.json allows missing from permission-gate.ps1: $($missingInGate -join ', ')"
            if (-not $Json -and -not $Quiet) { Write-Host " WARN ($($missingInGate.Count) mismatches)" }
        }
    }
} catch {
    if (-not $Json -and -not $Quiet) { Write-Host " WARN (check: $($_.Exception.Message))" }
}

# Output
$result = @{
    timestamp        = (Get-Date -Format "o")
    canonicalSkills  = $actualCount
    errors           = $errors
    warnings         = $warnings
    brokenCrossRefs  = $brokenRefs.Count
    allClean         = ($errors.Count -eq 0 -and $warnings.Count -eq 0)
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 2)
    # Exit after JSON output to avoid polluting pipeline with the result object
    exit ($result.allClean ? 0 : 1)
} elseif ($result.allClean) {
    if (-not $Quiet) { Write-Host "OK ALL CHECKS PASSED" -ForegroundColor Green }
    exit 0
} elseif (-not $Quiet) {
    if ($errors.Count -gt 0) {
        Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red
        $errors.ForEach({ Write-Host " * $_" -ForegroundColor Red })
    }
    if ($warnings.Count -gt 0) {
        Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
        $warnings.ForEach({ Write-Host " * $_" -ForegroundColor Yellow })
    }
    if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
}
