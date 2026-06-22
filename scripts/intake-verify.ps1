#requires -Version 5.1

<#
.SYNOPSIS
  Project Intake Verification — 7 checks + 3-iteration cycle
.DESCRIPTION
  Evalúa un proyecto contra el framework de gap-analysis. Corre 7 checks y
  opcionalmente itera para mejora progresiva. Output en texto o JSON.
.PARAMETER ProjectPath
  Ruta al proyecto a verificar.
.PARAMETER Iterations
  Cantidad de ciclos de mejora (default: 3).
.PARAMETER OutputFormat
  Formato de salida: text (default) o json.
.PARAMETER ProjectType
  Tipo de proyecto para análisis: auto (default), fe, be, db, fullstack, mobile, etc.
.PARAMETER SaveMetrics
  Guardar métricas en docs/metricas/ (default: $true).
#>

param([Parameter(Mandatory=$true)][string]$ProjectPath,[ValidateRange(1,5)][int]$Iterations=1,[ValidateSet("auto","fe","be","db","fullstack","mobile","desktop","saas","erp","ecom","api","web","cms","infra")][string]$ProjectType="auto",[bool]$SaveMetrics=$true,[ValidateSet("text","json")][string]$OutputFormat="text")

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$script:startTime=Get-Date;$script:roundResults=@()
$script:CHK=[char]0x2705;$script:CRS=[char]0x274C;$script:WRN=[char]0x26A0

function Write-Result {
    param([string]$I,[string]$A,[string]$S,[string]$D)
    $c=@{$script:CHK="Green";$script:CRS="Red";$script:WRN="Yellow"}[$I]
    if(-not$c){$c="White"}
    $l="$I $A : $S"
    if($D){$l+=" - $D"}
    if($OutputFormat-ne"json"){Write-Host $l -ForegroundColor $c}
}

function Get-FileSize {
    param([string]$Path)
    if(Test-Path $Path){$l=(Get-Item $Path).Length;if($l-gt1KB){return"$([math]::Round($l/1KB,1))KB"};return"$l B"}
    return""
}

