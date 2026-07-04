#requires -Version 7.6
<#
.SYNOPSIS
    Sync gentleman-agent-gh to global OpenCode config — skills, scripts, MCPs, agents, AGENTS.md, permissions.
.DESCRIPTION
    One-shot pipeline to apply gentleman-agent globally:
    1. Install/verify skill junctions → ~/.config/opencode/skills/
    2. Install/verify scripts junction → ~/.config/opencode/scripts/
    3. Write global opencode.jsonc with MCPs (engram, context7) + permission rules (preserves existing agents)
    4. Sync gentleman-* agents + AGENTS.md from project to global config
    5. Verify MCP availability
    6. Report full status
.PARAMETER DryRun
    Show what would be done without making changes.
.PARAMETER Force
    Overwrite existing global opencode.jsonc.
.PARAMETER NoAgentSync
    Skip agent + AGENTS.md sync (only install junctions + config).
.PARAMETER Json
    Output status as JSON.
.EXAMPLE
    .\scripts\sync-global.ps1
.EXAMPLE
    .\scripts\sync-global.ps1 -DryRun
#>
param([switch]$DryRun,[switch]$Force,[switch]$NoAgentSync,[switch]$Json,[switch]$NoAgentsMd)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$srcSkills = Resolve-Path "$PSScriptRoot\..\.agents\skills" -ErrorAction Stop
$dstSkills = "$env:USERPROFILE\.config\opencode\skills"
$srcScripts = Resolve-Path "$PSScriptRoot" -ErrorAction Stop
$dstScripts = "$env:USERPROFILE\.config\opencode\scripts"
$globalCfg = "$env:USERPROFILE\.config\opencode\opencode.jsonc"
$projectCfg = Resolve-Path "$PSScriptRoot\..\opencode.json" -ErrorAction Stop

$report = @{timestamp=(Get-Date -Format "o"); steps=@{}; errors=@(); warnings=@()}

function Write-Step([string]$Name, [scriptblock]$Block) {
    # Captures script-scope $DryRun and $Force — keep synced if adding params
    if ($DryRun) { Write-Host "[dry-run] $Name" -ForegroundColor Yellow; return }
    Write-Host "==> $Name" -ForegroundColor Cyan
    try { &$Block; $report.steps[$Name] = "ok" } catch { Write-Host "[err] $Name : $_" -ForegroundColor Red; $report.errors += "$Name : $_"; $report.steps[$Name] = "fail" }
}

# ── Step 1: Skill junctions ──────────────────────────────────────────────
Write-Step "Skill junctions" {
    if (-not (Test-Path $dstSkills)) { New-Item -ItemType Directory -Path $dstSkills -Force | Out-Null }
    $count = 0; $total = 0
    foreach ($skill in Get-ChildItem -Directory -Path $srcSkills) {
        $total++
        $link = Join-Path $dstSkills $skill.Name
        if (-not (Test-Path $link)) {
            New-Item -ItemType Junction -Path $link -Target $skill.FullName -ErrorAction Stop | Out-Null
            $count++
        }
    }
    Write-Host "  $count new junctions (total: $total)" -ForegroundColor Green
    $report.steps["skill_junctions"] = @{created=$count; total=$total}
}

# ── Step 2: Scripts junction ─────────────────────────────────────────────
Write-Step "Scripts junction" {
    if (-not (Test-Path $dstScripts)) {
        New-Item -ItemType Junction -Path $dstScripts -Target $srcScripts -ErrorAction Stop | Out-Null
        Write-Host "  Created scripts junction" -ForegroundColor Green
    } else {
        Write-Host "  Scripts junction exists, skipping" -ForegroundColor Yellow
    }
}

