#requires -Version 5.1
<#
.SYNOPSIS Pull-from-Upstream Workflow — detect, classify, and selectively apply upstream changes.
#>
[CmdletBinding()]param([Parameter(Position=0)][ValidateSet('Check','Apply-New','Apply-File')][string]$Mode='Check',[string]$TargetFile='',[string]$Branch='main',[string]$Remote='upstream')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest;$rr=Resolve-Path "$PSScriptRoot/.."
trap{try{Pop-Location}catch{};exit 1};Push-Location $rr
function Test-GitRemote([string]$N){(git remote) -contains $N}
$pm=@{u='skills/';p='.agents/skills/';n='Skills'},@{u='scripts/';p='scripts/';n='Scripts'},@{u='';p='';n='Root files'}
if(-not(Test-GitRemote $Remote)){Write-Warning "Remote '$Remote' not found";Pop-Location;exit 1}
Write-Host "Fetch $Remote/$Branch...";$e=$ErrorActionPreference;$ErrorActionPreference='Continue';git fetch $Remote $Branch 2>&1 | Out-Null;$ErrorActionPreference=$e
if($LASTEXITCODE -ne 0){Write-Warning "Fetch failed";Pop-Location;exit 1}
$rem="$Remote/$Branch";$loc='HEAD'
$b=git rev-list --count "${loc}..${rem}" 2>&1;$a=git rev-list --count "${rem}..${loc}" 2>&1
Write-Host "Behind:$b Ahead:$a Total:$([int]$b+[int]$a)"
$nu=@();$mo=@();$ou=@()
foreach($m in $pm){$up=$m.u;$lo=$m.p;$l=$m.n
if([string]::IsNullOrEmpty($up)){$uf=@(git ls-tree -r --name-only $rem | Where-Object {$_ -notmatch '^skills/|^scripts/|^\.' -and $_ -notlike '*/'});$lf=@(git ls-tree -r --name-only $loc | Where-Object {$_ -notmatch '^\.agents/skills/|^scripts/|^\.' -and $_ -notlike '*/'})}
else{$uf=@(git ls-tree -r --name-only $rem -- "$up" | ForEach-Object {if(-not[string]::IsNullOrEmpty($lo)-and$lo-ne$up){$_.Replace($up,$lo)}else{$_}});$lf=@(git ls-tree -r --name-only $loc -- "$lo" | ForEach-Object {$_})}
$us=@($uf | Sort-Object -Unique);$ls=@($lf | Sort-Object -Unique)
$n=@($us | Where-Object {$_ -notin $ls});$c=@($us | Where-Object {$_ -in $ls});$o=@($ls | Where-Object {$_ -notin $us})
if($l-eq'Root files'){$n=$n | Where-Object {$_ -notmatch '\.md$|LICENSE'}}elseif($l-eq'Scripts'){$n=$n | Where-Object {$_ -notmatch 'install\.(ps1|sh)$'}}
$mod=@()
if($l-ne'Root files'){$uh=@{};if([string]::IsNullOrEmpty($up)){git ls-tree $rem | ForEach-Object {$p=$_-split'\s+';$uh[$p[3]]=$p[2]}}else{git ls-tree -r $rem -- "$up" | ForEach-Object {$p=$_-split'\s+';$fp=$p[3];if(-not[string]::IsNullOrEmpty($lo)-and$lo-ne$up){$fp=$fp.Replace($up,$lo)};$uh[$fp]=$p[2]}};$lh=@{};if([string]::IsNullOrEmpty($lo)){git ls-tree $loc | ForEach-Object {$p=$_-split'\s+';$lh[$p[3]]=$p[2]}}else{git ls-tree -r $loc -- "$lo" | ForEach-Object {$p=$_-split'\s+';$lh[$p[3]]=$p[2]}};$c | ForEach-Object {if($uh[$_]-and$lh[$_]-and$uh[$_]-ne$lh[$_]){$mod+=$_}};if($l-eq'Scripts'){$mod=$mod | Where-Object {$_ -notmatch 'install\.(ps1|sh)$'}}}
Write-Host "--- $l ---"
if($n.Count){Write-Host "NEW $($n.Count)";$n | ForEach-Object {Write-Host "  + $_"}}
if($mod.Count){Write-Host "MOD $($mod.Count)";$mod | ForEach-Object {Write-Host "  ~ $_"}}
if($o.Count){Write-Host "OURS $($o.Count)";$o | ForEach-Object {Write-Host "  - $_"}}
if(-not$n.Count-and-not$mod.Count-and-not$o.Count){Write-Host "(none)"}
$nu+=$n;$mo+=$mod;$ou+=$o}
Write-Host "New:$($nu.Count) Mod:$($mo.Count) Ours:$($ou.Count)"
if($Mode-eq'Apply-New'){$sf=$nu | Where-Object {$_ -match '^\.agents/skills/' -or $_ -match '^scripts/'};$sk=@($nu | Where-Object {$_ -notin $sf})
if($sk.Count){Write-Host "Skip $($sk.Count) non-skill/script"}
if(-not$sf.Count){Write-Host "No new skills/scripts";Pop-Location;exit 0}
Write-Host "Apply $($sf.Count) files...";$app=0;$fail=0
foreach($f in $sf){$up=$f
foreach($m in $pm){if(-not[string]::IsNullOrEmpty($m.p)-and$f.StartsWith($m.p)){$up=$f.Replace($m.p,$m.u);break}}
$pd=Split-Path $f -Parent
if(-not[string]::IsNullOrEmpty($pd)-and-not(Test-Path $pd)){New-Item -ItemType Directory -Path $pd -Force | Out-Null}
Write-Host "  + $f"
$e2=$ErrorActionPreference;$ErrorActionPreference='Continue';git checkout "$Remote/$Branch" -- "$up" 2>&1 | Out-Null;$ErrorActionPreference=$e2
if($LASTEXITCODE -eq 0){if($up-ne$f){if(Test-Path $up){Move-Item -Path $up -Destination $f -Force}};$null=git add $f 2>&1;$app++}else{Write-Warning "FAILED $up";$fail++}}
Write-Host "$app applied, $fail failed"
if($app){Write-Host "Staged. git status then commit"}}
if($Mode-eq'Apply-File'){
if([string]::IsNullOrEmpty($TargetFile)){Write-Warning "Usage: -TargetFile path";Pop-Location;exit 1}
$up=$TargetFile
foreach($m in $pm){if(-not[string]::IsNullOrEmpty($m.p)-and$TargetFile.StartsWith($m.p)){$up=$TargetFile.Replace($m.p,$m.u);break}}
Write-Host "Checkout '$up' from $Remote/$Branch..."
git checkout "$Remote/$Branch" -- "$up" 2>&1
if($LASTEXITCODE -eq 0){if($up-ne$TargetFile){$pd=Split-Path $TargetFile -Parent;if(-not[string]::IsNullOrEmpty($pd)-and-not(Test-Path $pd)){New-Item -ItemType Directory -Path $pd -Force | Out-Null};Move-Item -Path $up -Destination $TargetFile -Force};Write-Host "Done. git diff --cached $TargetFile"}else{Write-Warning "Failed $up"}}
Pop-Location;exit 0
