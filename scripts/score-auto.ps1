#requires -Version 5.1
<# .SYNOPSIS Compute project score from repo state #>
param([switch]$Json,[switch]$Quiet)
$ErrorActionPreference="Stop"
cd "$PSScriptRoot\.."
& "$PSScriptRoot\restore-project-score.ps1" -Quiet 2>&1|Out-Null
$L=@{}
function ad($Name,$Score,$Max,$Evidence,$Rationale){$L[$Name]=@{score=[math]::Round($Score,1);max=$Max;evidence=$Evidence;rationale=$Rationale}}
$ErrorActionPreference="SilentlyContinue"
$Dirs=gci -Directory ".\.agents\skills" -Name
$SC=($Dirs|?{$_ -ne '_shared'}).Count
& ".\scripts\cross-ref-check.ps1" *>$null
$X=($LASTEXITCODE -eq 0);$HR=Test-Path "README.md";$HC=Test-Path "CHANGELOG.md";$HPJ=Test-Path ".project.json";$HRd=Test-Path "ROADMAP.md"
$AS=10
if(-not $X){$AS-=2}
if(-not $HR){$AS-=2}
if(-not $HC){$AS-=1}
if($SC -lt 60){$AS-=2}
if(-not $HPJ){$AS-=1}
$AS=[math]::Max(0,$AS)
ad "Project Artifacts" $AS 10 @{skills=$SC;cross_ref=$X;readme=$HR;changelog=$HC;project_json=$HPJ;roadmap=$HRd} "Cross-ref $X, $SC skills"
$Sec=10;$WC=$false;$SF=$false
$WeakCrypto=sls -Path ".\scripts\*.ps1" -Pattern "MD5|SHA1\b" -SimpleMatch|?{$_.Line -notmatch "SHA1ToSHA256|SHA256|# deprecat|# legacy|SHA1SHA256|Select-String.*MD5"}
if($WeakCrypto){$WC=$true;$Sec-=2}
$Secrets=sls -Path ".\.agents\skills\*\SKILL.md" -Pattern "(?i)(api[_-]?key|secret|password|token|credential)\s*[=:]\s*['""][^'""]{8,}"
if($Secrets){$SF=$true;$Sec-=3}
if(Test-Path "docs/metricas/errors/LATEST_error.json"){$P=gc "docs/metricas/errors/LATEST_error.json" -Raw|ConvertFrom-Json;if($P.source -ne "quality-gate" -or $P.passed -lt 5){$Sec-=1}}else{$PO=& ".\scripts\pssa-gate.ps1" -Mode Check 2>&1;if($LASTEXITCODE -ne 0 -or $PO -match "FAIL|violation|security"){$Sec-=1}}
$Sec=[math]::Max(0,[math]::Min(10,$Sec))
ad "Security" $Sec 10 @{weak_crypto=$WC;secrets=$SF} "Weak crypto: $WC, secrets: $SF"
$DS=10
$WF=gci ".\skills" -File -EA SilentlyContinue
$OC=($WF|?{$_.Name -notin $Dirs}).Count
if($OC -gt 5){$DS-=2}elseif($OC -gt 0){$DS-=1}
$JI=0
gci ".\skills" -Directory -EA SilentlyContinue|%{if(-not (Test-Path $_.Target)){$JI++}}
if($JI -gt 0){$DS-=1}
$CC=@(sls -Path ".\scripts\*.ps1" -Pattern "#.*function|#.*if|#.*for\s*\(" -SimpleMatch|?{$_.Filename -ne "score-auto.ps1"})
if($CC.Count -gt 10){$DS-=1}
$DS=[math]::Max(0,[math]::Min(10,$DS))
ad "Dead Code" $DS 10 @{orphans=$OC;dead_junctions=$JI;commented_out=$CC.Count} "Orphans: $OC, dead junctions: $JI"
$Scripts=gci ".\scripts\*.ps1";$TS=$Scripts.Count;$WH=0;$WP=0;$WS=0
foreach($S in $Scripts){$C=gc $S.FullName -Raw;if($C -match '<#'){$WH++};if($C -match 'param\('){$WP++};if($C -match 'Set-StrictMode'){$WS++}}
$CR=@($WH,$WP,$WS|%{[math]::Round($_/$TS,2)})
$CS=[math]::Round(($CR[0]+$CR[1]+$CR[2])/3*10,1)
ad "Clean Code" $CS 10 @{total_scripts=$TS;with_help=$WH;with_params=$WP;with_strictmode=$WS} "Scripts: $TS, help: $WH, params: $WP, strict: $WS"
$Best=[math]::Round(($WP/$TS)*10,1);$WTC=0
foreach($S in $Scripts){if((gc $S.FullName -Raw) -match 'try\s*\{'){$WTC++}}
$TCR=$WTC/$TS
if($TCR -ge 0.8){$Best=[math]::Min(10,$Best+1)}elseif($TCR -le 0.3){$Best=[math]::Max(0,$Best-1)}
ad "Best Practices" $Best 10 @{param_coverage=$WP;trycatch=$WTC} "Params: $WP/$TS, try/catch: $WTC/$TS"
$Corr=0
$SFiles=gci ".\.agents\skills\*\SKILL.md"
foreach($F in $SFiles){try{$B=[System.IO.File]::ReadAllBytes($F.FullName);$C2=$false;for($i=0;$i -lt $B.Length-3;$i++){if($B[$i]-eq0xC3-and$B[$i+1]-eq0x83-and$B[$i+2]-ge0x80){$C2=$true;break};if($B[$i]-eq0xC3-and$B[$i+1]-eq0xA2-and$i+3-lt$B.Length){if($B[$i+2]-eq0xE2-and($B[$i+3]-eq0x80-or$B[$i+3]-eq0x82)){$C2=$true;break}}};if($C2){$Corr++}}catch{Write-Debug "score-auto: $($_.Exception.Message)"}}
$Ort=10
if($Corr -gt 10){$Ort=4}elseif($Corr -gt 5){$Ort=7}elseif($Corr -gt 0){$Ort=9}
ad "Orthography" $Ort 10 @{corrupted_files=$Corr;total_scanned=$SFiles.Count} "Encoding corruption: $Corr/$($SFiles.Count) files"
$Bita=0
if(Test-Path "BITACORA.md"){$Bc=gc "BITACORA.md" -Raw;$BL=$Bc.Split("`n").Count;if($BL -gt 10){$Bita=10}elseif($BL -gt 5){$Bita=7}else{$Bita=5}}
ad "Bitacora" $Bita 10 @{exists=(Test-Path "BITACORA.md");lines=if(Test-Path "BITACORA.md"){(gc "BITACORA.md").Count}else{0}} "BITACORA.md exists: $(Test-Path 'BITACORA.md')"
$HMD=Test-Path "docs/metricas";$HED=Test-Path "docs/metricas/errors";$HEJ=Test-Path "docs/metricas/errors/LATEST_error.json";$HRp=(gci "docs/metricas" -File -EA SilentlyContinue).Count -gt 0
$Met=4
if($HMD -and $HEJ){$Met=9}elseif($HMD){$Met=7}
if($HRp -and $HED){$Met=[math]::Min(10,$Met+1)}
ad "Metrics" $Met 10 @{metrics_dir=$HMD;errors_dir=$HED;error_json=$HEJ;has_reports=$HRp} "Metrics dir: $HMD, error json: $HEJ"
$SS=gci ".\scripts\*.ps1"|select Name,Length
$AvgKB=[math]::Round(($SS|measure -Average Length).Average/1KB,1)
$O50=($SS|?{$_.Length -gt 51200}).Count;$SCt=$SS.Count
$Perf=10
if($SCt -lt 15 -or $SCt -gt 35){$Perf-=1}
if($AvgKB -gt 15){$Perf-=1}elseif($AvgKB -gt 20){$Perf-=2}
if($O50 -gt 0){$Perf-=2}
$Perf=[math]::Max(0,[math]::Min(10,$Perf))
ad "Script Performance" $Perf 10 @{script_count=$SCt;avg_size_kb=$AvgKB;over_50kb=$O50} "Scripts: $SCt, avg: ${AvgKB}KB, >50KB: $O50"
$SF2=gci ".\.agents\skills\*\SKILL.md"|?{$_.Directory.Name -ne '_shared'};$Tot=$SF2.Count;$O3=($SF2|?{$_.Length -gt 3072}).Count;$O5=($SF2|?{$_.Length -gt 5120}).Count;$TB=($SF2|measure -Sum Length).Sum;$ASKB=[math]::Round($TB/$Tot/1KB,1)
$Eff=10
if($O5 -gt 0){$Eff-=2}elseif($O3 -gt 3){$Eff-=2}elseif($O3 -gt 1){$Eff-=1}
if($ASKB -le 2.5){$Eff=[math]::Min(10,$Eff+0.5)}
if($Tot -lt 60){$Eff-=2}
$Eff=[math]::Round([math]::Max(0,[math]::Min(10,$Eff)),1)
ad "Skill Effectiveness" $Eff 10 @{total_skills=$Tot;over_3kb=$O3;over_5kb=$O5;avg_size_kb=$ASKB;total_bytes=$TB} "Skills: $Tot, >3KB: $O3, >5KB: $O5, avg: ${ASKB}KB"
$IntPath=".learnings\inter-track.json";$Cyc=0;$IC=0;$IT=30
if(Test-Path $IntPath){try{$ID=gc $IntPath -Raw|ConvertFrom-Json;$IC=[int]$ID.cycle.count;$IT=[int]$ID.cycle.target;$Cyc=[math]::Min(10,[math]::Round(($IC/$IT)*10,1))}catch{$Cyc=0}}
ad "Cycle Activity" $Cyc 10 @{inter_count=$IC;inter_target=$IT} "inter: $IC/$IT"
$BScript=Join-Path $PSScriptRoot 'check-backlog-integrity.ps1'
if(Test-Path $BScript){$BJ=& $BScript -Json 2>&1|Out-String|ConvertFrom-Json;$BS=$BJ.score;$BP=$BJ.passed;$BT=$BJ.totalItems}else{$BS=0;$BP=0;$BT=0}
ad "Backlog Integrity" $BS 10 @{passed=$BP;total=$BT} "$BP/$BT items match reality"
$All=$L.Values|%{$_.score}
$Final=[math]::Round(($All|measure -Average).Average,1)
$dm=@("Project Artifacts","Security","Dead Code","Clean Code","Best Practices","Orthography","Bitacora","Metrics","Script Performance","Skill Effectiveness","Cycle Activity","Backlog Integrity")
$r=@{score=@{current=$Final;dimensions=[ordered]@{};last_updated=(Get-Date -Format "yyyy-MM-dd");trend="stable"};dimensions_detail=$L}
foreach($D in $dm){$r.score.dimensions[$D]=$L[$D].score}
if(Test-Path ".project.json"){try{$Prev=gc ".project.json" -Raw -Encoding UTF8|ConvertFrom-Json;$PSc=$Prev.score.current;if($Final -gt $PSc){$r.score.trend="up"}elseif($Final -lt $PSc){$r.score.trend="down"}else{$r.score.trend="stable"};$LU=$Prev.score.last_updated;if($LU){$age=[int]((Get-Date)-(Get-Date $LU)).TotalDays;if($age -ge 1){Write-Host "WARNING: .project.json is $age day(s) stale (last: $LU)" -ForegroundColor Yellow}}}catch{$r.score.trend="unknown"}}
if($Json){$r|ConvertTo-Json -Depth 4}elseif($Quiet){Write-Host "Score: $Final/10 (trend: $($r.score.trend))"}else{Write-Host "$($r.score.last_updated) | $Final/10 ($($r.score.trend))" -ForegroundColor Cyan;Write-Host "Dimensions:" -ForegroundColor Yellow;foreach($D in $dm){$d2=$L[$D];$C=if($d2.score -ge 9){"Green"}elseif($d2.score -ge 7){"Yellow"}else{"Red"};Write-Host " $($D.PadRight(16))$($d2.score.ToString('F1').PadLeft(4))/10" -ForegroundColor $C};Write-Host $("-"*32) -ForegroundColor Gray;Write-Host " TOTAL$(''.PadLeft(12))$($Final.ToString('F1').PadLeft(4))/10" -ForegroundColor White}
