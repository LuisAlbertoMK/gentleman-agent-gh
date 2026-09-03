#requires -Version 5.1
<#
.SYNOPSIS
    Sync gentleman-agent-gh to global OpenCode config — PS 5.1 compatible.
.DESCRIPTION
    Creates skill junctions, copies missing scripts, syncs AGENTS.md + configs.
    Fully self-contained — no PS7-only lib dependencies, runs on PS 5.1.
.PARAMETER DryRun  Show what would be done without making changes.
#>
param([switch]$DryRun,
    [switch]$Quiet,
    [switch]$Json)

function Get-GlobalConfigDir {
    $base = if ($env:OS -eq 'Windows_NT') { $env:USERPROFILE } else { $HOME }
    return Join-Path (Join-Path $base ".config") "opencode"
}
function New-CrossPlatLink {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Path, [string]$Target)
    if ($env:OS -eq 'Windows_NT') { if ($PSCmdlet.ShouldProcess($Target, "Create junction: $Path")) { New-Item -ItemType Junction -Path $Path -Target $Target -Force | Out-Null } }
    else { if ($PSCmdlet.ShouldProcess($Target, "Create symlink: $Path")) { New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force | Out-Null } }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path "$PSScriptRoot\.." -ErrorAction Stop
$srcSkills = Join-Path $repoRoot ".agents\skills"
$srcScripts = Join-Path $repoRoot "scripts"
$dstSkills = Join-Path (Get-GlobalConfigDir) "skills"
$dstScripts = Join-Path (Get-GlobalConfigDir) "scripts"
$globalCfg = Get-GlobalConfigDir

function Sync-DirectoryFile { param([string]$SrcDir,[string]$DstDir,[switch]$IsDryRun,[ref]$Count)
    if (-not (Test-Path $DstDir)) { New-Item -ItemType Directory -Path $DstDir -Force | Out-Null }
    if (Test-Path $SrcDir -PathType Container) {
        foreach ($f in Get-ChildItem -Path $SrcDir -File) {
            $dst = Join-Path $DstDir $f.Name
            $needsCopy = -not (Test-Path $dst)
            if (-not $needsCopy) { try { $needsCopy = (Get-FileHash $f.FullName).Hash -ne (Get-FileHash $dst -EA SilentlyContinue).Hash } catch { $needsCopy = $true } }
            if ($needsCopy) { if (-not $IsDryRun) { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force; $Count.Value++ } }
        }
    }
}

function Sync-SingleFile { param([string]$Src,[string]$Dst,[switch]$IsDryRun,[ref]$Count)
    if (-not (Test-Path $Src -PathType Leaf)) { return }
    $needsCopy = -not (Test-Path $Dst)
    if (-not $needsCopy) { try { $needsCopy = (Get-FileHash -Path $Src).Hash -ne (Get-FileHash -Path $Dst -EA SilentlyContinue).Hash } catch { $needsCopy = $true } }
    if ($needsCopy) { if (-not $IsDryRun) { Copy-Item -LiteralPath $Src -Destination $Dst -Force; $Count.Value++ } }
}

Write-Host "`n=== sync-global-ps5: Gentleman Agent ===" -ForegroundColor Cyan

# Step 1: Skill junctions
Write-Host "`n[1] Skill junctions" -ForegroundColor Cyan
if (-not (Test-Path $dstSkills)) { New-Item -ItemType Directory -Path $dstSkills -Force | Out-Null }
$skillsCreated = 0; $skillsTotal = 0
foreach ($skill in Get-ChildItem -Directory -Path $srcSkills) {
    $skillsTotal++; $link = Join-Path $dstSkills $skill.Name
    if (-not (Test-Path $link)) {
        if ($DryRun) { Write-Host "  [dry-run] junction: $($skill.Name)" -Fore Yellow } else { New-CrossPlatLink -Path $link -Target $skill.FullName; Write-Host "  [created] $($skill.Name)" -Fore Green }
        $skillsCreated++
    }
}
Write-Host "  Skills: $skillsCreated new of $skillsTotal total" -Fore Green

# Step 2: Scripts copy
Write-Host "`n[2] Scripts sync" -ForegroundColor Cyan
$scriptsCopied = 0; $scriptsTotal = 0
foreach ($script in Get-ChildItem -Path $srcScripts -File) {
    $scriptsTotal++; $dst = Join-Path $dstScripts $script.Name
    $needsCopy = -not (Test-Path $dst)
    if (-not $needsCopy) { try { $needsCopy = (Get-FileHash -Path $script.FullName).Hash -ne (Get-FileHash -Path $dst -EA SilentlyContinue).Hash } catch { $needsCopy = $true } }
    if ($needsCopy) { if ($DryRun) { Write-Host "  [dry-run] $($script.Name)" -Fore Yellow } else { Copy-Item -LiteralPath $script.FullName -Destination $dst -Force; Write-Host "  [copied] $($script.Name)" -Fore Green; $scriptsCopied++ } }
}
Write-Host "  Scripts: $scriptsCopied/$scriptsTotal" -Fore Green

