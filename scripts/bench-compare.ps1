<#
.SYNOPSIS
  Benchmark comparativo: backup pre-sprint3 vs gentleman-agent-gh (actual)
#>
param(
  [string]$BDir = "$env:USERPROFILE\.config\opencode\.bak\pre-sprint3-apply-20260607-005330",
  [string]$RDir = "$PSScriptRoot\.."
)
$ErrorActionPreference = 'Stop'
$RDir = (rvpa $RDir).Path
try {
function Get-Line { param($P) try { if (test-path $P) { (gc $P -EA Stop | measure -Line).Lines } else { 0 } } catch { Write-Warning "GL $P: $_"; 0 } }
function Get-Byte { param($P) try { if (test-path $P) { (gi $P -EA Stop).Length } else { 0 } } catch { Write-Warning "GB $P: $_"; 0 } }
Write-Host "<<< AGENTS.md 3-way >>>"
$bA = Join-Path $BDir "AGENTS.md"
$rA = Join-Path $RDir "AGENTS.md"
$gA = "$env:USERPROFILE\.config\opencode\AGENTS.md"
Write-Host ("  vMK (Go): ?L")
Write-Host ("  Backup: " + (Get-Line $bA) + "L, " + (Get-Byte $bA) + "B")
Write-Host ("  Repo:   " + (Get-Line $rA) + "L, " + (Get-Byte $rA) + "B")
if (test-path $gA) { Write-Host ("  Global: " + (Get-Line $gA) + "L, " + (Get-Byte $gA) + "B") }
Write-Host "<<< Skills - line count >>>"
$bSD = Join-Path $BDir "skills"
$rSD = Join-Path (Join-Path $RDir ".agents") "skills"
try { $bSk = gci -Dir -Lit $bSD -EA Stop | % { $_.Name } } catch { Write-Warning "b skills $bSD: $_"; $bSk = @() }
try { $rSk = gci -Dir -Lit $rSD -EA Stop | % { $_.Name } } catch { Write-Warning "r skills $rSD: $_"; $rSk = @() }
$c = $bSk | ? { $rSk -contains $_ }
$oB = $bSk | ? { $rSk -notcontains $_ }
$oR = $rSk | ? { $bSk -notcontains $_ }
$tB = 0; $tR = 0
foreach ($s in $c) { $tB += (Get-Line (Join-Path $bSD "$s\SKILL.md")); $tR += (Get-Line (Join-Path $rSD "$s\SKILL.md")) }
$dL = $tR - $tB
$pC = if ($tB -gt 0) { [math]::Round($dL / $tB * 100, 1) } else { 0 }
Write-Host ("  Common: " + $c.Count + " | B: " + $tB + "L | R: " + $tR + "L | D: " + $dL + "L (" + $pC + "%)")
Write-Host ("  B-only: " + $oB.Count + " | R-only: " + $oR.Count)
Write-Host "<<< Skills - metadata >>>"
$bP = 0; $rP = 0; $bTr = 0; $rTr = 0; $bTa = 0; $rTa = 0
foreach ($s in $bSk) {
  try { $c2 = gc (Join-Path $bSD "$s\SKILL.md") -Raw -EA Stop } catch { Write-Warning "b SKILL.md $s: $_"; continue }
  if ($c2 -match 'description:\s*>\s+\{?\w+\}?\s*skill') { $bP++ }
  if ($c2 -match '(?m)^\s*triggers:') { $bTr++ }
  if ($c2 -match '(?m)^\s*tags:') { $bTa++ }
}
foreach ($s in $rSk) {
  try { $c3 = gc (Join-Path $rSD "$s\SKILL.md") -Raw -EA Stop } catch { Write-Warning "r SKILL.md $s: $_"; continue }
  if ($c3 -match 'description:\s*>\s+\{?\w+\}?\s*skill') { $rP++ }
  if ($c3 -match '(?m)^\s*triggers:') { $rTr++ }
  if ($c3 -match '(?m)^\s*tags:') { $rTa++ }
}
Write-Host ("  Placeh: B " + $bP + " -> R " + $rP)
Write-Host ("  Triggr: B " + $bTr + "/" + $bSk.Count + " -> R " + $rTr + "/" + $rSk.Count)
Write-Host ("  Tags:   B " + $bTa + "/" + $bSk.Count + " -> R " + $rTa + "/" + $rSk.Count)
Write-Host ("  Descr real: B NO -> R SI")
Write-Host "<<< Scripts >>>"
$bSd = Join-Path $BDir "scripts"
$rSd = Join-Path $RDir "scripts"
if (test-path $bSd) { try { $bs = (gci -Filter "*.ps1" -Lit $bSd -EA Stop).Count } catch { $bs = 0 } } else { $bs = 0 }
try { $rs = (gci -Filter "*.ps1" -Lit $rSd -EA Stop).Count } catch { Write-Warning "r scripts $rSd: $_"; $rs = 0 }
$sm = 0; $ct = 0
try { $sf = gci -Filter "*.ps1" -Lit $rSd -EA Stop } catch { Write-Warning "r scripts dir $rSd: $_"; $sf = @() }
foreach ($f in $sf) {
  try { $cc = gc $f.FullName -Raw -EA Stop } catch { continue }
  if ($cc -match 'Set-StrictMode') { $sm++ }
  $ct += (sls '\bcatch\b' -Lit $f.FullName).Count
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
