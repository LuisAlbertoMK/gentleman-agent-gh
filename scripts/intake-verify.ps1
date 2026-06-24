#requires -Version 5.1
<# .SYNOPSIS Verify SDD intake — validates project structure and skill scaffolding against intake.json #>
param([string]$p,[ValidateRange(1,5)][int]$i=1,[string]$t="auto",[bool]$m=$true,[ValidateSet("text","json")][string]$f="text")
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest;$t0=Get-Date;$rr=@();$chk=[char]0x2705;$crs=[char]0x274C;$wrn=[char]0x26A0
function wr{param([string]$I,[string]$M)
$c=@{$chk="Green";$crs="Red";$wrn="Yellow"}[$I]
if(-not$c){$c="White"}if($f-ne"json"){Write-Host "$I $M" -ForegroundColor $c}}
function sz{param([string]$x)
if(Test-Path $x){$l=(Get-Item $x).Length;if($l-gt1KB){return"$([math]::Round($l/1KB,1))KB"};return"$l B"}return""}
function ic{param([int]$R,[string]$pp)
$r=@{};$sm=@{};Write-Host "`n  #$R Intake" -ForegroundColor Cyan;$rp=$null
if(Test-Path "$pp\ROADMAP.md"){$rp="ROADMAP.md"}
elseif(Test-Path "$pp\docs\roadmap.md"){$rp="docs/decisions/roadmap.md"}
elseif(Test-Path "$pp\roadmap.md"){$rp="roadmap.md"}
elseif(Test-Path "$pp\roadmap"){$rp="roadmap/ (dir)"}
if($rp){$s2=sz "$pp\$rp";wr $chk "Roadmap $rp ($s2)";$r.rm=$chk;$sm.rm=10}
else{wr $crs "Roadmap Missing";$r.rm=$crs;$sm.rm=0}
$prs=0;$prd=@()
if(Test-Path "$pp\.git"){
try{$cc=&git -C "$pp" log --oneline -10 2>$null|measure|%{$_.Count}}catch{Write-Warning "git: $_";$cc=0}
if($cc-gt0){$prs+=5;$prd+="$cc commits";try{$gp=&gh pr list --limit 5 2>$null}catch{Write-Warning "gh: $_";$gp=$null};if($gp-and!$LASTEXITCODE){$prd+="$(($gp|measure|%{$_.Count})) PR(s)";$prs+=3}}
}else{$prd+="no .git"}
$pf=gci "$pp" -Recurse -Include "*PROBLEM*REPORT*","*bug-report*","*incident*" -Exclude "*node_modules*",".git","*vendor*" -ea 0|select -First 3
if($pf){$prd+="Problem Rpt: $($pf.Count) file(s) ($($pf[0].Name))";$prs=[math]::Max($prs,5)}
$pi=if($prs-ge8){$chk}elseif($prs-ge3){$wrn}else{$crs}
wr $pi "PR: $($prd-join' | ')";$r.pr=$pi;$sm.pr=$prs
$prdF=gci "$pp" -Recurse -Include "*PRD*","*spec*","*requirements*","*srs*" -Exclude "*node_modules*",".git","*vendor*" -File -ea 0|select -First 5
if($prdF){wr $chk "PRD $($prdF.Count) files (e.g., $($prdF[0].Name))";$r.pd=$chk;$sm.pd=10}
else{wr $crs "PRD Missing";$r.pd=$crs;$sm.pd=0}
if(Test-Path "$pp\README.md"){
$s2=sz "$pp\README.md";$c=gc "$pp\README.md" -Raw -ea 0;$q=10
if($c){
if($c-notmatch'# '){$q-=2}
if($c-notmatch'setup|install|getting started|usage|empezar|instalacion'){$q-=2}
if($c.Length-lt200){$q-=2}
if($c.Length-lt100){$q-=3}}
$q=[math]::Max(1,$q);$qi=if($q-ge8){$chk}elseif($q-ge5){$wrn}else{$crs}
wr $qi "README $s2 (score: $q/10)";$r.rd=$qi;$sm.rd=$q
}else{wr $crs "README Missing";$r.rd=$crs;$sm.rd=0}
$td=gci "$pp" -Directory -Include "tests","__tests__","spec","test","cypress" -ea 0
$tf=gci "$pp" -Recurse -Include "*test*","*spec*","*suite*" -File -Exclude "*node_modules*",".git","*vendor*" -ea 0|select -First 10
if($td){wr $chk "Tests dirs: $($td.Name -join',')";$r.ts=$chk;$sm.ts=10}
elseif($tf.Count-ge3){wr $chk "Tests $($tf.Count) files";$r.ts=$chk;$sm.ts=8}
elseif($tf.Count-ge1){wr $wrn "Tests $($tf.Count) files";$r.ts=$wrn;$sm.ts=5}
else{wr $crs "No tests";$r.ts=$crs;$sm.ts=0}
$cf=@();@(".github\workflows","GitHub Actions","Jenkinsfile","Jenkins",".gitlab-ci.yml","GitLab CI","azure-pipelines.yml","Azure Pipelines",".circleci\config.yml","CircleCI","Dockerfile","Docker")|%{$i=0}{if($i%2-eq0){$k=$_}elseif(Test-Path "$pp\$k"){$cf+=$_};$i++}
if($cf.Count-ge2){wr $chk "CI/CD: $($cf-join',')";$r.ci=$chk;$sm.ci=10}
elseif($cf.Count-eq1){wr $wrn "CI/CD: $($cf[0])";$r.ci=$wrn;$sm.ci=5}
else{wr $crs "No CI/CD";$r.ci=$crs;$sm.ci=0}
$mf=@()
foreach($q in @("*sentry*","*datadog*","*newrelic*","*grafana*","*prometheus*","*openTelemetry*","*appinsights*","*bugsnag*","*rollbar*","*logstash*","*honeycomb*","*dynatrace*")){$m2=gci "$pp" -Recurse -Include $q -File -Exclude "*node_modules*",".git" -ea 0|select -First 1;if($m2){$mf+=$m2.Name}}
$hl=(Test-Path "$pp\logs")-or(gci "$pp" -Directory -Include "metrics","monitoring","alerts" -ea 0)
if($mf.Count-ge1){wr $chk "Monitoring $($mf[0]) (+$($mf.Count-1) more)";$r.mo=$chk;$sm.mo=10}
elseif($hl){wr $wrn "Monitoring logging only";$r.mo=$wrn;$sm.mo=5}
else{wr $crs "No monitoring";$r.mo=$crs;$sm.mo=0}
$ts=($sm.Values|measure -Sum).Sum;$ms=$sm.Count*10
$pct=if($ms-gt0){[math]::Round(($ts/$ms)*100,1)}else{0}
Write-Host "  Score: $ts/$ms ($pct%)" -ForegroundColor $(if($pct-ge80){"Green"}elseif($pct-ge50){"Yellow"}else{"Red"})
$miss=@()
if($r.rm-eq$crs){$miss+="Roadmap"}
if($r.pd-eq$crs){$miss+="PRD"}
if($r.rd-eq$crs){$miss+="README"}
if($miss.Count-gt0){Write-Host "  MISSING: $($miss-join', ')" -ForegroundColor Red}
return@{round=$R;results=$r;scores=$sm;totalScore=$ts;maxScore=$ms;pct=$pct;criticalMissing=$miss}}
try {
if(-not(Test-Path $p)){Write-Error "Path not found: $p";exit 2}
if($t-eq"auto"){
$sigs=@()
if(Test-Path "$p\package.json"){$pkg=gc "$p\package.json" -Raw -ea 0
if($pkg-match'"react"|"next"|"vue"'){$sigs+="frontend"}
if($pkg-match'"express"|"fastify"'){$sigs+="backend"}
if($sigs.Count-eq0-and$pkg){$sigs+="node"}}
if(Test-Path "$p\go.mod"){$sigs+="backend"}
if(Test-Path "$p\pubspec.yaml"){$sigs+="mobile"}
if(Test-Path "$p\Dockerfile"){$sigs+="infra"}
if($sigs-contains"frontend"-and$sigs-contains"backend"){$t="fullstack"}
elseif($sigs-contains"frontend"){$t="fe"}
elseif($sigs-contains"backend"){$t="be"}
elseif($sigs-contains"mobile"){$t="mobile"}
else{$t="be"}}
for($j=1;$j-le$i;$j++){$round=ic -R $j -pp $p;$rr+=$round;if($j-lt$i){sleep 1}}
$el=[math]::Round(((Get-Date)-$t0).TotalSeconds,1)
$ar=@("rm","pr","pd","rd","ts","ci","mo")
foreach($a in $ar){$b=$rr[0].scores.$a;$c=$rr[-1].scores.$a;$d=$c-$b;$ds=if($d-gt0){"+$d"}elseif($d-lt0){"$d"}else{"-"};Write-Host "  $a $b->$c ($ds)"}
$bt=$rr[0].totalScore;$lt=$rr[-1].totalScore;$dt=$lt-$bt;$ds=if($dt-gt0){"+$dt"}elseif($dt-lt0){"$dt"}else{"-"};Write-Host "  TOTAL $bt->$lt ($ds)" -ForegroundColor Gray
$opct=$rr[-1].pct;$g=if($opct-ge90){"A"}elseif($opct-ge80){"B"}elseif($opct-ge60){"C"}elseif($opct-ge40){"D"}else{"F"}
Write-Host "`n  Grade: $g ($opct%)" -ForegroundColor $(if($opct-ge80){"Green"}elseif($opct-ge60){"Yellow"}else{"Red"})
if($rr[-1].criticalMissing.Count-gt0){Write-Host "  Critical: $($rr[-1].criticalMissing-join', ')" -ForegroundColor Red}
if($m){
$dv="$p\docs\metricas";if(-not(Test-Path $dv)){try{ni $dv -ItemType Directory|Out-Null}catch{Write-Warning "dv: $_"}}
$x=@{timestamp=(Get-Date -Format "yyyy-MM-dd HH:mm:ss");project=$p;type=$t;iterations=$i;el=$el;baseline=@{};current=@{};delta=@{};pct=$opct;gaps=$rr[-1].criticalMissing}
$md="# Intake $p $t $g $opct%"
foreach($a in $ar){$b=$rr[0].scores.$a;$c=$rr[-1].scores.$a;$d=$c-$b;$ds2=if($d-gt0){"+$d"}elseif($d-lt0){"$d"}else{"-"};$x.baseline[$a]=$b;$x.current[$a]=$c;$x.delta[$a]=$d;$md+="`n$a $b->$c ($ds2)"}
if($rr[-1].criticalMissing.Count-gt0){$md+="`nCritical: $($rr[-1].criticalMissing-join',')"}
try{($x|ConvertTo-Json)|Out-File "$dv\intake-baseline.json" -en utf8}catch{Write-Warning "json: $_"}
try{$md|Out-File "$dv\intake-report.md" -en utf8}catch{Write-Warning "rpt: $_"};Write-Host "  $dv\intake-..." -ForegroundColor Cyan}
if($rr[-1].criticalMissing.Count-gt0){exit 2}
if($opct-lt80){exit 1}
exit 0}catch{Write-Error "Intake failed: $_";exit 1}