function Invoke-Check {
    param([int]$R,[string]$PP,[string]$PT)
    $r=@{};$sm=@{};$ok=$script:CHK;$no=$script:CRS;$warn=$script:WRN
    $dash='-'*50
    Write-Host "`n  Iteracion $R - Intake Verification" -ForegroundColor Cyan
    Write-Host "  Proyecto: $PP`n  Tipo: $PT" -ForegroundColor Gray

    $rp=$null
    if(Test-Path "$PP\ROADMAP.md"){$rp="ROADMAP.md"}
    elseif(Test-Path "$PP\docs\roadmap.md"){$rp="docs/roadmap.md"}
    elseif(Test-Path "$PP\roadmap.md"){$rp="roadmap.md"}
    elseif(Test-Path "$PP\roadmap"){$rp="roadmap/ (dir)"}
    if($rp){$sz=Get-FileSize "$PP\$rp";Write-Result $ok Roadmap Found "$rp ($sz)";$r["roadmap"]=$ok;$sm["roadmap"]=10}
    else{Write-Result $no Roadmap Missing "No roadmap docs found";$r["roadmap"]=$no;$sm["roadmap"]=0}

    $prs=0;$prd=@()
    if(Test-Path "$PP\.git"){
        try{$cc=&git -C "$PP" log --oneline -10 2>$null|Measure-Object|ForEach-Object{$_.Count}}catch{Write-Warning "git log failed: $_";$cc=0}
        if($cc-gt0){$prs+=5;$prd+="$cc commits in HEAD";try{$gp=&gh pr list --limit 5 2>$null}catch{Write-Warning "gh pr list failed: $_";$gp=$null};if($LASTEXITCODE-eq0-and$gp){$prd+="$(($gp|Measure-Object|ForEach-Object{$_.Count})) open PR(s)";$prs+=3}}
    }else{$prd+="no .git dir (score limited)"}
    $pf=Get-ChildItem -Path "$PP" -Recurse -Include "*PROBLEM*REPORT*","*bug-report*","*incident*" -Exclude "*node_modules*",".git","*vendor*" -ErrorAction SilentlyContinue|Select-Object -First 3
    if($pf){$prd+="Problem Report: $($pf.Count) file(s) ($($pf[0].Name))";$prs=[math]::Max($prs,5)}
    $pi=if($prs-ge8){$ok}elseif($prs-ge3){$warn}else{$no}
    Write-Result $pi PR "Pull Request + Problem Report" ($prd-join" | ")
    $r["pr"]=$pi;$sm["pr"]=$prs

    $prdF=Get-ChildItem -Path "$PP" -Recurse -Include "*PRD*","*spec*","*requirements*","*srs*" -Exclude "*node_modules*",".git","*vendor*" -File -ErrorAction SilentlyContinue|Select-Object -First 5
    if($prdF){Write-Result $ok PRD Found "$($prdF.Count) files (e.g., $($prdF[0].Name))";$r["prd"]=$ok;$sm["prd"]=10}
    else{Write-Result $no PRD Missing "No PRD, spec, or requirements files";$r["prd"]=$no;$sm["prd"]=0}

    if(Test-Path "$PP\README.md"){
        $sz=Get-FileSize "$PP\README.md"
        $c=Get-Content "$PP\README.md" -Raw -ErrorAction SilentlyContinue;$q=10
        if($c){
            if($c-notmatch'# '){$q-=2}
            if($c-notmatch'setup|install|getting started|usage|empezar|instalacion'){$q-=2}
            if($c.Length-lt200){$q-=2}
            if($c.Length-lt100){$q-=3}
        }
        $q=[math]::Max(1,$q);$qi=if($q-ge8){$ok}elseif($q-ge5){$warn}else{$no}
        Write-Result $qi README Found "$sz (quality score: $q/10)";$r["readme"]=$qi;$sm["readme"]=$q
    }else{Write-Result $no README Missing "No README.md at project root";$r["readme"]=$no;$sm["readme"]=0}

    $td=Get-ChildItem -Path "$PP" -Directory -Include "tests","__tests__","spec","test","cypress" -ErrorAction SilentlyContinue
    $tf=Get-ChildItem -Path "$PP" -Recurse -Include "*test*","*spec*","*suite*" -File -Exclude "*node_modules*",".git","*vendor*" -ErrorAction SilentlyContinue|Select-Object -First 10
    if($td){Write-Result $ok Tests "Test dirs found" "$($td.Count) dir(s): $($td.Name -join ', ')";$r["tests"]=$ok;$sm["tests"]=10}
    elseif($tf.Count-ge3){Write-Result $ok Tests "Test files found" "$($tf.Count) files found";$r["tests"]=$ok;$sm["tests"]=8}
    elseif($tf.Count-ge1){Write-Result $warn Tests "Minimal test files" "$($tf.Count) files found";$r["tests"]=$warn;$sm["tests"]=5}
    else{Write-Result $no Tests "No test artifacts" "No test dirs or files found";$r["tests"]=$no;$sm["tests"]=0}

    $cf=@();@(".github\workflows","GitHub Actions","Jenkinsfile","Jenkins",".gitlab-ci.yml","GitLab CI","azure-pipelines.yml","Azure Pipelines",".circleci\config.yml","CircleCI","Dockerfile","Docker")|%{$i=0}{if($i%2-eq0){$k=$_}elseif(Test-Path "$PP\$k"){$cf+=$_};$i++}
    if($cf.Count-ge2){Write-Result $ok "CI/CD" "Multiple configs" ($cf-join', ');$r["cicd"]=$ok;$sm["cicd"]=10}
    elseif($cf.Count-eq1){Write-Result $warn "CI/CD" "Single config" $cf[0];$r["cicd"]=$warn;$sm["cicd"]=5}
    else{Write-Result $no "CI/CD" "Not found" "No CI/CD config detected";$r["cicd"]=$no;$sm["cicd"]=0}

    $mf=@()
    foreach($p in @("*sentry*","*datadog*","*newrelic*","*grafana*","*prometheus*","*openTelemetry*","*appinsights*","*bugsnag*","*rollbar*","*logstash*","*honeycomb*","*dynatrace*")){$m=Get-ChildItem -Path "$PP" -Recurse -Include $p -File -Exclude "*node_modules*",".git" -ErrorAction SilentlyContinue|Select-Object -First 1;if($m){$mf+=$m.Name}}
    $hl=(Test-Path "$PP\logs")-or(Get-ChildItem -Path "$PP" -Directory -Include "metrics","monitoring","alerts" -ErrorAction SilentlyContinue)
    if($mf.Count-ge1){Write-Result $ok Monitoring "APM/tracing found" "$($mf[0]) (+$($mf.Count-1) more)";$r["monitoring"]=$ok;$sm["monitoring"]=10}
    elseif($hl){Write-Result $warn Monitoring "Basic logging only" "logs/ or metrics/ dir exists, no APM";$r["monitoring"]=$warn;$sm["monitoring"]=5}
    else{Write-Result $no Monitoring "Not found" "No APM/tracing/logging config";$r["monitoring"]=$no;$sm["monitoring"]=0}

    $ts=($sm.Values|Measure-Object -Sum).Sum;$ms=$sm.Count*10
    $pct=if($ms-gt0){[math]::Round(($ts/$ms)*100,1)}else{0}
    Write-Host "  Score: $ts/$ms ($pct%)" -ForegroundColor $(if($pct-ge80){"Green"}elseif($pct-ge50){"Yellow"}else{"Red"})
    $miss=@()
    if($r["roadmap"]-eq$no){$miss+="Roadmap"}
    if($r["prd"]-eq$no){$miss+="PRD"}
    if($r["readme"]-eq$no){$miss+="README"}
    if($miss.Count-gt0){Write-Host "  CRIT: Sin $($miss-join', ')" -ForegroundColor Red}
    return@{round=$R;results=$r;scores=$sm;totalScore=$ts;maxScore=$ms;pct=$pct;criticalMissing=$miss}
}

