#requires -Version 7.6
<#
.SYNOPSIS
  Auto-score project metrics across 7 dimensions.
.DESCRIPTION
  Scores correctness, tokens, error prevention, skill, speed, breadth, and skill_eval.
  Outputs JSON with -Json, quiet mode with -Quiet.
#>
param([switch]$Json,[switch]$Quiet)
Set-Location "$PSScriptRoot\.."
& "$PSScriptRoot\restore-project-score.ps1" -Quiet 2>&1 | Out-Null
$m=[math];$h=@{};function a($n,$s,$e,$r){$h[$n]=@{s=$s;e=$e;r=$r}}
$d=Get-ChildItem -Directory ".\.agents\skills" -Name
$c=$d.PSWhere({$_ -ne '_shared'}).Count
& ".\scripts\cross-ref-check.ps1" *>$null;$x=($LASTEXITCODE -eq 0)
$h1=Test-Path "README.md";$h3=Test-Path ".project.json"
$as=10;if(!$x){$as-=2};if(!$h1){$as-=2};if($c -lt 60){$as-=2};if(!$h3){$as-=1}
a "PA" ($m::Max(0,$as)) @{skills=$c;cross_ref=$x;readme=$h1;project_json=$h3} "X-ref $x, $c skills"
$s1=10;$wc=$false;$sf=$false
$wk=@(Select-String -Path ".\scripts\*.ps1" -Pattern "MD5|SHA1\b").PSWhere({$_.Line -notmatch "SHA1ToSHA256|SHA256|#deprecat|#legacy|SHA1SHA256|Select-String.*MD5"})
if($wk){$wc=$true;$s1-=2}
$sk=@(Select-String -Path ".\.agents\skills\*\SKILL.md", ".\scripts\*.ps1", ".\.github\workflows\*.yml", ".\opencode.json" -Pattern "(?i)(api[_-]?key|secret|password|token|credential)\s*[=:]\s*['""][^'""]{8,}")
if($sk){$sf=$true;$s1-=3}
if(Test-Path "docs/metricas/errors/LATEST_error.json"){$p1=Get-Content "docs/metricas/errors/LATEST_error.json" -Raw | ConvertFrom-Json;if($p1.source -ne "quality-gate" -or $p1.passed -lt 5){$s1-=1}}else{$po=& ".\scripts\pssa-gate.ps1" -Mode Check 2>&1;if($LASTEXITCODE -ne 0 -or $po -match "FAIL|violation|security"){$s1-=1}}
a "Sec" ($m::Max(0,$m::Min(10,$s1))) @{weak_crypto=$wc;secrets=$sf} "Weak crypto: $wc, secrets: $sf"
$ds=10;$wf=@(Get-ChildItem ".\skills" -File -EA SilentlyContinue);$oc=$wf.PSWhere({$_.Name -notin $d}).Count
if($oc -gt 5){$ds-=2}elseif($oc -gt 0){$ds-=1}
$ji=(Get-ChildItem ".\skills" -Directory -EA SilentlyContinue).PSWhere({ $_.Target -and -not (Test-Path $_.Target) }).Count
if($ji -gt 0){$ds-=1};$co=@(Select-String -Path ".\scripts\*.ps1" -Pattern '^\s*#\s+function\s+\w+|^\s*#\s+if\s*\(|^\s*#\s+foreach\s*\(|^\s*#\s+for\s*\(|^\s*#\s+while\s*\(|^\s*#\s+switch\s*\(|^\s*#\s+try\s*\{|^\s*#\s+catch\s*\{').PSWhere({$_.Filename -ne "score-auto.ps1"})
if($co.Count -gt 10){$ds-=1}
a "DC" ($m::Max(0,$m::Min(10,$ds))) @{orphans=$oc;dead_junctions=$ji;commented_out=$co.Count} "Orphans: $oc, dead junctions: $ji"
$sc=@(Get-ChildItem ".\scripts\*.ps1");$ts=$sc.Count
$scStats=$sc|ForEach-Object -Parallel{$c1=[IO.File]::ReadAllText($_.FullName);[PSCustomObject]@{h=[bool]($c1-match'<#');p=[bool]($c1-match'param\(');s=[bool]($c1-match'Set-StrictMode');t=[bool]($c1-match'try\s*\{')}} -ThrottleLimit 7
$wh=@($scStats|?{$_.h}).Count;$wp=@($scStats|?{$_.p}).Count;$ws=@($scStats|?{$_.s}).Count;$wt=@($scStats|?{$_.t}).Count
$cr=($wh,$wp,$ws).PSForEach({$m::Round(($_/$ts),2)})
a "CC" ($m::Round(($cr[0]+$cr[1]+$cr[2])/3*10,1)) @{total_scripts=$ts;with_help=$wh;with_params=$wp;with_strictmode=$ws} "S:$ts H:$wh P:$wp S:$ws"
$bp=$m::Round(($wp/$ts)*10,1)
$tr=$wt/$ts;if($tr -ge 0.8){$bp=$m::Min(10,$bp+1)}elseif($tr -le 0.3){$bp=$m::Max(0,$bp-1)}
a "BP" $bp @{param_cov=$wp;trycatch=$wt} "P:$wp/$ts T:$wt/$ts"
$sf2=Get-ChildItem ".\.agents\skills\*\SKILL.md";$crp=@($sf2|ForEach-Object -Parallel{$f=$_;try{$b=[System.IO.File]::ReadAllBytes($f.FullName);for($i=0;$i -lt $b.Length-3;$i++){if($b[$i]-eq0xC3-and$b[$i+1]-eq0x83-and$b[$i+2]-ge0x80){$true;return};if($b[$i]-eq0xC3-and$b[$i+1]-eq0xA2-and$i+3-lt$b.Length-and$b[$i+2]-eq0xE2-and($b[$i+3]-eq0x80-or$b[$i+3]-eq0x82)){$true;return}};return $false}catch{$false}} -ThrottleLimit 4|?{$_}).Count
$ort=10;if($crp -gt 10){$ort=4}elseif($crp -gt 5){$ort=7}elseif($crp -gt 0){$ort=9}
a "Or" $ort @{corrupted=$crp;scanned=$sf2.Count} "Corruption: $crp/$($sf2.Count)"
$bi=0;if(Test-Path "BITACORA.md"){$bc=Get-Content "BITACORA.md" -Raw;$bl=$bc.Split("`n").Count;if($bl -gt 10){$bi=10}elseif($bl -gt 5){$bi=7}else{$bi=5}}
a "Bi" $bi @{exists=(Test-Path "BITACORA.md");lines=if(Test-Path "BITACORA.md" -and $null -ne $bc){$bl}else{0}} "BI: $(Test-Path 'BITACORA.md')"
$hm=Test-Path "docs/metricas";$he=Test-Path "docs/metricas/errors";$hj=Test-Path "docs/metricas/errors/LATEST_error.json";$hr=(Get-ChildItem "docs/metricas" -File -EA SilentlyContinue).Count -gt 0
$mt=4;if($hm -and $hj){$mt=9}elseif($hm){$mt=7};if($hr -and $he){$mt=$m::Min(10,$mt+1)}
a "Me" $mt @{md=$hm;ed=$he;ej=$hj;rp=$hr} "MD:$hm EJ:$hj"
$ak=$m::Round(($sc | Measure-Object -Average Length).Average/1KB,1);$o5=$sc.PSWhere({$_.Length -gt 51200}).Count
$pf=10;if($ts -lt 15 -or $ts -gt 50){$pf-=1};if($ak -gt 15){$pf-=1}elseif($ak -gt 20){$pf-=2};if($o5 -gt 0){$pf-=2}
a "SP" ($m::Max(0,$m::Min(10,$pf))) @{sc=$ts;avg=$ak;huge=$o5} "S:$ts avg:${ak}KB"
$s4=(Get-ChildItem ".\.agents\skills\*\SKILL.md").PSWhere({$_.Directory.Name -ne '_shared'});$tt=$s4.Count;$o3=$s4.PSWhere({$_.Length -gt 3072}).Count;$o6=$s4.PSWhere({$_.Length -gt 5120}).Count;$tb=($s4 | Measure-Object -Sum Length).Sum;$ak2=$m::Round($tb/$tt/1KB,1)
# Extend overweight check to commands/ + prompts/ (H-019)
$cmdFiles=Get-ChildItem "commands\*.md" -EA SilentlyContinue;$promptFiles=Get-ChildItem "prompts" -Recurse -File -EA SilentlyContinue
$cmdOver3=$cmdFiles.PSWhere({$_.Length -gt 3072}).Count;$cmdOver5=$cmdFiles.PSWhere({$_.Length -gt 5120}).Count
$prOver3=$promptFiles.PSWhere({$_.Length -gt 3072}).Count;$prOver5=$promptFiles.PSWhere({$_.Length -gt 5120}).Count
$owPenalty=0;if($cmdOver5 -gt 0-or$prOver5 -gt 0){$owPenalty=2}elseif($cmdOver3 -gt 2-or$prOver3 -gt 1){$owPenalty=1}
$ef=10;if($o6 -gt 0){$ef-=2}elseif($o3 -gt 3){$ef-=2}elseif($o3 -gt 1){$ef-=1};$ef-=$owPenalty;if($ak2 -le 2.5){$ef=$m::Min(10,$ef+0.5)};if($tt -lt 60){$ef-=2}
a "SE" ($m::Round($m::Max(0,$m::Min(10,$ef)),1)) @{total=$tt;o3=$o3;o5=$o6;avg=$ak2;bytes=$tb;cmdO3=$cmdOver3;cmdO5=$cmdOver5;prO3=$prOver3;prO5=$prOver5} "T:$tt >3:$o3 >5:$o6 avg:${ak2}KB cmdO3:$cmdOver3 cmdO5:$cmdOver5 prO3:$prOver3 prO5:$prOver5"
$ip=".learnings\inter-track.json";$cy=0;$ic=0;$it=30
if(Test-Path $ip){try{$id=Get-Content $ip -Raw | ConvertFrom-Json;$ic=[int]$id.cycle.count;$it=[int]$id.cycle.target;$cy=$m::Min(10,$m::Round(($ic/$it)*10,1))}catch{$cy=0}}
a "CA" $cy @{ic=$ic;it=$it} "IC:$ic/$it"
$bp2=Join-Path $PSScriptRoot 'check-backlog-integrity.ps1'
if(Test-Path $bp2){$bj=& $bp2 -Json 2>&1 | Out-String | ConvertFrom-Json;$bs=$bj.score;$bpp=$bj.passed;$bt=$bj.totalItems}else{$bs=0;$bpp=0;$bt=0}
a "BI2" $bs @{passed=$bpp;total=$bt} "$bpp/$bt items"
$sd=@();$e1=$h["PA"].e
$sd+=$(if($e1.readme){10}else{0});$sd+=$(if($e1.cross_ref){10}else{0});$sd+=($m::Min(10,$e1.skills/6));$sd+=$(if($e1.project_json){10}else{0})
$e2=$h["Sec"].e;$sd+=$(if($e2.weak_crypto){5}else{10});$sd+=$(if($e2.secrets){3}else{10})
$e3=$h["DC"].e;$sd+=$(if($e3.orphans -le 0){10}elseif($e3.orphans -le 5){7}else{5});$sd+=$(if($e3.dead_junctions -le 0){10}else{7});$sd+=$(if($e3.commented_out -le 10){10}else{7})
$e4=$h["CC"].e;$sd+=($m::Round($e4.with_help/$ts*10,1));$sd+=($m::Round($e4.with_params/$ts*10,1));$sd+=($m::Round($e4.with_strictmode/$ts*10,1))
$e5=$h["BP"].e;$sd+=($m::Round($e5.param_cov/$ts*10,1));$sd+=($m::Round($e5.trycatch/$ts*10,1))
$sd+=$(if($crp -le 0){10}elseif($crp -le 5){9}elseif($crp -le 10){7}else{4});$sd+=$(if($h["Bi"].e.exists){10}else{0});$sd+=($m::Min(10,$h["Bi"].e.lines/2))
$sd+=$(if($hm){10}else{0});$sd+=$(if($he){10}else{0});$sd+=$(if($hj){10}else{0});$sd+=$(if($hr){10}else{0})
$sd+=$(if($ts -ge 15-and$ts -le 50){10}else{7});$sd+=$(if($ak -le 10){10}elseif($ak -le 15){7}else{5});$sd+=$(if($o5 -le 0){10}else{5})
$sd+=$(if($tt -ge 60){10}else{7});$sd+=$(if($o3 -le 0){10}elseif($o3 -le 1){9}else{7});$sd+=$(if($o6 -le 0){10}else{7});$sd+=$(if($ak2 -le 2.0){10}elseif($ak2 -le 2.5){9.5}else{7})
$sd+=($m::Min(10,$ic/$it*10));$sd+=$(if($bt -gt 0){$bpp/$bt*10}else{0})
$dp=($sd | Measure-Object -Average).Average;if($dp -is [double]){$dp=$m::Round($dp,1)}
a "SD" $dp @{subd=$sd.Count} "Depth: $($sd.Count) sub-dims: $dp/10"
# Bias calibration warning (auto-metrics correction, not project score)
$bp3=".learnings/bias-calibration.json";if(!$Json-and(Test-Path $bp3)){try{$bc2=Get-Content $bp3 -Raw|ConvertFrom-Json;if($bc2.samples -ge 2){Write-Host "⚠️ Active bias offsets (auto-metrics):" -ForegroundColor DarkYellow;$bc2.offsets.PSObject.Properties|Sort-Object Name|ForEach-Object{Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor DarkYellow}}}catch{}}
$all=$h.Values.PSForEach({$_.s});$fn=$m::Round(($all | Measure-Object -Average).Average,1)
$dn=@{"PA"="Project Artifacts";"Sec"="Security";"DC"="Dead Code";"CC"="Clean Code";"BP"="Best Practices";"Or"="Orthography";"Bi"="Bitacora";"Me"="Metrics";"SP"="Script Performance";"SE"="Skill Effectiveness";"CA"="Cycle Activity";"BI2"="Backlog Integrity";"SD"="Score Depth"}
$r=@{score=@{current=$fn;dimensions=[ordered]@{};last_updated=(Get-Date -Format "yyyy-MM-dd");trend="stable"};dimensions_detail=$h}
foreach($k in $dn.Keys){$r.score.dimensions[$dn[$k]]=$h[$k].s}
if(Test-Path ".project.json"){try{$pr=Get-Content ".project.json" -Raw -Encoding UTF8 | ConvertFrom-Json;$ps=$pr.score.current;if($fn -gt $ps){$r.score.trend="up"}elseif($fn -lt $ps){$r.score.trend="down"};$lu=$pr.score.last_updated;if($lu -and !$Json){$age=[int]((Get-Date)-(Get-Date $lu)).TotalDays;if($age -ge 1){Write-Host "WARNING: .project.json is $age day(s) stale (last: $lu)" -ForegroundColor Yellow}}}catch{Write-Warning "score-auto: .project.json parse failed ($($_.Exception.Message))"}}
if($Json){$r | ConvertTo-Json -Depth 5}elseif($Quiet){Write-Host "Score: $fn/10 (trend: $($r.score.trend))"}else{Write-Host "$($r.score.last_updated) | $fn/10 ($($r.score.trend))" -ForegroundColor Cyan;Write-Host "Dimensions:" -ForegroundColor Yellow;foreach($k in $dn.Keys){$d2=$h[$k];$C=if($d2.s -ge 9){"Green"}elseif($d2.s -ge 7){"Yellow"}else{"Red"};Write-Host " $($dn[$k].PadRight(16))$($d2.s.ToString('F1').PadLeft(4))/10" -ForegroundColor $C};Write-Host $("-"*32);Write-Host " TOTAL$(''.PadLeft(12))$($fn.ToString('F1').PadLeft(4))/10" -ForegroundColor White}
