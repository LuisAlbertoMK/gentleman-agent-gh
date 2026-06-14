<#
.SYNOPSIS
  Check skill drift between project skills/ and global config (~/.config/opencode/skills/).
  Detects stale copies before they cause issues.

.DESCRIPTION
  Compares line counts (quick) or content hashes (thorough) between:
  - D:\gentleman-agent-gh\skills\ (project mirror)
  - C:\Users\MK\.config\opencode\skills\ (global config)

  Flags any skill where project != global.
  Returns exit code 0 = all in sync, 1 = drift detected.

.PARAMETER Thorough
  Use content hash comparison (slower but accurate). Default: line count comparison (fast).

.PARAMETER AutoFix
  Copy global version to project for any drift found.

.PARAMETER Json
  Output results as JSON.

.EXAMPLE
  .\scripts\check-skill-drift.ps1
  .\scripts\check-skill-drift.ps1 -Thorough
  .\scripts\check-skill-drift.ps1 -AutoFix
  .\scripts\check-skill-drift.ps1 -Json
#>

param(
  [switch]$Thorough,
  [switch]$AutoFix,
  [switch]$Json
)

$projectDir = "D:\gentleman-agent-gh\skills"
$globalDir = "C:\Users\MK\.config\opencode\skills"
$errors = @()
$drifted = @()

if (-not (Test-Path $projectDir)) { Write-Error "Project skills dir not found: $projectDir"; exit 2 }
if (-not (Test-Path $globalDir)) { Write-Error "Global skills dir not found: $globalDir"; exit 2 }

$projectSkills = Get-ChildItem $projectDir -Directory

foreach ($skill in $projectSkills) {
  $projPath = Join-Path -Path $projectDir -ChildPath "$($skill.Name)\SKILL.md"
  $globPath = Join-Path -Path $globalDir -ChildPath "$($skill.Name)\SKILL.md"

  if (-not (Test-Path $globPath)) {
    $errors += [PSCustomObject]@{ Skill=$skill.Name; Status="GLOBAL_MISSING"; Detail="Global has no $($skill.Name)/SKILL.md" }
    continue
  }

  if (-not (Test-Path $projPath)) {
    $errors += [PSCustomObject]@{ Skill=$skill.Name; Status="PROJECT_MISSING"; Detail="Project has no $($skill.Name)/SKILL.md" }
    continue
  }

  if ($skill.LinkType -eq "Junction") {
    # Junction skills are auto-synced by definition - verify target exists
    $target = $skill.Target
    $targetOk = Test-Path (Join-Path -Path $target -ChildPath "SKILL.md")
    if (-not $targetOk) {
      $errors += [PSCustomObject]@{ Skill=$skill.Name; Status="JUNCTION_BROKEN"; Detail="Junction target missing: $target" }
    }
    continue  # junctions are always in sync, skip comparison
  }

  # Compare real files
  if ($Thorough) {
    $projHash = (Get-FileHash -LiteralPath $projPath -Algorithm MD5).Hash
    $globHash = (Get-FileHash -LiteralPath $globPath -Algorithm MD5).Hash
    $match = $projHash -eq $globHash
  } else {
    $projLines = (Get-Content $projPath | Measure-Object -Line).Lines
    $globLines = (Get-Content $globPath | Measure-Object -Line).Lines
    $match = $projLines -eq $globLines
  }

  if (-not $match) {
    $projSize = (Get-Item $projPath).Length
    $globSize = (Get-Item $globPath).Length
    $drifted += [PSCustomObject]@{
      Skill = $skill.Name
      ProjectSize = if ($Thorough) { $projHash } else { "$projLines lines" }
      GlobalSize  = if ($Thorough) { $globHash } else { "$globLines lines" }
      Status = "DRIFT"
    }
  }
}

# AutoFix: copy global to project for drifted files
if ($AutoFix -and $drifted.Count -gt 0) {
  Write-Output "Auto-fixing $($drifted.Count) drifted skills..."
  foreach ($d in $drifted) {
    $src = Join-Path -Path $globalDir -ChildPath "$($d.Skill)\SKILL.md"
    $dst = Join-Path -Path $projectDir -ChildPath "$($d.Skill)\SKILL.md"
    Copy-Item -LiteralPath $src -Destination $dst -Force
    Write-Output "  Fixed: $($d.Skill)"
  }
  # Re-scan to confirm
  $drifted = @()
  # Re-run the check logic (simplified inline)
  foreach ($skill in $projectSkills) {
    if ($skill.LinkType -eq "Junction") { continue }
    $projPath = Join-Path -Path $projectDir -ChildPath "$($skill.Name)\SKILL.md"
    $globPath = Join-Path -Path $globalDir -ChildPath "$($skill.Name)\SKILL.md"
    if ((Test-Path $projPath) -and (Test-Path $globPath)) {
      $projLines = (Get-Content $projPath | Measure-Object -Line).Lines
      $globLines = (Get-Content $globPath | Measure-Object -Line).Lines
      if ($projLines -ne $globLines) {
        $drifted += $skill.Name
      }
    }
  }
  if ($drifted.Count -eq 0) { Write-Output "  All fixed!" }
}

# --- Output ---
$result = @{
  timestamp = (Get-Date -Format "o")
  totalSkills = $projectSkills.Count
  junctionSkills = ($projectSkills | Where-Object { $_.LinkType -eq "Junction" }).Count
  realFileSkills = ($projectSkills | Where-Object { $_.LinkType -ne "Junction" }).Count
  drifted = $drifted
  errors = $errors
  allSynced = ($drifted.Count -eq 0 -and $errors.Count -eq 0)
}

if ($Json) {
  Write-Output ($result | ConvertTo-Json -Depth 3)
} else {
  if ($result.allSynced) {
    Write-Output "`n✅ ALL $($result.totalSkills) skills in sync!"
    Write-Output "   ($($result.junctionSkills) junctions auto-synced, $($result.realFileSkills) real files verified)"
  } else {
    if ($drifted.Count -gt 0) {
      Write-Output "`n⚠️ DRIFT DETECTED: $($drifted.Count) skills out of sync"
      $drifted | Format-Table Skill, ProjectSize, GlobalSize, Status -AutoSize
    }
    if ($errors.Count -gt 0) {
      Write-Output "`n❌ ERRORS: $($errors.Count)"
      $errors | Format-Table Skill, Status, Detail -AutoSize
    }
    exit 1
  }
}
