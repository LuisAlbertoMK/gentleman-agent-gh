#requires -Version 7.6
<#
.SYNOPSIS
    Unified verify profiles E1/E2/E3 -- runnable checks for triple-verify gates.
#>
param(
    [ValidateSet('E1','E2','E3','All')][string]$ProfileName='All',
    [switch]$Json,
    [string]$Root=(Split-Path $PSScriptRoot -Parent)
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$r=@{profile=$ProfileName;checks=@();passed=0;failed=0;errors=@()}
function Add-Check{
    param([string]$N,[bool]$P,[string]$D='')
    $script:r.checks+=@{name=$N;passed=$P;detail=$D}
    if($P){$script:r.passed++}else{$script:r.failed++}
    Write-Host ("[{0}] {1} -- {2}" -f $(if($P){'PASS'}else{'FAIL'}),$N,$D) -ForegroundColor $(if($P){'Green'}else{'Red'})
}
function Invoke-E1Checks{
    $sDir=Join-Path $Root 'scripts'
    $bs=@()
    Get-ChildItem "$sDir\*.ps1" | ForEach-Object {
        $e=$null
        $null=[System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$null,[ref]$e)
        if($e){$bs+="$($_.Name): $($e.Message)"}
    }
    if($bs.Count-eq0){Add-Check 'PS Syntax' $true 'All scripts parse OK'}else{Add-Check 'PS Syntax' $false "$($bs.Count) files with errors: $($bs -join '; ')"}
    $skd=Join-Path $Root '.agents\skills'
    $bf=@()
    if(Test-Path $skd){
        Get-ChildItem "$skd\*\SKILL.md" | ForEach-Object {
            $c=[IO.File]::ReadAllText($_.FullName)
            if($c-match'^---'){
                $end=$c.IndexOf('---',3)
                if($end-eq-1){$bf+="$($_.Directory.Name): unclosed frontmatter"}
            }
        }
    }
    if($bf.Count-eq0){Add-Check 'Skill Frontmatter' $true 'All frontmatter valid'}else{Add-Check 'Skill Frontmatter' $false "$($bf.Count) issues: $($bf -join '; ')"}
    $xs=Join-Path $sDir 'cross-ref-check.ps1'
    if(Test-Path $xs){& $xs;Add-Check 'Cross-Ref Check' ($LASTEXITCODE-eq0) "exit $LASTEXITCODE"}else{Add-Check 'Cross-Ref Check' $true 'not found (skipped)'}
}
function Invoke-E2Checks{
    $ps=Join-Path $Root 'scripts\pssa-gate.ps1'
    if(Test-Path $ps){& $ps -Mode Check;Add-Check 'PSSA Gate' ($LASTEXITCODE-eq0) "exit $LASTEXITCODE"}else{Add-Check 'PSSA Gate' $true 'not found (skipped)'}
    $sf=@()
    $sPat=@('password\s*=','secret\s*=','api[_-]?key\s*=','token\s*=','connection\s*string\s*=',
             'GH_TOKEN\s*=','GITHUB_TOKEN\s*=','ghp_','gho_','ghs_','github_pat_','ctx7sk_','AKIA',
             'xox[abprs]-\d+','sk-[a-zA-Z0-9]{20,}','-----BEGIN\s+(RSA|EC|DSA|PRIVATE|OPENSSH)\s+KEY')
    $sDirs=@((Join-Path $Root 'scripts'),(Join-Path $Root '.agents\skills'),(Join-Path $Root '.github\workflows'),(Join-Path $Root 'docs'))
    foreach($dir in $sDirs){
        if(-not(Test-Path $dir)){continue}
        Get-ChildItem $dir -Recurse -Include '*.ps1','*.md','*.psm1' | ForEach-Object {
            $c=[IO.File]::ReadAllText($_.FullName)
            foreach($p in $sPat){if($c-match$p){$sf+="$($_.Name): matched '$p'"}}
        }
    }
    if($sf.Count-eq0){Add-Check 'Secrets Scan' $true 'No patterns detected'}else{Add-Check 'Secrets Scan' $false "$($sf.Count) potential secrets: $($sf -join '; ')"}
    Push-Location $Root
    $gs=$(git status --short)
    Pop-Location
    if([string]::IsNullOrWhiteSpace($gs)){Add-Check 'Git Hygiene' $true 'Working tree clean'}else{Add-Check 'Git Hygiene' $false 'Uncommitted changes detected'}
    $rp=Join-Path $Root 'review-rules.jsonc'
    if(Test-Path $rp){
        try{
            $raw=Get-Content $rp -Raw -Encoding UTF8
            $stripped=$raw-replace'(?m)^\s*//.*$',''-replace'(?m)\s*//[^"\n]*$',''-replace'(?s)/\*.*?\*/',''
            $null=$stripped | ConvertFrom-Json
            Add-Check 'review-rules.jsonc' $true 'Parses OK'
        }catch{Add-Check 'review-rules.jsonc' $false "Parse error: $_"}
    }else{Add-Check 'review-rules.jsonc' $true 'Not found (skipped)'}
}
function Invoke-E3Checks{
    $cd=Join-Path $Root '.agents\skills'
    $gd="$env:USERPROFILE\.config\opencode\skills"
    $mj=@()
    if((Test-Path $cd)-and(Test-Path $gd)){
        Get-ChildItem $cd -Directory | Where-Object {$_.Name -ne '_shared'} | ForEach-Object {
            if(-not(Test-Path (Join-Path $gd $_.Name))){$mj+=$_.Name}
        }
    }
    if($mj.Count-eq0){Add-Check 'Global Junctions' $true 'All junctions present'}else{Add-Check 'Global Junctions' $false "Missing: $($mj -join ', ')"}
    $pj=Join-Path $Root '.project.json'
    if(Test-Path $pj){
        try{
            $pjc=Get-Content $pj -Raw -Encoding UTF8 | ConvertFrom-Json
            $dc=$pjc.score.dimensions.PSObject.Properties.Name.Count
            $sc=$pjc.score.current
            if($dc-ge6-and$sc-ge0-and$sc-le10){Add-Check '.project.json' $true "$dc dims, score $sc/10"}else{Add-Check '.project.json' $false "Invalid structure: $dc dims, score $sc"}
        }catch{Add-Check '.project.json' $false "Parse error: $_"}
    }else{Add-Check '.project.json' $false 'Not found'}
    $sDir=Join-Path $Root 'scripts'
    $mh=@()
    [IO.Directory]::EnumerateFiles($sDir, '*.ps1') | ForEach-Object {
        $c=[IO.File]::ReadAllText($_)
        if($c -notmatch '\.SYNOPSIS'){$mh+=$_.Name}
    }
    if($mh.Count-eq0){Add-Check 'Script Help' $true 'All scripts have .SYNOPSIS'}else{Add-Check 'Script Help' $false "$($mh.Count) missing: $($mh -join ', ')"}
    $cp=Join-Path $Root 'CYCLE.md'
    if(Test-Path $cp){
        $cc=Get-Content $cp -Raw -Encoding UTF8
        $hb=$cc-match'\|\s*Item\s*\|'
        $hl=$cc-match'LOOP:'
        $hm=$cc-match'\|\s*Metric\s*\|'
        $dt=@()
        if($hb){$dt+='backlog'}
        if($hl){$dt+='loop'}
        if($hm){$dt+='metrics'}
        Add-Check 'CYCLE.md' $true "Sections found: $($dt -join ', ')"
    }else{Add-Check 'CYCLE.md' $false 'Not found'}
}
switch($ProfileName){
    'E1'{Invoke-E1Checks}
    'E2'{Invoke-E2Checks}
    'E3'{Invoke-E3Checks}
    'All'{Invoke-E1Checks;Invoke-E2Checks;Invoke-E3Checks}
}
$r.allPassed=($r.failed-eq0)
if($Json){
    $r.timestamp=(Get-Date -Format 'o')
    Write-Output ($r | ConvertTo-Json -Depth 3)
}
exit $(if($r.allPassed){0}else{1})