try {
if(-not(Test-Path $ProjectPath)){Write-Error "Proj path not found: $ProjectPath";exit 2}
$pp=$ProjectPath

if($ProjectType-eq"auto"){
    $sigs=@()
    if(Test-Path "$pp\package.json"){
        $pkg=Get-Content "$pp\package.json" -Raw -ErrorAction SilentlyContinue
        if($pkg-match'"react"|"next"|"vue"'){$sigs+="frontend"}
        if($pkg-match'"express"|"fastify"'){$sigs+="backend"}
        if($sigs.Count-eq0-and$pkg){$sigs+="node"}
    }
    if(Test-Path "$pp\go.mod"){$sigs+="backend"}
    if(Test-Path "$pp\pubspec.yaml"){$sigs+="mobile"}
    if(Test-Path "$pp\Dockerfile"){$sigs+="infra"}
    if($sigs-contains"frontend"-and$sigs-contains"backend"){$ProjectType="fullstack"}
    elseif($sigs-contains"frontend"){$ProjectType="fe"}
    elseif($sigs-contains"backend"){$ProjectType="be"}
    elseif($sigs-contains"mobile"){$ProjectType="mobile"}
    else{$ProjectType="be"}
}

for($i=1;$i-le$Iterations;$i++){
    $round=Invoke-Check -R $i -PP $pp -PT $ProjectType;$script:roundResults+=$round
    if($i-lt$Iterations){Start-Sleep -Seconds 1}
}

$elapsed=[math]::Round(((Get-Date)-$script:startTime).TotalSeconds,1)
$first=$script:roundResults[0];$last=$script:roundResults[-1]
Write-Host "`n  Proyecto: $pp`n  Tipo: $ProjectType`n  Iteraciones: $Iterations en ${elapsed}s"

$arts=@("roadmap","pr","prd","readme","tests","cicd","monitoring")
Write-Host "  | $('Artifact'.PadRight(19)) | $('Baseline'.PadRight(8)) | $('Current'.PadRight(8)) | $('Delta'.PadRight(8)) |" -ForegroundColor Gray
Write-Host "  $('-'*55)" -ForegroundColor Gray
foreach($a in $arts){
    $bs=if($first.scores[$a]){$first.scores[$a]}else{0};$ls=if($last.scores[$a]){$last.scores[$a]}else{0}
    $d=$ls-$bs;$ds=if($d-gt0){"+$d"}elseif($d-lt0){"$d"}else{"-"};$dc=if($d-gt0){"Green"}elseif($d-lt0){"Red"}else{"Gray"}
    Write-Host "  | $($a.PadRight(19)) | $($bs.ToString().PadLeft(8)) | $($ls.ToString().PadLeft(8)) | " -NoNewline -ForegroundColor Gray
    Write-Host $ds.PadLeft(8) -NoNewline -ForegroundColor $dc;Write-Host " |" -ForegroundColor Gray
}
$bt=$first.totalScore;$lt=$last.totalScore;$dt=$lt-$bt;$dtc=if($dt-gt0){"Green"}elseif($dt-lt0){"Red"}else{"Gray"}
Write-Host "  | $('TOTAL'.PadRight(19)) | $($bt.ToString().PadLeft(8)) | $($lt.ToString().PadLeft(8)) | " -NoNewline -ForegroundColor Gray
Write-Host $dt.ToString().PadLeft(8) -NoNewline -ForegroundColor $dtc;Write-Host " |" -ForegroundColor Gray

$opct=$last.pct
$g=if($opct-ge90){"A"}elseif($opct-ge80){"B"}elseif($opct-ge60){"C"}elseif($opct-ge40){"D"}else{"F"}
Write-Host "`n  Grade: $g ($opct%)" -ForegroundColor $(if($opct-ge80){"Green"}elseif($opct-ge60){"Yellow"}else{"Red"})
if($last.criticalMissing.Count-gt0){Write-Host "  Critical: $($last.criticalMissing-join', ')" -ForegroundColor Red}

if($SaveMetrics){
    $mdir="$pp\docs\metricas";if(-not(Test-Path $mdir)){try{New-Item -ItemType Directory -Path $mdir -Force|Out-Null}catch{Write-Warning "Failed to create metrics dir: $_"}}
    $ts2=Get-Date -Format "yyyyMMdd-HHmmss";$bf="$mdir\intake-baseline.json"
    $m=@{timestamp=(Get-Date -Format "yyyy-MM-dd HH:mm:ss");project=$pp;type=$ProjectType;iterations=$Iterations;elapsedSeconds=$elapsed;baseline=@{};current=@{};delta=@{};overall_pct=$opct;critical_gaps=$last.criticalMissing}
    foreach($a in $arts){$m.baseline[$a]=if($first.scores[$a]){$first.scores[$a]}else{0};$m.current[$a]=if($last.scores[$a]){$last.scores[$a]}else{0};$m.delta[$a]=$m.current[$a]-$m.baseline[$a]}
    try{($m|ConvertTo-Json)|Out-File -FilePath $bf -Encoding utf8}catch{Write-Warning "Failed to save metrics JSON: $_"}
    $mdf="$mdir\intake-report-$ts2.md"
    $mdc=@"
# Intake Verification Report

**Project**: $pp
**Type**: $ProjectType
**Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Iterations**: $Iterations
**Elapsed**: ${elapsed}s
**Grade**: $g ($opct%)

## Score Progression

| Artifact | Baseline | Current | Delta |
|----------|----------|---------|-------|
"@
    foreach($a in $arts){$b=if($first.scores[$a]){$first.scores[$a]}else{0};$c=if($last.scores[$a]){$last.scores[$a]}else{0};$d=$c-$b;$ds2=if($d-gt0){"+$d"}elseif($d-lt0){"$d"}else{"-"};$mdc+="`n| $a | $b/10 | $c/10 | $ds2 |"}
    $mdc+="`n## Artifact Details (Final Iteration)`n`n| Artifact | Status | Detail |`n|----------|--------|--------|"
    $smap=@{roadmap="Roadmap";pr="PR";prd="PRD/Specs";readme="README";tests="Tests";cicd="CI/CD";monitoring="Monitoring"}
    foreach($a in $arts){$ic=if($last.results[$a]){$last.results[$a]}else{"-"};$sc=if($last.scores[$a]){$last.scores[$a]}else{0};$mdc+="`n| $($smap[$a]) | $ic | Score: $sc/10 |"}
    if($last.criticalMissing.Count-gt0){$mdc+="`n## Critical Gaps";foreach($x in $last.criticalMissing){$mdc+="`n- **$x**: Missing - Blocker"}}
    try{$mdc|Out-File -FilePath $mdf -Encoding utf8}catch{Write-Warning "Failed to save metrics report: $_"}
    Write-Host "  Metrics: $bf`n  Report: $mdf" -ForegroundColor Cyan
}

if($last.criticalMissing.Count-gt0){exit 2}
if($opct-lt80){exit 1}
exit 0
} catch {
    Write-Error "Intake verification failed: $_"
    exit 1
}