# ── Step 3: Global opencode.jsonc (MCPs + permissions + agents) ──────────
Write-Step "Global config (MCPs + permissions + agents)" {
    $genCfg = $Force -or -not (Test-Path $globalCfg)
    if ($genCfg) {
        # Preserve existing agent definitions if they exist (global source of truth)
        $existingAgents = @{}
        if (Test-Path $globalCfg) {
            try {
                $existing = Get-Content $globalCfg -Raw | ConvertFrom-Json
                if ($existing.PSObject.Properties.Match('agent').Count -gt 0) {
                    foreach ($prop in $existing.agent.PSObject.Properties) {
                        $existingAgents[$prop.Name] = $prop.Value
                    }
                }
            } catch { Write-Warning "  Could not read existing global config, starting fresh" }
        }
        $cfg = @{
            '$schema' = "https://opencode.ai/config.json"
            default_agent = "gentleman-vMK"
            mcp = @{
                context7 = @{ enabled = $true; type = "remote"; url = "https://mcp.context7.com/mcp" }
                engram = @{ command = @("engram", "mcp", "--tools=agent"); type = "local" }
                "sequential-thinking" = @{ enabled = $true; type = "local"; command = @("npx", "-y", "@modelcontextprotocol/server-sequential-thinking@2025.12.18") }
                headroom = @{ enabled = $true; type = "local"; command = @("headroom", "mcp", "serve") }
            }
            permission = @{
                bash = @{
                    "*" = "allow"
                    "git commit *" = "ask"; "git push *" = "ask"; "git push --force *" = "ask"
                    "git push --delete *" = "ask"; "git rebase *" = "ask"; "git reset *" = "ask"
                    "git merge *" = "ask"; "git branch -D *" = "ask"; "git stash drop *" = "ask"
                    "gh pr merge *" = "ask"
                }
                read = @{
                    "*" = "allow"
                    "**/.env" = "deny"; "**/.env.*" = "deny"; "**/credentials.json" = "deny"
                    "**/secrets/**" = "deny"; "*.env" = "deny"; "*.env.*" = "deny"
                }
            }
            agent = $existingAgents
        }
        # If no agents preserved, add an empty agent object to keep valid JSON
        if ($cfg.agent.Keys.Count -eq 0) { $cfg.agent = @{} }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $globalCfg -Encoding UTF8 -Force
        Write-Host "  Written $globalCfg (preserved $($existingAgents.Keys.Count) agent definitions)" -ForegroundColor Green
    } else {
        Write-Host "  Global config exists, skipping (use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# ── Step 4: Sync gentleman agents from project to global ─────────────────
if (-not $NoAgentSync) {
    Write-Step "Agent sync (project -> global)" {
        if (-not (Test-Path $globalCfg)) { throw "Global config not found at $globalCfg -- run step 3 first" }
        try {
            $proj = Get-Content $projectCfg -Raw | ConvertFrom-Json
            $glob = Get-Content $globalCfg -Raw | ConvertFrom-Json
        } catch {
            throw "Failed to parse config JSON: $_"
        }
        $agentNames = @("gentleman-vMK", "gentleman-deep", "gentleman-codex", "gentleman-quick")

        # Ensure agent section exists in global
        $globHasAgent = $glob.PSObject.Properties.Match('agent').Count -gt 0
        if (-not $globHasAgent) { $glob | Add-Member -Name agent -Value @{} -MemberType NoteProperty -Force; $globHasAgent = $true }

        # Check project has gentleman agents (canonical source)
        $projHasAgent = $proj.PSObject.Properties.Match('agent').Count -gt 0
        if (-not $projHasAgent) {
            Write-Warning "  Project opencode.json has no agent definitions -- nothing to sync"
            $report.steps["agent_sync"] = @{added=0; note="no project agents"; source="project -> global"}
        } else {
            $added = 0; $updated = 0
            foreach ($name in $agentNames) {
                $srcProp = $proj.agent.PSObject.Properties[$name]
                if ($null -eq $srcProp) { Write-Host "  [not in project] $name" -ForegroundColor Gray; continue }
                $globHas = $glob.agent.PSObject.Properties.Match($name).Count -gt 0
                $glob.agent | Add-Member -Name $name -Value $srcProp.Value -MemberType NoteProperty -Force
                if ($globHas) { $updated++ } else { $added++ }
                Write-Host "  $(if($globHas){'[updated]'}else{'[added]'}) $name" -ForegroundColor Green
            }
            # Sync AGENTS.md for {file:AGENTS.md} reference
            if (-not $NoAgentsMd) {
                $srcAgentsMd = Join-Path (Split-Path $projectCfg -Parent) "AGENTS.md"
                $dstAgentsMd = Join-Path (Split-Path $globalCfg -Parent) "AGENTS.md"
                if (Test-Path $srcAgentsMd -PathType Leaf) {
                    Copy-Item -LiteralPath $srcAgentsMd -Destination $dstAgentsMd -Force
                    Write-Host "  [synced] AGENTS.md" -ForegroundColor Green
                } else {
                    Write-Warning "  AGENTS.md not found at $srcAgentsMd"
                }
            } else {
                Write-Host "  [skipped] AGENTS.md (stub preserved)" -ForegroundColor Yellow
            }

            $glob | ConvertTo-Json -Depth 10 | Set-Content $globalCfg -Encoding UTF8 -Force
            Write-Host "  Updated $globalCfg (${added} added, ${updated} updated, AGENTS.md synced)" -ForegroundColor Green
            $report.steps["agent_sync"] = @{added=$added; updated=$updated; agendsMdSynced=$true; source="project -> global"}
        }
    }
}

# ── Step 5: Verify junctions ─────────────────────────────────────────────
Write-Step "Junction verification" {
    $skills = Get-ChildItem $dstSkills -Directory -EA SilentlyContinue
    $bad = $skills.PSWhere({ $_.Target -and -not (Test-Path $_.Target) })
    if ($bad.Count -gt 0) {
        $bad | ForEach-Object { Write-Host "  [broken] $($_.Name) -> $($_.Target)" -ForegroundColor Red }
        throw "$($bad.Count) broken junctions"
    }
    Write-Host "  Skills: $($skills.Count) entries accessible via junction" -ForegroundColor Green
    $scriptsOk = Test-Path $dstScripts
    Write-Host "  Scripts junction: $scriptsOk" -ForegroundColor Green
}

# ── Step 6: Verify MCPs ──────────────────────────────────────────────────
Write-Step "MCP availability" {
    $engramPath = (Get-Command engram -EA SilentlyContinue).Source
    if ($engramPath) { Write-Host "  engram: $engramPath" -ForegroundColor Green; $report.steps["mcp_engram"] = "found" }
    else { Write-Warning "  engram: not in PATH"; $report.warnings += "engram not in PATH"; $report.steps["mcp_engram"] = "missing" }
    # context7 is remote — no local binary to check
    Write-Host "  context7: remote MCP (verified at runtime)" -ForegroundColor Gray
}

# ── Report ───────────────────────────────────────────────────────────────
$report.status = if ($report.errors.Count -eq 0) { "ok" } else { "fail" }
$report.trend = "stable"

if ($Json) {
    $report | ConvertTo-Json -Depth 5
} else {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  sync-global report" -ForegroundColor White
    Write-Host "  Status: $($report.status)" -ForegroundColor $(if ($report.errors.Count -eq 0) { "Green" } else { "Red" })
    foreach ($step in $report.steps.Keys) {
        $v = $report.steps[$step]
        $c = if ($v -eq "ok" -or $v.Contains("created") -or $v.Contains("found")) { "Green" } else { "Red" }
        Write-Host "  $($step.PadRight(30)) $(if ($v -is [string]){$v}else{'ok'})" -ForegroundColor $c
    }
    if ($report.warnings.Count -gt 0) { Write-Host "  Warnings: $($report.warnings.Count)" -ForegroundColor Yellow }
    if ($report.errors.Count -gt 0) { Write-Host "  Errors: $($report.errors.Count)" -ForegroundColor Red; exit 1 }
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
}
