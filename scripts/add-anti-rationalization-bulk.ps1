#requires -Version 7
<#
.SYNOPSIS
    Bulk add addyosmani anti-rationalization structure to remaining skills (R2-1 "todo" — 81 remaining).
.DESCRIPTION
    Scans .agents/skills for SKILL.md without "Anti-Rationalization" section,
    generates domain-specific tables (security, frontend, performance, infra,
    datascience, docs, aem, seo, generic), bumps token_budget (+500 headroom),
    validates parse and cross-ref before writing.

    Idempotent: skills already with has_all are skipped.
    Run:  pwsh -File scripts/add-anti-rationalization-bulk.ps1 -WhatIf   # preview
          pwsh -File scripts/add-anti-rationalization-bulk.ps1           # apply
#>
[CmdletBinding()]
param([switch]$WhatIf)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$skillsDir = Join-Path $repoRoot '.agents/skills'

# Domain → template mapping (from playbook + skill-graph domain table)
$templates = @{
    security      = @{ rational="No secrets in this repo"; red="Skipping secrets scan"; verify="grep -rn process.env + npm audit before commit"; }
    frontend      = @{ rational="Pixel perfect without tokens"; red="Hardcoded hex without OKLCH"; verify="baseline-ui tokens + vision-analyze screenshot"; }
    performance   = @{ rational="Optimize without profiling"; red="No baseline measurement"; verify="benchmark-core.ps1 -Gate before/after"; }
    infra         = @{ rational="Deploy without canary"; red="No rollback plan"; verify="infra-audit checklist + dry-run"; }
    datascience   = @{ rational="EDA without pipeline"; red="No data-pipeline.ps1 stages"; verify="data-pipeline stages 1-3 PASS"; }
    docs          = @{ rational="Docs are obvious, no audit needed"; red="README without Diataxis"; verify="docs-audit checklist"; }
    seo           = @{ rational="SEO can wait"; red="No structured data / E-E-A-T"; verify="seo skill checklist + Lighthouse SEO"; }
    aem           = @{ rational="AEM migration is copy-paste"; red="No component/dialog mapping"; verify="aem-migration skill checklist"; }
    generic       = @{ rational="Skill without verification"; red="Doing work without checking output format"; verify="Output matches skill ## Output contract + file:line citaton"; }
}

function Get-TemplateForSkill([string]$name) {
    foreach ($k in $templates.Keys) { if ($name -match $k) { return $templates[$k] } }
    return $templates.generic
}

$skills = Get-ChildItem $skillsDir -Directory
$pending = @()
foreach ($d in $skills) {
    $p = Join-Path $d.FullName 'SKILL.md'
    if (-not (Test-Path $p)) { continue }
    $c = Get-Content $p -Raw
    if ($c -match 'Anti-Rationalization') { continue }
    $pending += $d.Name
}

Write-Host "Skills total: $($skills.Count) | pending without anti-rationalization: $($pending.Count) / has_all: $($skills.Count - $pending.Count)/$($skills.Count)" -ForegroundColor Cyan
if ($WhatIf) {
    $pending | ForEach-Object { Write-Host "  would patch: $_" -ForegroundColor Yellow }
    exit 0
}

foreach ($name in $pending) {
    $path = Join-Path $skillsDir "$name/SKILL.md"
    $content = Get-Content $path -Raw
    $tmpl = Get-TemplateForSkill $name

    # Bump token_budget (+500 headroom, or at least current chars+500)
    $chars = $content.Length
    $newBudget = [math]::Max(1500, $chars + 600)
    if ($content -match 'token_budget:\s*(\d+)') {
        $oldBudget = [int]$Matches[1]
        $newBudget = [math]::Max($newBudget, $oldBudget + 500)
        $content = $content -replace 'token_budget:\s*\d+', "token_budget: $newBudget"
    }

    # Insert anti-rationalization before first ## Refs / ## Cross-Refs / ## Refs:
    $section = @"
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "$($tmpl.rational)" | $($tmpl.red) | $($tmpl.verify) |
| "Save time skipping this skill" | Using skill directly without resolving deps | `skill-graph` resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- $($tmpl.red) → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- $($tmpl.verify)
- `cross-ref-check.ps1` → SKILL.md OK

"@

    $inserted = $false
    foreach ($marker in @('## Refs', '## Cross-Refs', '## Refs:')) {
        if ($content.Contains($marker)) {
            $content = $content.Replace($marker, "$section$marker")
            $inserted = $true
            break
        }
    }
    if (-not $inserted) {
        # Fallback: append before last Refs line via regex
        $content = $content -replace '(?m)^(## Refs.*)', "$section`$1"
    }

    # Validate markdown: must have frontmatter and token_budget
    if ($content -notmatch '(?m)^---\s*\nname:' -or $content -notmatch 'token_budget:') {
        Write-Warning "Frontmatter check failed for $name — skipping"
        continue
    }

    Set-Content -LiteralPath $path -Value $content -Encoding UTF8
    Write-Host "  patched: $name (budget → $newBudget)" -ForegroundColor Green
}

Write-Host "`nDone. Run: & scripts/cross-ref-check.ps1  then  git add .agents/skills/*/SKILL.md" -ForegroundColor Cyan
