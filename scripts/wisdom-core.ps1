#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='Load')]
<#
.SYNOPSIS
    Wisdom Core — unified pattern store operations: load, store, forge.
.DESCRIPTION
    Consolidated entry point for cross-project pattern store operations.
    Replaces: wisdom-loader.ps1, wisdom-store.ps1, wisdom-forge.ps1

    SUBCOMMANDS:
    - Load:     Load and rank patterns matching context (domain/tech/keywords)
    - Store:    Save/migrate patterns to store + Engram
    - Forge:    Auto-forge skill from pattern when threshold met

.PARAMETER Command
    Subcommand: Load, Store, Forge (default: Load).

# Load parameters
.PARAMETER Domain
    Filter by domain (ux, css, security, ps, etc.).
.PARAMETER Technology
    Filter by technology (comma-separated: gradient,playwright,theme).
.PARAMETER Keywords
    Search keywords (comma-separated: contrast,footer,btn).
.PARAMETER Severity
    Minimum severity filter (CRITICAL, HIGH, MEDIUM, LOW). Default: LOW.
.PARAMETER Limit
    Max patterns to return (default: 5).
.PARAMETER Json
    Output JSON (default: true for agent consumption).

# Store parameters
.PARAMETER PatternFile
    Single JSON file to migrate (from backlog/ or manual create).
.PARAMETER MigrateBacklog
    Migrate ALL .json files from backlog/ to patterns/ with auto-ID.
.PARAMETER Category
    Override category for migrated patterns (domain/subdomain).
.PARAMETER DryRun
    Preview actions without modifying any files.
.PARAMETER Force
    Skip confirmation prompts during migration.
.PARAMETER Quiet
    Output JSON only (machine-readable).

# Forge parameters
.PARAMETER PatternId
    Pattern ID (e.g. "ux/a11y/hero-btn-contrast").
.PARAMETER PatternFileForge
    Path to pattern JSON (alternative to PatternId).
.PARAMETER ForceForge
    Skip threshold check.
.PARAMETER DryRunForge
    Run gates but don't write.

.EXAMPLE
    .\scripts\wisdom-core.ps1 -Command Load -Domain ux -Limit 3
    .\scripts\wisdom-core.ps1 -Command Store -PatternFile "backlog/my-pattern.json" -DryRun
    .\scripts\wisdom-core.ps1 -Command Store -MigrateBacklog
    .\scripts\wisdom-core.ps1 -Command Forge -PatternId "ux/a11y/hero-btn-contrast" -Force