# Step 3: Config files
Write-Host "`n[3] Config sync" -ForegroundColor Cyan
$configFiles = @("AGENTS.md","ANTI-PATTERN-CATALOG.md","SKILLS-INDEX.md","CYCLE.md","BITACORA.md","review-rules.jsonc","PROJECT-SCORE.md","skills-lock.json")
$configCopied = 0
foreach ($cfgFile in $configFiles) { Sync-SingleFile -Src (Join-Path $repoRoot $cfgFile) -Dst (Join-Path $globalCfg $cfgFile) -IsDryRun:$DryRun -Count ([ref]$configCopied) }
# opencode.json/.jsonc: bootstrap-only — plant repo config ONLY if global target missing (never overwrite accumulated global settings; PS7 sync-global.ps1 owns updates, step [8] owns autoupdate)
foreach ($cfgFile in @("opencode.json","opencode.jsonc")) {
    $src = Join-Path $repoRoot $cfgFile; $dst = Join-Path $globalCfg $cfgFile
    if ((Test-Path $src -PathType Leaf) -and -not (Test-Path $dst)) {
        if ($DryRun) { Write-Host "  [dry-run] bootstrap $cfgFile" -Fore Yellow } else { Copy-Item -LiteralPath $src -Destination $dst -Force; Write-Host "  [bootstrapped] $cfgFile" -Fore Green; $configCopied++ }
    }
}
Write-Host "  Config: $configCopied/$($configFiles.Count)" -Fore Green

# Steps 4-6: Commands, Prompts, Plugins (identical pattern)
$syncSections = @(@{Name="Commands";Dir="commands"},@{Name="Prompts";Dir="prompts"},@{Name="Plugins";Dir="plugins"})
$stepNum = 4; foreach ($sec in $syncSections) {
    Write-Host "`n[$stepNum] $($sec.Name) sync" -ForegroundColor Cyan
    $count = 0; Sync-DirectoryFile -SrcDir (Join-Path $repoRoot $sec.Dir) -DstDir (Join-Path $globalCfg $sec.Dir) -IsDryRun:$DryRun -Count ([ref]$count)
    Write-Host "  $($sec.Name): $count" -Fore Green; $stepNum++
}

# Step 7: Verify junctions
Write-Host "`n[7] Verification" -ForegroundColor Cyan
$broken = 0
Get-ChildItem $dstSkills -Directory -EA SilentlyContinue | ForEach-Object { $t = Get-Item $_.FullName -Force -EA SilentlyContinue; if ($t.Target -and -not (Test-Path $t.Target)) { Write-Host "  [broken] $($_.Name)" -Fore Red; $broken++ } }
if ($broken -eq 0) { Write-Host "  All junctions valid" -Fore Green } else { Write-Host "  $broken broken junctions!" -Fore Red }

# [8] opencode binary health (ADR-048)
Write-Host "`n[8] opencode binary health" -ForegroundColor Cyan
$prefix=$null; try{ $r=& npm prefix -g 2>$null | Select-Object -First 1; if($r){ $prefix=$r.Trim() } if(-not $prefix){ throw "empty" } }catch{ $prefix=Join-Path $env:APPDATA "npm" }
$exe=Join-Path $prefix "node_modules\opencode-ai\bin\opencode.exe"; $postinstall=Join-Path $prefix "node_modules\opencode-ai\postinstall.mjs"
$ver=$null; $status="ok"
if(-not (Test-Path -LiteralPath $exe)){ $status="corrupt/missing" } else { try{ $o=& $exe --version 2>&1 | Out-String; $t=$o.Trim(); if($LASTEXITCODE -ne 0 -or $t -notmatch '^\d+\.\d+\.\d+'){ $status="corrupt/missing" } else { $m=[regex]::Match($t,'\d+\.\d+\.\d+'); if($m.Success){ $ver=$m.Value } else { $ver=$t } } }catch{ $status="corrupt/missing" } }
if($DryRun){ try{ $cp=Join-Path $globalCfg "opencode.json"; if(Test-Path $cp){ $gc=Get-Content $cp -Raw | ConvertFrom-Json; if($gc.PSObject.Properties.Match('autoupdate').Count -eq 0 -or $gc.autoupdate -eq $true){ Write-Host "  [dry-run] would patch autoupdate=false" -Fore Yellow } } }catch{ Write-Warning "  Could not check autoupdate: $_" }
} else { try{ $cp=Join-Path $globalCfg "opencode.json"; if(Test-Path $cp){ $gcRaw=Get-Content $cp -Raw | ConvertFrom-Json; if($gcRaw.PSObject.Properties.Match('autoupdate').Count -eq 0 -or $gcRaw.autoupdate -eq $true){ $gcRaw | Add-Member -MemberType NoteProperty -Name 'autoupdate' -Value $false -Force; $gcRaw | ConvertTo-Json -Depth 100 | Set-Content $cp -Encoding UTF8; Write-Host "  Patched autoupdate=false" -Fore Green } } }catch{ Write-Warning "  Could not patch autoupdate: $_" } }
if($status -eq "ok"){ Write-Host "  opencode: $ver" -Fore Green } else { Write-Host "  opencode: $status" -Fore Red }
if($status -ne "ok" -and -not $DryRun){ if(Get-Command pwsh -EA SilentlyContinue){ Write-Host "  healing via pwsh..." -Fore Yellow; try{ & pwsh -NoProfile -File (Join-Path $srcScripts "update-opencode.ps1") -HealOnly; if($LASTEXITCODE -eq 0){ Write-Host "  heal: ok" -Fore Green } else { Write-Host "  heal: failed (exit $LASTEXITCODE)" -Fore Red } }catch{ Write-Warning "  heal failed: $_" } } else { Write-Warning "  binary corrupt and pwsh not available — run: node `"$postinstall`"" }
} elseif($status -ne "ok" -and $DryRun){ if(Get-Command pwsh -EA SilentlyContinue){ Write-Host "  [dry-run] would heal via pwsh" -Fore Yellow } else { Write-Host "  [dry-run] would heal via node postinstall (pwsh not available)" -Fore Yellow } }

# Summary
Write-Host "`n=== Summary ===" -Fore Cyan
Write-Host "  Skills: $skillsCreated new | Scripts: $scriptsCopied | Config: $configCopied | Status: OK" -Fore Green
