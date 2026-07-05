#requires -Version 7.6
<#
.SYNOPSIS Validate internal refs (skills, SKILLS-INDEX, junctions, shared).
#>
param([string]$RepoRoot=(Split-Path $PSScriptRoot -Parent),[switch]$Json,[switch]$Quiet)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';if($Quiet){$Json=$true}
$e=@();$w=@();$cd=Join-Path $RepoRoot ".agents\skills";$gd=(Join-Path $(if($env:USERPROFILE){$env:USERPROFILE}else{$env:HOME}) ".config/opencode/skills")
if(-not(Test-Path $cd)){if(-not $Quiet){Write-Host "FATAL: missing $cd"-ForegroundColor Red};exit 1}
if(-not $Quiet){Write-Host "[1/8] APC..."-N};$apc=Test-Path(Join-Path $RepoRoot "ANTI-PATTERN-CATALOG.md")
if($apc){if(-not $Quiet){Write-Host " OK"}}else{$e+="APC not found";if(-not $Quiet){Write-Host " FAIL"}}
if(-not $Quiet){Write-Host "[2/8] SKILL.md..."-N};$sb_ms = [System.Text.StringBuilder]::new(65536)
try{$sd=Get-ChildItem (Join-Path $cd "*") -Directory}catch{if(-not $Quiet){Write-Host " FAIL`nFATAL: list: $_"-ForegroundColor Red};exit 1}
$sd | ForEach-Object {$n=$_.Name;if($n -eq '_shared'){return};if(-not(Test-Path(Join-Path $_.FullName "SKILL.md"))){$null = $sb_ms.AppendLine($n)}}
$ms = @($sb_ms.ToString() -split '\r?\n' | Where-Object { $_ })
if($ms.Count -eq 0){if(-not $Quiet){Write-Host " OK (all)"}}else{$w+="Missing SKILL.md: $($ms-join', ')";if(-not $Quiet){Write-Host " WARN"}}
if(-not $Quiet){Write-Host "[3/8] INDEX count..."-N};$ac=$sd.Where({$_.Name -ne '_shared'}).Count
$hl=Select-String -Path (Join-Path $RepoRoot "SKILLS-INDEX.md") -Pattern "all \d+ skills"
if($hl-match"all (\d+) skills"){$dc=[int]$Matches[1];if($dc -eq $ac){if(-not $Quiet){Write-Host " OK ($ac)"}}else{$e+="INDEX says $dc, has $ac";if(-not $Quiet){Write-Host " FAIL ($dc vs $ac)"}}}else{$w+="INDEX header mismatch";if(-not $Quiet){Write-Host " WARN"}}
if(-not $Quiet){Write-Host "[4/8] junctions..."-N};$sb_mg = [System.Text.StringBuilder]::new(65536)
if(Test-Path $gd){(Get-ChildItem $cd -Directory).Where({$_.Name -ne '_shared'}) | ForEach-Object {$gp=Join-Path $gd $_.Name;if(-not(Test-Path $gp)){$null = $sb_mg.AppendLine($_.Name)}}}
$mg = @($sb_mg.ToString() -split '\r?\n' | Where-Object { $_ })
if($mg.Count -eq 0){if(-not $Quiet){Write-Host " OK (all)"}}else{$w+="Missing junctions: $($mg-join', ')";if(-not $Quiet){Write-Host " WARN"}}
if(-not $Quiet){Write-Host "[5/8] _shared..."-N}
$sf=@{'skill-resolver.md'=Test-Path(Join-Path $cd "_shared\skill-resolver.md");'sdd-phase-common.md'=Test-Path(Join-Path $cd "sdd\references\sdd-phase-common.md");'persistence-contract.md'=Test-Path(Join-Path $cd "_shared\persistence-contract.md");'engram-convention.md'=Test-Path(Join-Path $cd "_shared\engram-convention.md")}
$mh=@($sf.GetEnumerator().Where({-not $_.Value}) | ForEach-Object {$_.Key})
if($mh.Count -eq 0){if(-not $Quiet){Write-Host " OK"}}else{$e+="Missing _shared: $($mh-join', ')";if(-not $Quiet){Write-Host " FAIL"}}
if(-not $Quiet){Write-Host "[6/8] cross-refs..."-N};$sb_br = [System.Text.StringBuilder]::new(65536)
$al=($sd.Where({$_.Name -ne '_shared'}) | ForEach-Object {$_.Name.ToLower()});$rp='Cross-Refs:\s*(.+)';$ap='Anti-Patterns:\s*(.+)'
(Get-ChildItem $cd -Directory).Where({$_.Name -ne '_shared'}) | ForEach-Object {$sn=$_.Name;$mp=Join-Path $_.FullName "SKILL.md";if(-not(Test-Path $mp)){return};try{$c=[IO.File]::ReadAllText($mp)}catch{return};if($c -match $rp){$rf=($Matches[1]-split'\s*[\|,]\s*' | ForEach-Object {$_.Trim()}).Where({$_ -cmatch '^[a-z][a-z0-9_-]+$'});$rf | ForEach-Object {if($al -notcontains $_){$null = $sb_br.AppendLine("$sn cross-refs '$_' missing")}}};if($c -match $ap){$ax=($Matches[1]-split'\s*[\|,]\s*' | ForEach-Object {$_.Trim()}).Where({$_ -cmatch '^[a-z][a-z0-9_-]+$'});$ax | ForEach-Object {if($al -notcontains $_){$null = $sb_br.AppendLine("$sn anti-refs '$_' missing")}}}}
$br = @($sb_br.ToString() -split '\r?\n' | Where-Object { $_ })
if($br.Count -eq 0){if(-not $Quiet){Write-Host " OK"}}else{$e+=$br;if(-not $Quiet){Write-Host " FAIL ($($br.Count))"}}
if(-not $Quiet){Write-Host "[7/8] config_refs..."-N};$sb_mc = [System.Text.StringBuilder]::new(65536);$crp='config_refs:\s*(.+)'
(Get-ChildItem $cd -Directory).Where({$_.Name -ne '_shared'}) | ForEach-Object {$sn=$_.Name;$mp=Join-Path $_.FullName "SKILL.md";if(-not(Test-Path $mp)){return};try{$c=[IO.File]::ReadAllText($mp)}catch{return};if($c -match $crp){$rf=($Matches[1]-split'\s*[\|,]\s*' | ForEach-Object {$_.Trim()}).Where({$_ -ne ''});$rf | ForEach-Object {$rp2=Join-Path $RepoRoot $_;if(-not(Test-Path $rp2)){$null = $sb_mc.AppendLine("$sn config_refs '$_' missing at $rp2")}}}}
$mc = @($sb_mc.ToString() -split '\r?\n' | Where-Object { $_ })
if($mc.Count -eq 0){if(-not $Quiet){Write-Host " OK"}}else{$e+=$mc;if(-not $Quiet){Write-Host " FAIL ($($mc.Count))"}}
if(-not $Quiet){Write-Host "[8/8] review-rules.jsonc..."-N};$rk=Join-Path $RepoRoot "review-rules.jsonc"
if(Test-Path $rk){try{$b=Get-Content $rk -Raw -Encoding UTF8;$s=$b-replace'(?m)^\s*//.*$',''-replace'(?m)\s*//[^"\n]*$',''-replace'(?s)/\*.*?\*/','';$p=$s | ConvertFrom-Json;$zc=$p.zones.PSObject.Properties.Name.Count;$cc=$p.context_zones.PSObject.Properties.Name.Count;$md=$p.modes.PSObject.Properties.Name.Count;$pc=$p.jd_profiles.PSObject.Properties.Name.Count;$sc=$p.jd_profile_selector.Count;$is=@();if($zc -ne 3){$is+="zones $zc"};if($cc -ne 4){$is+="ctx $cc"};if($md -ne 5){$is+="modes $md"};if($pc -lt 1){$is+="profiles $pc"};if($sc -lt 1){$is+="selectors $sc"};if($is.Count -eq 0){if(-not $Quiet){Write-Host " OK (z$zc c$cc m$md p$pc s$sc)"}}else{$e+="review-rules.jsonc: $($is-join'; ')";if(-not $Quiet){Write-Host " FAIL"}}}catch{$e+="review-rules.jsonc parse: $_";if(-not $Quiet){Write-Host " FAIL"}}}else{$w+="review-rules.jsonc missing";if(-not $Quiet){Write-Host " WARN"}}
$res=@{timestamp=(Get-Date -Format "o");canonicalSkills=$ac;errors=$e;warnings=$w;brokenCrossRefs=$br.Count;allClean=($e.Count -eq 0 -and $w.Count -eq 0)}
if($Json){Write-Output($res | ConvertTo-Json -Depth 2)}elseif($res.allClean){if(-not $Quiet){Write-Host "OK ALL CHECKS PASSED"-ForegroundColor Green};exit 0}else{if($e.Count -gt 0){if(-not $Quiet){Write-Host "ERRORS ($($e.Count)):"-ForegroundColor Red};$e | ForEach-Object {if(-not $Quiet){Write-Host " * $_"-ForegroundColor Red}}};if($w.Count -gt 0){if(-not $Quiet){Write-Host "WARNINGS ($($w.Count)):"-ForegroundColor Yellow};$w | ForEach-Object {if(-not $Quiet){Write-Host " * $_"-ForegroundColor Yellow}}};if($e.Count -gt 0){exit 1}else{exit 0}}
