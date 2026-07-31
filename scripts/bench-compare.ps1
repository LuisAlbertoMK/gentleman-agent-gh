#requires -Version 5.1
<#
.SYNOPSIS
    Benchmark comparativo: backup pre-sprint3 vs gentleman-agent-gh (actual)
#>
param(
  [string]$BDir = (Join-Path (Join-Path $HOME ".config") "opencode" ".bak" "pre-sprint3-apply-20260607-005330"),
  [string]$RDir = "$PSScriptRoot\.."
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$RDir = (Resolve-Path $RDir).Path
try {
function Get-Line { param($P) try { if (test-path $P) { (Get-Content $P -EA Stop | Measure-Object -Line).Lines } else { 0 } } catch { Write-Warning "GL $($P): $_"; 0 } }
function Get-Byte { param($P) try { if (test-path $P) { (Get-Item $P -EA Stop).Length } else { 0 } } catch { Write-Warning "GB $($P): $_"; 0 } }
Write-Host "<<< AGENTS.md 3-way >>>"
$bA = Join-Path $BDir "AGENTS.md"
$rA = Join-Path $RDir "AGENTS.md"
$gA = Join-Path (Get-GlobalConfigDir) "AGENTS.md"
Write-Host ("  vMK (Go): ?L")
Write-Host ("  Backup: " + (Get-Line $bA) + "L, " + (Get-Byte $bA) + "B")
Write-Host ("  Repo:   " + (Get-Line $rA) + "L, " + (Get-Byte $rA) + "B")
if (test-path $gA) { Write-Host ("  Global: " + (Get-Line $gA) + "L, " + (Get-Byte $gA) + "B") }
Write-Host "<<< Skills - line count >>>"
$bSD = Join-Path $BDir "skills"
$rSD = Join-Path (Join-Path $RDir ".agents") "skills"
try { $bSk = Get-ChildItem -Directory -LiteralPath $bSD -EA Stop | ForEach-Object { $_.Name } } catch { Write-Warning "b skills $($bSD): $_"; $bSk = @() }
try { $rSk = Get-ChildItem -Directory -LiteralPath $rSD -EA Stop | ForEach-Object { $_.Name } } catch { Write-Warning "r skills $($rSD): $_"; $rSk = @() }
$c = $bSk | Where-Object { $rSk -contains $_ }
$oB = $bSk | Where-Object { $rSk -notcontains $_ }
$oR = $rSk | Where-Object { $bSk -notcontains $_ }
$tB = 0; $tR = 0
foreach ($s in $c) { $tB += (Get-Line (Join-Path $bSD "$s\SKILL.md")); $tR += (Get-Line (Join-Path $rSD "$s\SKILL.md")) }
$dL = $tR - $tB
$pC = if ($tB -gt 0) { [math]::Round($dL / $tB * 100, 1) } else { 0 }
Write-Host ("  Common: " + $c.Count + " | B: " + $tB + "L | R: " + $tR + "L | D: " + $dL + "L (" + $pC + "%)")
Write-Host ("  B-only: " + $oB.Count + " | R-only: " + $oR.Count)
Write-Host "<<< Skills - metadata >>>"
$bP = 0; $rP = 0; $bTr = 0; $rTr = 0; $bTa = 0; $rTa = 0
function Test-SkillMeta {
    param([string]$SkillPath)
    try { $content = Get-Content $SkillPath -Raw -EA Stop } catch { return @{ Placeholder = $false; HasTriggers = $false; HasTags = $false } }
    return @{
        Placeholder = $content -match 'description:\s*>\s+\{?\w+\}?\s*skill'
        HasTriggers = $content -match '(?m)^\s*triggers:'
        HasTags     = $content -match '(?m)^\s*tags:'
    }
}
foreach ($s in $bSk) {
  $m = Test-SkillMeta -SkillPath (Join-Path $bSD "$s\SKILL.md")
  if ($m.Placeholder) { $bP++ }
  if ($m.HasTriggers) { $bTr++ }
  if ($m.HasTags)    { $bTa++ }
}
foreach ($s in $rSk) {
  $m = Test-SkillMeta -SkillPath (Join-Path $rSD "$s\SKILL.md")
  if ($m.Placeholder) { $rP++ }
  if ($m.HasTriggers) { $rTr++ }
  if ($m.HasTags)    { $rTa++ }
}
Write-Host ("  Placeh: B " + $bP + " -> R " + $rP)
Write-Host ("  Triggr: B " + $bTr + "/" + $bSk.Count + " -> R " + $rTr + "/" + $rSk.Count)
Write-Host ("  Tags:   B " + $bTa + "/" + $bSk.Count + " -> R " + $rTa + "/" + $rSk.Count)
Write-Host ("  Descr real: B NO -> R SI")
Write-Host "<<< Scripts >>>"
$bSd = Join-Path $BDir "scripts"
$rSd = Join-Path $RDir "scripts"
if (test-path $bSd) { try { $bs = (Get-ChildItem -Filter "*.ps1" -LiteralPath $bSd -EA Stop).Count } catch { $bs = 0 } } else { $bs = 0 }
try { $rs = (Get-ChildItem -Filter "*.ps1" -LiteralPath $rSd -EA Stop).Count } catch { Write-Warning "r scripts $($rSd): $_"; $rs = 0 }
$sm = 0; $ct = 0
try { $sf = Get-ChildItem -Filter "*.ps1" -LiteralPath $rSd -EA Stop } catch { Write-Warning "r scripts dir $($rSd): $_"; $sf = @() }
foreach ($f in $sf) {
  try { $cc = Get-Content $f.FullName -Raw -EA Stop } catch { continue }
  if ($cc -match 'Set-StrictMode') { $sm++ }
  # Count catch blocks from cached content (avoids 2nd file read via Select-String -Path)
  $ct += [regex]::Matches($cc, '\bcatch\b').Count
}
Write-Host ("  Scripts: B " + $bs + " -> R " + $rs)
Write-Host ("  StrictMd: B 0 -> R " + $sm + "/" + $rs)
Write-Host ("  catche:  B 0 -> R " + $ct)
Write-Host "<<< Infra (no existía en backup) >>>"
$tsP = Join-Path $RDir "scripts\skill-test-suite.ps1"
$qgP = Join-Path $RDir ".githooks\pre-commit"
$crP = Join-Path $RDir "scripts\cross-ref-check.ps1"
$tsS = if (test-path $tsP) { "EXISTS (" + (Get-Line $tsP) + "L)" } else { "MISSING" }
$qgS = if (test-path $qgP) { "EXISTS (4 checks)" } else { "MISSING" }
$crS = if (test-path $crP) { "EXISTS (" + (Get-Line $crP) + "L)" } else { "MISSING" }
Write-Host ("  Test suite: " + $tsS)
Write-Host ("  QGate:      " + $qgS)
Write-Host ("  Cross-ref:  " + $crS)
$dL2 = $tR - $tB
$pC2 = if ($tB -gt 0) { [math]::Round($dL2 / $tB * 100, 1) } else { 0 }
Write-Host "<<< SUMMARY >>>"
Write-Host ("  Common: " + $c.Count + " | " + $tB + "L -> " + $tR + "L (" + $pC2 + "%)")
Write-Host ("  Placeh: " + $bP + " -> " + $rP)
Write-Host ("  Triggr: " + $bTr + " -> " + $rTr)
Write-Host ("  Tags:   " + $bTa + " -> " + $rTa)
Write-Host ("  Scripts: " + $bs + " -> " + $rs + " (SM: " + $sm + "/" + $rs + ")")
Write-Host ("  Tests:  " + $tsS)
Write-Host ("  QGate:  " + $qgS)
} catch {
  Write-Error "Benchmark failed: $_"
  exit 1
}
