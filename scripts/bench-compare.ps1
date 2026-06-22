<#
.SYNOPSIS
  Benchmark comparativo: backup pre-sprint3 vs gentleman-agent-gh (actual)
.DESCRIPTION
  Reproduce la comparación oficial entre el backup pre-sprint3 (baseline)
  y el estado actual del repo. Genera salida formateada en consola.
.PARAMETER BackupDir
  Ruta al backup pre-sprint3. Default: $env:USERPROFILE\.config\opencode\.bak\pre-sprint3-apply-20260607-005330\
.PARAMETER RepoDir
  Ruta al repo gentleman-agent-gh. Default: D:\gentleman-agent-gh
.EXAMPLE
  .\scripts\bench-compare.ps1
  .\scripts\bench-compare.ps1 -BackupDir "C:\custom\backup" -RepoDir "D:\repo"
#>

param(
  [string]$BackupDir = "$env:USERPROFILE\.config\opencode\.bak\pre-sprint3-apply-20260607-005330",
  [string]$RepoDir = "$PSScriptRoot\.."
)

$ErrorActionPreference = 'Stop'
$RepoDir = (Resolve-Path $RepoDir).Path

try {

# --- Helper ---
function Get-Line { param($Path) try { if (Test-Path $Path) { (Get-Content $Path -ErrorAction Stop | Measure-Object -Line).Lines } else { 0 } } catch { Write-Warning "Get-Line failed for $Path\`: $_"; 0 } }
function Get-Byte { param($Path) try { if (Test-Path $Path) { (Get-Item $Path -ErrorAction Stop).Length } else { 0 } } catch { Write-Warning "Get-Byte failed for $Path\`: $_"; 0 } }

# --- TITLE ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  BENCHMARK: Backup pre-sprint3 vs gentleman-agent-gh" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ("  Backup: " + $BackupDir) -ForegroundColor Gray
Write-Host ("  Repo:   " + $RepoDir) -ForegroundColor Gray
Write-Host "========================================================`n" -ForegroundColor Cyan

# --- 1. AGENTS.md ---
Write-Host "<<< AGENTS.md 3-way >>>" -ForegroundColor Yellow
$backupAgents = Join-Path $BackupDir "AGENTS.md"
$repoAgents = Join-Path $RepoDir "AGENTS.md"
$globalAgents = "$env:USERPROFILE\.config\opencode\AGENTS.md"

Write-Host ("  gentleman-vMK template (Go): ? lines (no disponible localmente)")
Write-Host ("  Backup pre-sprint3:      " + (Get-Line $backupAgents) + " lines, " + (Get-Byte $backupAgents) + " bytes")
Write-Host ("  gentleman-agent-gh:      " + (Get-Line $repoAgents) + " lines, " + (Get-Byte $repoAgents) + " bytes")
if (Test-Path $globalAgents) {
    Write-Host ("  Global ~/.config/opencode: " + (Get-Line $globalAgents) + " lines, " + (Get-Byte $globalAgents) + " bytes")
}
Write-Host ""

# --- 2. Skills total ---
Write-Host "<<< Skills - line count >>>" -ForegroundColor Yellow
$backupSkillsDir = Join-Path $BackupDir "skills"
$repoSkillsDir = Join-Path (Join-Path $RepoDir ".agents") "skills"

try { $backupSkills = Get-ChildItem -Directory -LiteralPath $backupSkillsDir -ErrorAction Stop | ForEach-Object { $_.Name } } catch { Write-Warning "Could not read backup skills dir $backupSkillsDir\`: $_"; $backupSkills = @() }
try { $repoSkills = Get-ChildItem -Directory -LiteralPath $repoSkillsDir -ErrorAction Stop | ForEach-Object { $_.Name } } catch { Write-Warning "Could not read repo skills dir $repoSkillsDir\`: $_"; $repoSkills = @() }
$common = $backupSkills | Where-Object { $repoSkills -contains $_ }
$onlyBackup = $backupSkills | Where-Object { $repoSkills -notcontains $_ }
$onlyRepo = $repoSkills | Where-Object { $backupSkills -notcontains $_ }

$totalBackupLines = 0; $totalRepoLines = 0
foreach ($s in $common) {
    $totalBackupLines += (Get-Line (Join-Path $backupSkillsDir "$s\SKILL.md"))
    $totalRepoLines += (Get-Line (Join-Path $repoSkillsDir "$s\SKILL.md"))
}
Write-Host ("  Common skills: " + $common.Count + " | Backup: " + $totalBackupLines + "L | Repo: " + $totalRepoLines + "L | Delta: " + ($totalRepoLines - $totalBackupLines) + "L (" + [math]::Round(($totalRepoLines - $totalBackupLines) / $totalBackupLines * 100, 1) + "%)")
Write-Host ("  Backup-only skills: " + $onlyBackup.Count + " | Repo-only: " + $onlyRepo.Count)

# --- 3. Metadata ---
Write-Host "`n<<< Skills - metadata >>>" -ForegroundColor Yellow
$backupPlaceholders = 0; $repoPlaceholders = 0
$backupTriggers = 0; $repoTriggers = 0
$backupTags = 0; $repoTags = 0

foreach ($s in $backupSkills) {
    try { $c = Get-Content (Join-Path $backupSkillsDir "$s\SKILL.md") -Raw -ErrorAction Stop } catch { Write-Warning "Could not read backup SKILL.md for $s\`: $_"; continue }
    if ($c -match 'description:\s*>\s+\{?\w+\}?\s*skill') { $backupPlaceholders++ }
    if ($c -match '(?m)^\s*triggers:') { $backupTriggers++ }
    if ($c -match '(?m)^\s*tags:') { $backupTags++ }
}
foreach ($s in $repoSkills) {
    try { $c = Get-Content (Join-Path $repoSkillsDir "$s\SKILL.md") -Raw -ErrorAction Stop } catch { Write-Warning "Could not read repo SKILL.md for $s\`: $_"; continue }
    if ($c -match 'description:\s*>\s+\{?\w+\}?\s*skill') { $repoPlaceholders++ }
    if ($c -match '(?m)^\s*triggers:') { $repoTriggers++ }
    if ($c -match '(?m)^\s*tags:') { $repoTags++ }
}

Write-Host ("  Placeholders:       Backup " + $backupPlaceholders + " -> Repo " + $repoPlaceholders)
Write-Host ("  Triggers field:     Backup " + $backupTriggers + "/" + $backupSkills.Count + " -> Repo " + $repoTriggers + "/" + $repoSkills.Count)
Write-Host ("  Tags field:         Backup " + $backupTags + "/" + $backupSkills.Count + " -> Repo " + $repoTags + "/" + $repoSkills.Count)
Write-Host ("  Descriptions reales: Backup NO → Repo SI")

# --- 4. Scripts ---
Write-Host "`n<<< Scripts >>>" -ForegroundColor Yellow
$backupScriptsDir = Join-Path $BackupDir "scripts"
$repoScriptsDir = Join-Path $RepoDir "scripts"

if (Test-Path $backupScriptsDir) {
    try { $bs = (Get-ChildItem -Filter "*.ps1" -LiteralPath $backupScriptsDir -ErrorAction Stop).Count } catch { Write-Warning "Could not list backup scripts dir $backupScriptsDir\`: $_"; $bs = 0 }
} else { $bs = 0 }
try { $rs = (Get-ChildItem -Filter "*.ps1" -LiteralPath $repoScriptsDir -ErrorAction Stop).Count } catch { Write-Warning "Could not list repo scripts dir $repoScriptsDir\`: $_"; $rs = 0 }

$strictMode = 0; $catches = 0
try { $scriptFiles = Get-ChildItem -Filter "*.ps1" -LiteralPath $repoScriptsDir -ErrorAction Stop } catch { Write-Warning "Could not read repo scripts dir $repoScriptsDir\`: $_"; $scriptFiles = @() }
foreach ($f in $scriptFiles) {
    try { $c = Get-Content $f.FullName -Raw -ErrorAction Stop } catch { Write-Warning "Could not read $($f.FullName)\`: $_"; continue }
    if ($c -match 'Set-StrictMode') { $strictMode++ }
    $catches += (Select-String -Pattern '\bcatch\b' -LiteralPath $f.FullName).Count
}

Write-Host ("  Scripts PS:         Backup " + $bs + " -> Repo " + $rs)
Write-Host ("  Set-StrictMode:     Backup 0 -> Repo " + $strictMode + "/" + $rs)
Write-Host ("  catch blocks:       Backup 0 -> Repo " + $catches)

# --- 5. Infra ---
Write-Host "`n<<< Infraestructura (no existía en backup) >>>" -ForegroundColor Yellow
$testSuite = "scripts\skill-test-suite.ps1"
$qualityGate = ".githooks\pre-commit"
$crossRef = "scripts\cross-ref-check.ps1"
$tsPath = Join-Path $RepoDir $testSuite
$qgPath = Join-Path $RepoDir $qualityGate
$crPath = Join-Path $RepoDir $crossRef
$tsStatus = if (Test-Path $tsPath) { "EXISTS (" + (Get-Line $tsPath) + "L)" } else { "MISSING" }
$qgStatus = if (Test-Path $qgPath) { "EXISTS (4 checks)" } else { "MISSING" }
$crStatus = if (Test-Path $crPath) { "EXISTS (" + (Get-Line $crPath) + "L)" } else { "MISSING" }
Write-Host ("  Test suite:         " + $tsStatus)
Write-Host ("  Quality gate:       " + $qgStatus)
Write-Host ("  Cross-ref check:    " + $crStatus)

# --- SUMMARY ---
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host "  SUMMARY" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ("  Common skills:     " + $common.Count + " | Compaction: " + $totalBackupLines + "L -> " + $totalRepoLines + "L (" + [math]::Round(($totalRepoLines - $totalBackupLines) / $totalBackupLines * 100, 1) + "%)")
Write-Host ("  Placeholders:      " + $backupPlaceholders + " -> " + $repoPlaceholders)
Write-Host ("  Triggers:          " + $backupTriggers + " -> " + $repoTriggers)
Write-Host ("  Tags:              " + $backupTags + " -> " + $repoTags)
Write-Host ("  Scripts:           " + $bs + " -> " + $rs + " (StrictMode: " + $strictMode + "/" + $rs + ")")
Write-Host ("  Test suite:        " + $tsStatus)
Write-Host ("  Quality gate:      " + $qgStatus)
Write-Host "========================================================`n" -ForegroundColor Green
} catch {
    Write-Error "Benchmark failed: $_"
    exit 1
}
