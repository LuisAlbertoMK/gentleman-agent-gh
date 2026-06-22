#requires -Version 5.1
<#
.SYNOPSIS Validate internal refs (skills, SKILLS-INDEX, junctions, shared).
#>
param([string]$R=(Split-Path $PSScriptRoot -Parent),[switch]$J)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$e=@();$w=@();$cd=Join-Path $R ".agents\skills";$gd="$env:USERPROFILE\.config\opencode\skills"
if(-not(Test-Path $cd)){Write-Host "FATAL: missing $cd"-ForegroundColor Red;exit 1}
Write-Host "[1/8] APC..."-N;$apc=Test-Path(Join-Path $R "ANTI-PATTERN-CATALOG.md")
if($apc){Write-Host " OK"}else{$e+="APC not found";Write-Host " FAIL"}
Write-Host "[2/8] SKILL.md..."-N;$ms=@()
try{$sd=gci(Join-Path $cd "*")-Directory}catch{Write-Host " FAIL`nFATAL: list: $_"-ForegroundColor Red;exit 1}
$sd|%{$n=$_.Name;if($n-eq'_shared'){return};if(-not(Test-Path(Join-Path $_.FullName "SKILL.md"))){$ms+=$n}}
if($ms.Count-eq0){Write-Host " OK (all)"}else{$w+="Missing SKILL.md: $($ms-join', ')";Write-Host " WARN"}
Write-Host "[3/8] INDEX count..."-N;$ac=($sd|?{$_.Name-ne'_shared'}).Count
$hl=sls -Path(Join-Path $R "SKILLS-INDEX.md")-Pattern "all \d+ skills"
if($hl-match"all (\d+) skills"){$dc=[int]$Matches[1];if($dc-eq$ac){Write-Host " OK ($ac)"}else{$e+="INDEX says $dc, has $ac";Write-Host " FAIL ($dc vs $ac)"}}else{$w+="INDEX header mismatch";Write-Host " WARN"}
Write-Host "[4/8] junctions..."-N;$mg=@()
if(Test-Path $gd){gci $cd -Directory|?{$_.Name-ne'_shared'}|%{$gp=Join-Path $gd $_.Name;if(-not(Test-Path $gp)){$mg+=$_.Name}}}
if($mg.Count-eq0){Write-Host " OK (all)"}else{$w+="Missing junctions: $($mg-join', ')";Write-Host " WARN"}
Write-Host "[5/8] _shared..."-N
$sf=@{'skill-resolver.md'=Test-Path(Join-Path $cd "_shared\skill-resolver.md");'sdd-phase-common.md'=Test-Path(Join-Path $cd "sdd\references\sdd-phase-common.md");'persistence-contract.md'=Test-Path(Join-Path $cd "_shared\persistence-contract.md");'engram-convention.md'=Test-Path(Join-Path $cd "_shared\engram-convention.md")}
$mh=@($sf.GetEnumerator()|?{-not$_.Value}|%{$_.Key})
if($mh.Count-eq0){Write-Host " OK"}else{$e+="Missing _shared: $($mh-join', ')";Write-Host " FAIL"}
Write-Host "[6/8] cross-refs..."-N;$br=@()
$al=($sd|?{$_.Name-ne'_shared'}|%{$_.Name.ToLower()});$rp='Cross-Refs:\s*(.+)';$ap='Anti-Patterns:\s*(.+)'
gci $cd -Directory|?{$_.Name-ne'_shared'}|%{$sn=$_.Name;$mp=Join-Path $_.FullName "SKILL.md";if(-not(Test-Path $mp)){return};try{$c=gc $mp -Raw}catch{return};if(-not$c){return};if($c-match$rp){$rf=$Matches[1]-split'\s*[\|,]\s*'|%{$_.Trim()}|?{$_-cmatch'^[a-z][a-z0-9_-]+$'};$rf|%{if($al-notcontains$_){$br+="$sn cross-refs '$_' missing"}}};if($c-match$ap){$ax=$Matches[1]-split'\s*[\|,]\s*'|%{$_.Trim()}|?{$_-cmatch'^[a-z][a-z0-9_-]+$'};$ax|%{if($al-notcontains$_){$br+="$sn anti-refs '$_' missing"}}}}
if($br.Count-eq0){Write-Host " OK"}else{$e+=$br;Write-Host " FAIL ($($br.Count))"}
Write-Host "[7/8] config_refs..."-N;$mc=@();$crp='config_refs:\s*(.+)'
gci $cd -Directory|?{$_.Name-ne'_shared'}|%{$sn=$_.Name;$mp=Join-Path $_.FullName "SKILL.md";if(-not(Test-Path $mp)){return};try{$c=gc $mp -Raw -Encoding UTF8}catch{return};if(-not$c){return};if($c-match$crp){$rf=$Matches[1]-split'\s*[\|,]\s*'|%{$_.Trim()}|?{$_-ne''};$rf|%{$rp2=Join-Path $R $_;if(-not(Test-Path $rp2)){$mc+="$sn config_refs '$_' missing at $rp2"}}}}
if($mc.Count-eq0){Write-Host " OK"}else{$e+=$mc;Write-Host " FAIL ($($mc.Count))"}
Write-Host "[8/8] review-rules.jsonc..."-N;$rk=Join-Path $R "review-rules.jsonc"
if(Test-Path $rk){try{$b=gc $rk -Raw -Encoding UTF8;$s=$b-replace'(?m)^\s*//.*$',''-replace'(?m)\s*//[^"\n]*$',''-replace'(?s)/\*.*?\*/','';$p=$s|ConvertFrom-Json;$zc=$p.zones.PSObject.Properties.Name.Count;$cc=$p.context_zones.PSObject.Properties.Name.Count;$md=$p.modes.PSObject.Properties.Name.Count;$pc=$p.jd_profiles.PSObject.Properties.Name.Count;$sc=$p.jd_profile_selector.Count;$is=@();if($zc-ne3){$is+="zones $zc"};if($cc-ne4){$is+="ctx $cc"};if($md-ne5){$is+="modes $md"};if($pc-lt1){$is+="profiles $pc"};if($sc-lt1){$is+="selectors $sc"};if($is.Count-eq0){Write-Host " OK (z$zc c$cc m$md p$pc s$sc)"}else{$e+="review-rules.jsonc: $($is-join'; ')";Write-Host " FAIL"}}catch{$e+="review-rules.jsonc parse: $_";Write-Host " FAIL"}}else{$w+="review-rules.jsonc missing";Write-Host " WARN"}
$res=@{timestamp=(Get-Date -Format "o");canonicalSkills=$ac;errors=$e;warnings=$w;brokenCrossRefs=$br.Count;allClean=($e.Count-eq0-and$w.Count-eq0)}
if($J){Write-Output($res|ConvertTo-Json -Depth 2)}elseif($res.allClean){Write-Host "OK ALL CHECKS PASSED"-ForegroundColor Green;exit 0}else{if($e.Count-gt0){Write-Host "ERRORS ($($e.Count)):"-ForegroundColor Red;$e|%{Write-Host " * $_"-ForegroundColor Red}};if($w.Count-gt0){Write-Host "WARNINGS ($($w.Count)):"-ForegroundColor Yellow;$w|%{Write-Host " * $_"-ForegroundColor Yellow}};if($e.Count-gt0){exit 1}else{exit 0}}