#>
param(
    [Parameter(ParameterSetName='Load', Position=0)]
    [Parameter(ParameterSetName='Store', Position=0)]
    [Parameter(ParameterSetName='Forge', Position=0)]
    [ValidateSet('Load','Store','Forge')]
    [string]$Command = 'Load',

    # Load params
    [string]$Domain = "",
    [string]$Technology = "",
    [string]$Keywords = "",
    [string]$Severity = "LOW",
    [int]$Limit = 5,
    [bool]$Json = $true,

    # Store params
    [string]$PatternFile = "",
    [switch]$MigrateBacklog,
    [string]$Category = "",
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Quiet,

    # Forge params
    [string]$PatternId = "",
    [string]$PatternFileForge = "",
    [switch]$ForceForge,
    [switch]$DryRunForge
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$patternsDir = Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "patterns"
$skillsDir = Join-Path (Join-Path $repoRoot ".agents") "skills"
$backlogDir = Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "backlog"
$archivedDir = Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "archived"

# ============================================================
# SHARED HELPERS
# ============================================================
function Get-PatternIndex {
    $index = @{}
    if (Test-Path $patternsDir) {
        foreach ($pf in @(Get-ChildItem $patternsDir -Filter "*.json")) {
            try { $pp = Get-Content $pf.FullName -Raw | ConvertFrom-Json; if ($pp.id) { $index[$pp.id] = $pf.FullName } } catch { Write-Debug "wisdom-core: $($_.Exception.Message)" }
        }
    }
    return $index
}
$patternIndex = Get-PatternIndex

function New-PatternId {
    param([string]$Domain, [string]$Subdomain, [string]$Title)
    $slug = ($Title -replace '[^a-zA-Z0-9\s-]', '' -replace '\s+', '-' -replace '--+', '-').ToLower()
    $slug = $slug.Substring(0, [Math]::Min(40, $slug.Length)) -replace '-+$', ''
    return "$Domain-$Subdomain-$slug"
}

function Test-Pattern {
    param([PSCustomObject]$Pattern)
    $errors = @()
    if (-not $Pattern.title) { $errors += "Missing 'title'" }
    if (-not $Pattern.domain) { $errors += "Missing 'domain'" }
    if (-not $Pattern.rule) { $errors += "Missing 'rule'" }
    if (-not $Pattern.rule.summary) { $errors += "Missing 'rule.summary'" }
    return $errors
}

function Get-SkillSlug {
    param([string]$Id)
    $slug = ($Id -replace '[/\s]+', '-').ToLower()
    if ($slug -notlike "cross-project-*") { $slug = "cross-project-$slug" }
    return $slug -replace '-+$', ''
}

function Test-ForgeThreshold {
    param($Pattern, [switch]$Force)
    if ($Force) { return $true, "forced" }
    $thresholds = @{
        CRITICAL = @{ Hits = 1; Projects = 1 }; HIGH = @{ Hits = 2; Projects = 2 }
        MEDIUM = @{ Hits = 3; Projects = 2 }; LOW = @{ Hits = 5; Projects = 3 }
    }
    $severity = if ($Pattern.severity -and $thresholds.ContainsKey($Pattern.severity)) { $Pattern.severity } else { "MEDIUM" }
    $t = $thresholds[$severity]
    $hits = if ($Pattern.hits) { [int]$Pattern.hits } else { 0 }
    $projects = if ($Pattern.context -and $Pattern.context.files) { @($Pattern.context.files | Select-Object -Unique).Length } else { 1 }
    if ($projects -lt 1) { $projects = 1 }
    if ($hits -ge $t.Hits -and $projects -ge $t.Projects) { return $true, "met (${severity}: $($t.Hits)x$($t.Projects))" }
    return $false, "needs $([Math]::Max(0, $t.Hits - $hits)) hits, $([Math]::Max(0, $t.Projects - $projects)) projects"
}

# ============================================================
# LOAD COMMAND
# ============================================================
if ($Command -eq 'Load') {
    if (-not (Test-Path $patternsDir)) {
        $result = [PSCustomObject]@{ Status = "NO_STORE"; Patterns = @(); Count = 0 }
        if ($Json) { return $result | ConvertTo-Json }
        Write-Host "Pattern store not found: $patternsDir"
        exit 0
    }

    $patternFiles = @(Get-ChildItem $patternsDir -Filter "*.json")
    if ($patternFiles.Length -eq 0) {
        $result = [PSCustomObject]@{ Status = "EMPTY"; Patterns = @(); Count = 0 }
        if ($Json) { return $result | ConvertTo-Json }
        Write-Host "[OK] No patterns in store"
        exit 0
    }

    $techList = [string[]]@()
    if ($Technology -and $Technology.Trim()) { $techList = @($Technology -split ',' | ForEach-Object { $_.Trim().ToLower() }) }
    $keywordList = [string[]]@()
    if ($Keywords -and $Keywords.Trim()) { $keywordList = @($Keywords -split ',' | ForEach-Object { $_.Trim().ToLower() }) }
    $sevOrder = @{ "LOW" = 0; "MEDIUM" = 1; "HIGH" = 2; "CRITICAL" = 3 }
    $minSev = if ($sevOrder.ContainsKey($Severity)) { $sevOrder[$Severity] } else { 0 }

    $scoredPatterns = [System.Collections.ArrayList]@()

    foreach ($file in $patternFiles) {
        try { $pattern = Get-Content $file.FullName -Raw | ConvertFrom-Json } catch { continue }
        $score = 0.0
        $matchReasons = @()

        if ($Domain -and $pattern.domain -eq $Domain) {
            $score += 0.35; $matchReasons += "domain:$($pattern.domain)"
        } elseif ($Domain -and $pattern.domain -ne $Domain) {
            if ($pattern.subdomain -and $pattern.subdomain -match $Domain) {
                $score += 0.15; $matchReasons += "domain:substring"
            }
        }

        $hasTechList = $null -ne $techList -and $techList.Length -gt 0
        if ($hasTechList -and $null -ne $pattern.context -and $null -ne $pattern.context.technologies) {
            $techMatch = @($techList | Where-Object {
                $tc = $_; $found = $false
                foreach ($pt in $pattern.context.technologies) { if ($pt -match [regex]::Escape($tc)) { $found = $true; break } }
                $found
            })
            if ($techMatch.Length -gt 0) {
                $score += 0.25 * ([Math]::Min($techMatch.Length, 3) / 3)
                $matchReasons += "tech:$($techMatch -join ',')"
            }
        }

        if ($keywordList.Length -gt 0) {
            $searchText = @(
                $pattern.title
                if ($pattern.tags) { $pattern.tags -join ' ' }
                if ($pattern.signal) { $pattern.signal.keywords -join ' ' }
                if ($pattern.rule -and $pattern.rule.summary) { $pattern.rule.summary }
            ) -join ' ' | ForEach-Object { $_.ToLower() }
            $kwMatch = $keywordList | Where-Object { $searchText -match [regex]::Escape($_) }
            if ($null -ne $kwMatch) {
                $matchCount = @($kwMatch).Length
                $score += 0.25 * ([Math]::Min($matchCount, 5) / 5)
                $matchReasons += "kw:$(@($kwMatch) -join ',')"
            }
        }

        if ($pattern.confidence) { $score += 0.10 * $pattern.confidence }
        if ($pattern.severity -and $sevOrder.ContainsKey($pattern.severity)) {
            $sevScore = $sevOrder[$pattern.severity] / 3
            $score += 0.05 * $sevScore
        }

        $patternSev = if ($sevOrder.ContainsKey($pattern.severity)) { $sevOrder[$pattern.severity] } else { 0 }
        if ($patternSev -lt $minSev) { continue }

        $scoredPatterns += [PSCustomObject]@{
            Id        = $pattern.id
            Title     = $pattern.title
            Domain    = $pattern.domain
            Subdomain = $pattern.subdomain
            Severity  = $pattern.severity
            Confidence = if ($pattern.confidence) { $pattern.confidence } else { 0.0 }
            Score     = [Math]::Round($score, 3)
            MatchReasons = $matchReasons
            Summary   = if ($pattern.rule -and $pattern.rule.summary) { $pattern.rule.summary } else { "" }
            Fix       = if ($pattern.rule -and $pattern.rule.fix) { $pattern.rule.fix } else { "" }
            Check     = if ($pattern.rule -and $pattern.rule.check) { $pattern.rule.check } else { "" }
            File      = $file.Name
            Hits      = if ($pattern.hits) { $pattern.hits } else { 0 }
        }
    }

    $topPatternsArray = @($scoredPatterns | Sort-Object Score -Descending | Select-Object -First $Limit)
    $topCount = $topPatternsArray.Length

    $result = [PSCustomObject]@{
        Status      = if ($topCount -gt 0) { "MATCH" } else { "NO_MATCH" }
        TotalStore  = $patternFiles.Length
        TotalScored = @($scoredPatterns).Length
        Count       = $topCount
        Patterns    = $topPatternsArray
        Query       = [PSCustomObject]@{ Domain=$Domain; Technology=$Technology; Keywords=$Keywords; Severity=$Severity }
    }

    if ($Json) { $result | ConvertTo-Json -Depth 5 }
    else {
        Write-Host "=== Wisdom Loader ==="
        Write-Host "Store: $($patternFiles.Length) patterns | Scored: $(@($scoredPatterns).Length) | Top: $topCount"
        if ($topCount -gt 0) {
            Write-Host ""
            Write-Host "Top patterns:"
            foreach ($p in $topPatternsArray) {
                Write-Host "  [$($p.Severity)] $($p.Title) (score: $($p.Score))"
                Write-Host "    $($p.Summary)"
                if ($null -ne $p.MatchReasons -and @($p.MatchReasons).Length -gt 0) {
                    Write-Host "    matches: $($p.MatchReasons -join ', ')"
                }
            }
        } else { Write-Host "[INFO] No matching patterns found" }
    }
    exit 0
}

# ============================================================
# STORE COMMAND
# ============================================================
if ($Command -eq 'Store') {
    if (-not (Test-Path $patternsDir)) {
        if (-not $Quiet) { Write-Warning "Patterns directory not found: $patternsDir" }
        exit 1
    }

    # Pre-build pattern index for O(1) duplicate lookups
    $script:patternIndex = @{}
    if (Test-Path $patternsDir) {
        foreach ($ixf in @(Get-ChildItem $patternsDir -Filter "*.json")) {
            try { $ixp = Get-Content $ixf.FullName -Raw | ConvertFrom-Json; if ($ixp.title) { $script:patternIndex[$ixp.title.ToLower()] = $ixf.FullName } } catch { Write-Debug "wisdom-core store: $($_.Exception.Message)" }
        }
    }

    function Save-Pattern {
        param([PSCustomObject]$Pattern)
        $domain = $Pattern.domain; $subdomain = $Pattern.subdomain
        $id = New-PatternId -Domain $domain -Subdomain $subdomain -Title $Pattern.title
        $Pattern | Add-Member -NotePropertyName "id" -NotePropertyValue $id -Force
        $Pattern | Add-Member -NotePropertyName "status" -NotePropertyValue "active" -Force
        $hasCreated = $null -ne ($Pattern.PSObject.Properties['created'])
        if (-not $hasCreated) { $Pattern | Add-Member -NotePropertyName "created" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force }
        $Pattern | Add-Member -NotePropertyName "updated" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
        $filename = "$id.json"
        $filepath = Join-Path $patternsDir $filename
        $titleKey = "$($Pattern.title)".ToLower()
        if ([string]::IsNullOrWhiteSpace($titleKey)) { $titleKey = $id.ToLower() }
        $existingPath = $script:patternIndex[$titleKey]
        if ($existingPath) {
            # Fallback: fuzzy match
            foreach ($ek in $script:patternIndex.Keys) {
                if ($ek -match [regex]::Escape($titleKey) -or $titleKey -match [regex]::Escape($ek)) {
                    $existingPath = $script:patternIndex[$ek]; break
                }
            }
        }
        if ($existingPath -and (Test-Path $existingPath)) {
            if (-not $Quiet) { Write-Warning "Pattern already exists: $existingPath (same title)" }
            $oldContent = Get-Content $existingPath -Raw | ConvertFrom-Json
            $oldContent.updated = (Get-Date -Format "yyyy-MM-dd")
            $hasHits = $null -ne ($Pattern.PSObject.Properties['hits'])
            if ($hasHits -and $Pattern.hits) { $oldContent.hits = [int]$oldContent.hits + [int]$Pattern.hits }
            $oldContent | ConvertTo-Json -Depth 6 | Set-Content $existingPath -Encoding UTF8
            return @{ Action = "updated"; Path = $existingPath; Id = $id }
        }
        $Pattern | ConvertTo-Json -Depth 6 | Set-Content $filepath -Encoding UTF8
        $script:patternIndex[$titleKey] = $filepath
        foreach ($altKey in @($id.ToLower(), $filename)) { $script:patternIndex[$altKey] = $filepath }
        return @{ Action = "created"; Path = $filepath; Id = $id }
    }

    $results = @()
    if ($MigrateBacklog) {
        if (-not (Test-Path $backlogDir)) {
            if (-not $Quiet) { Write-Warning "Backlog directory not found: $backlogDir" }
            exit 1
        }
        $backlogFiles = @(Get-ChildItem $backlogDir -Filter "*.json")
        if ($backlogFiles.Length -eq 0) {
            if (-not $Quiet) { Write-Host "[OK] No backlog files to migrate" }
            exit 0
        }
        foreach ($file in $backlogFiles) {
            try {
                $pattern = Get-Content $file.FullName -Raw | ConvertFrom-Json
                if ($Category) {
                    $parts = $Category -split '/'
                    if (@($parts).Length -ge 2) {
                        $pattern | Add-Member -NotePropertyName "domain" -NotePropertyValue $parts[0] -Force
                        $pattern | Add-Member -NotePropertyName "subdomain" -NotePropertyValue $parts[1] -Force
                    }
                }
                $errors = @(Test-Pattern $pattern)
                if ($errors.Length -gt 0) {
                    $results += @{ File = $file.Name; Status = "invalid"; Errors = $errors }
                    if (-not $Quiet) { Write-Warning "Skipping $($file.Name): $($errors -join '; ')" }
                    continue
                }
                $result = Save-Pattern $pattern
                $rAction = if ($result -and $result.ContainsKey('Action')) { $result.Action } else { "unknown" }
                $rId = if ($result -and $result.ContainsKey('Id')) { $result.Id } else { "" }
                $rPath = if ($result -and $result.ContainsKey('Path')) { $result.Path } else { "" }
                if ($DryRun) { Write-Output "[DryRun] Would delete: $($file.FullName)" }
                elseif ($rAction -in @("created", "updated")) { Remove-Item $file.FullName -Force }
                elseif ($Force) { Remove-Item $file.FullName -Force; if (-not $Quiet) { Write-Warning "[Force] Deleted backlog despite failed save: $($file.Name)" } }
                else {
                    if (-not $Quiet) { Write-Warning "Backlog preserved (save failed): $($file.Name) — retry or use -Force to delete anyway" }
                    $results += @{ File = $file.Name; Status = "preserved"; Id = $rId; Path = $rPath }
                    continue
                }
                $results += @{ File = $file.Name; Status = $rAction; Id = $rId; Path = $rPath }
                if (-not $Quiet) { Write-Host "[$($result.Action)] $($result.Id)" }
            } catch {
                $results += @{ File = $file.Name; Status = "error"; Error = $_.Exception.Message }
                if (-not $Quiet) { Write-Warning "Error processing $($file.Name): $_" }
            }
        }
    } elseif ($PatternFile) {
        if (-not (Test-Path $PatternFile)) { Write-Error "Pattern file not found: $PatternFile"; exit 1 }
        try {
            $pattern = Get-Content $PatternFile -Raw | ConvertFrom-Json
            $errors = @(Test-Pattern $pattern)
            if ($errors.Length -gt 0) { Write-Error "Validation: $($errors -join '; ')"; exit 1 }
            $result = Save-Pattern $pattern
            $results += $result
            if (-not $Quiet) { Write-Host "[$($result.Action)] $($result.Id)" }
        } catch { Write-Error "Error: $_"; exit 1 }
    } else {
        try {
            $inputJson = [Console]::In.ReadToEnd()
            if ([string]::IsNullOrWhiteSpace($inputJson)) {
                Write-Error "Usage: wisdom-core.ps1 -Command Store -PatternFile <path> | -MigrateBacklog | pipe JSON"
                exit 1
            }
            $pattern = $inputJson | ConvertFrom-Json
            $errors = @(Test-Pattern $pattern)
            if ($errors.Length -gt 0) { Write-Error "Validation: $($errors -join '; ')"; exit 1 }
            $result = Save-Pattern $pattern
            if ($result) { $results += $result }
            if (-not $Quiet) { Write-Host "[$($result.Action)] $($result.Id)" }
        } catch { Write-Error "Error: $_"; exit 1 }
    }

    $resultsArray = @($results)
    $output = [PSCustomObject]@{
        Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        Script    = "wisdom-core"
        Total     = $resultsArray.Length
        Results   = $resultsArray
    }
    $output | ConvertTo-Json -Depth 4
    exit 0
}

# ============================================================
# FORGE COMMAND
# ============================================================
if ($Command -eq 'Forge') {
    if (-not (Test-Path $patternsDir) -or -not (Test-Path $skillsDir)) {
        Write-Error "Patterns or skills directory not found"
        exit 1
    }

    function Import-Pattern {
        param([string]$Id, [string]$File)
        if ($Id) {
            $filePath = $patternIndex[$Id]
            if (-not $filePath) { Write-Error "Pattern not found: $Id"; exit 1 }
        } elseif ($File) {
            if (-not (Test-Path $File)) { Write-Error "File not found: $File"; exit 1 }
            $filePath = $File
        } else { Write-Error "Provide -PatternId or -PatternFileForge"; exit 1 }
        try { $pattern = Get-Content $filePath -Raw | ConvertFrom-Json } catch { Write-Error "Invalid JSON: $_"; exit 1 }
        return $pattern, $filePath
    }

    function New-SkillContent {
        param($Pattern)
        $slug = Get-SkillSlug $Pattern.id
        $description = if ($Pattern.rule -and $Pattern.rule.summary) {
            $desc = $Pattern.rule.summary -replace '[\u201c\u201d]', '"' -replace "'", "'"
            if ($desc.Length -gt 115) { $desc.Substring(0, 112) + "..." } else { $desc }
        } else { $Pattern.title }
        $triggerKeywords = @($Pattern.title)
        if ($Pattern.tags) { $triggerKeywords += $Pattern.tags }
        if ($Pattern.signal -and $Pattern.signal.keywords) { $triggerKeywords += $Pattern.signal.keywords }
        if ($Pattern.signal -and $Pattern.signal.css_selectors) { $triggerKeywords += $Pattern.signal.css_selectors }
        $triggerStr = ($triggerKeywords | Select-Object -Unique) -join ', '
        $details = if ($Pattern.rule -and $Pattern.rule.details) { $Pattern.rule.details } else { "" }
        $check = if ($Pattern.rule -and $Pattern.rule.check) { $Pattern.rule.check } else { "" }
        $fix = if ($Pattern.rule -and $Pattern.rule.fix) { $Pattern.rule.fix } else { "" }
        $skillContent = @"
---
name: $slug
description: "$description"
license: Apache-2.0
metadata:
  tags: [$($Pattern.tags -join ', ')]
  author: gentleman-vMK (auto-forged)
  version: "1.0"
  source_pattern: "$($Pattern.id)"
  source_severity: "$($Pattern.severity)"
triggers: "$triggerStr"
---

## Rule
$details

## Check
$check

## Fix
$fix

## Source Pattern
Forged from **$($Pattern.id)**. Updated: $($Pattern.updated). Confidence: $($Pattern.confidence).
"@
        return $skillContent
    }

    $gateResults = @()
    function Add-Gate { param([string]$Name, [scriptblock]$Check)
        try { $passed = & $Check; $gateResults += [PSCustomObject]@{ Gate = $Name; Status = if ($passed) { "PASS" } else { "FAIL" } }; return $passed }
        catch { $gateResults += [PSCustomObject]@{ Gate = $Name; Status = "FAIL"; Error = $_.Exception.Message }; return $false }
    }
    function Test-YamlFrontmatter { param([string]$Content); $trimmed = $Content.TrimStart(); return $trimmed.StartsWith("---") -and ($Content -match '(?s)---\s*\n.*?\n---') }
    $script:triggerCache = $null
    function Get-TriggerCache {
        if ($script:triggerCache) { return $script:triggerCache }
        $set = @{}
        foreach ($f in @(Get-ChildItem $skillsDir -Filter 'SKILL.md' -Recurse -EA SilentlyContinue)) {
            try { $c = Get-Content $f.FullName -Raw; if ($c -match '(?s)triggers:\s*"([^"]+)"') { ($Matches[1] -split ',') | ForEach-Object { $set[$_.Trim().ToLower()] = $true } } } catch { continue }
        }
        $script:triggerCache = $set; return $set
    }
    function Test-TriggerUnique { param([string[]]$Triggers); $existing = Get-TriggerCache; foreach ($t in $Triggers) { if ($t.Trim().ToLower() -ne '' -and $existing.ContainsKey($t.Trim().ToLower())) { return $false } }; return $true }
    function Test-NoSecret { param([string]$Content); foreach ($p in @('-----BEGIN (RSA|OPENSSH|PRIVATE|EC) KEY-----', '(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*[''"][^''"]{8,}')) { if ($Content -match $p) { return $false } }; return $true }
    function Test-NoConflict { param([string]$Name); return @(Get-ChildItem $skillsDir -Directory | Where-Object { $_.Name -eq $Name }).Length -eq 0 }

    $pattern, $filePath = Import-Pattern -Id $PatternId -File $PatternFileForge
    $severity = if ($pattern.severity) { $pattern.severity } else { "MEDIUM" }
    $id = $pattern.id
    $hits = if ($pattern.hits) { [int]$pattern.hits } else { 0 }

    if (-not $Quiet) {
        Write-Host "=== Wisdom Forge | $id | $severity (hits: $hits) ===" -ForegroundColor Cyan
        if ($DryRunForge) { Write-Host "[DRY-RUN]" -ForegroundColor Yellow }
    }

    if (-not $ForceForge) {
        $met, $reason = Test-ForgeThreshold $pattern -Force:$ForceForge
        if (-not $met) {
            if (-not $Quiet) { Write-Host "[X] $reason" -ForegroundColor Red }
            [PSCustomObject]@{ Status = "BLOCKED"; Reason = $reason; PatternId = $id; Gates = $gateResults } | ConvertTo-Json -Depth 3
            exit 0
        }
        if (-not $Quiet) { Write-Host "[OK] $reason" -ForegroundColor Green }
    }

    $slug = Get-SkillSlug $pattern.id
    $skillDir = Join-Path $skillsDir $slug
    $skillFile = Join-Path $skillDir "SKILL.md"
    $skillContent = New-SkillContent $pattern
    $skillSize = [System.Text.Encoding]::UTF8.GetByteCount($skillContent)
    if (-not $Quiet) { Write-Host "[GEN] $slug ($skillSize bytes)" -ForegroundColor Cyan }

    $allPass = $true
    $triggers = if ($pattern.tags) { @($pattern.tags) } else { @() }
    $checks = @(
        @{ N = "yaml-frontmatter";  C = { Test-YamlFrontmatter $skillContent } },
        @{ N = "name-prefix";       C = { $slug -like "cross-project-*" } },
        @{ N = "desc-length";       C = { $d = if ($skillContent -match '(?m)^description:\s*"([^"]+)"') { $Matches[1] } else { "" }; $d.Length -le 120 } },
        @{ N = "triggers-nonempty"; C = { $triggers.Length -gt 0 } },
        @{ N = "triggers-unique";   C = { Test-TriggerUnique $triggers } },
        @{ N = "has-rules";         C = { $pattern.rule -and ($pattern.rule.check -or $pattern.rule.fix -or $pattern.rule.details) } },
        @{ N = "size-max-2kb";      C = { $skillSize -le 2048 } },
        @{ N = "no-conflict";       C = { Test-NoConflict $slug } },
        @{ N = "no-secrets";        C = { Test-NoSecret $skillContent } }
    )
    foreach ($check in $checks) { $ok = Add-Gate $check.N $check.C; if (-not $ok) { $allPass = $false } }

    if (-not $Quiet) {
        Write-Host "`n--- Gates ---" -ForegroundColor Yellow
        foreach ($gate in $gateResults) { $icon = if ($gate.Status -eq 'PASS') { "[OK]" } else { "[X]" }; Write-Host "  $icon $($gate.Gate)" }
    }

    if (-not $allPass) {
        if (-not $Quiet) { Write-Host "`n[X] BLOCKED" -ForegroundColor Red }
        [PSCustomObject]@{ Status = "BLOCKED"; Reason = "Gates failed"; PatternId = $id; Gates = $gateResults } | ConvertTo-Json -Depth 4
        exit 0
    }
    if (-not $Quiet) { Write-Host "`n[OK] All gates PASSED" -ForegroundColor Green }

    if ($DryRunForge) {
        if (-not $Quiet) { Write-Host "[DRY] Would create: $skillDir" -ForegroundColor Yellow }
        [PSCustomObject]@{ Status = "DRY_RUN"; PatternId = $id; SkillName = $slug; SkillPath = $skillDir; SkillSize = $skillSize; Gates = $gateResults } | ConvertTo-Json -Depth 4
        exit 0
    }

    if (-not (Test-Path $skillDir)) { New-Item -ItemType Directory -Path $skillDir -Force | Out-Null }
    Set-Content -Path $skillFile -Value $skillContent -Encoding UTF8
    if (-not $Quiet) { Write-Host "[WRITE] $skillFile" -ForegroundColor Green }

    $pattern | Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $slug -Force
    $pattern | Add-Member -NotePropertyName "status" -NotePropertyValue "promoted" -Force
    $pattern | Add-Member -NotePropertyName "promoted_at" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
    $pattern | ConvertTo-Json -Depth 6 | Set-Content $filePath -Encoding UTF8
    if (-not $Quiet) { Write-Host "[UPDATE] Pattern -> promoted" -ForegroundColor Green }

    $result = [PSCustomObject]@{
        Status = "FORGED"; PatternId = $id; SkillName = $slug; SkillPath = $skillDir; SkillFile = $skillFile; SkillSize = $skillSize; Gates = $gateResults
        EngramPayload = [PSCustomObject]@{ TopicKey = "forge/$slug"; Type = "architecture"; Title = "Forged: $slug"; Content = "**What**: Auto-forged from ``$id`` ($severity, $hits hits)`n**Where**: $skillFile`n**Learned**: 9 quality gates passed" }
    }
    if (-not $Quiet) { Write-Host "`n=== FORGED: $slug ===" -ForegroundColor Green }
    $result | ConvertTo-Json -Depth 5
    exit 0
}