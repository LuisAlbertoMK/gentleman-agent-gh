#Requires -Version 5.1
<#.SYNOPSIS Gentle-AI -- Windows installer. Channels: stable, beta, nightly.#>
$ErrorActionPreference="Stop";Set-StrictMode -V Latest
chcp 65001>$null 2>&1
try{[Console]::OutputEncoding=[Text.Encoding]::UTF8}catch{}
$o="Gentleman-Programming";$r="gentle-ai";$b="gentle-ai"
$gu="github.com/gentleman-programming/gentle-ai"
New-Alias jp Join-Path
function i{Write-Host"[info] $args"-fo Blue}
function s{Write-Host"[ok] $args"-fo Green}
function w{Write-Host"[warn] $args"-fo Yellow}
function e{Write-Host"[error] $args"-fo Red}
function t{Write-Host"`n==> $args"-fo Cyan}
function die{e "$args";exit 1}
function plat{
t"Detecting platform"
$a=if([Environment]::Is64BitOperatingSystem){if($env:PROCESSOR_ARCHITECTURE-eq"ARM64"){"arm64"}else{"amd64"}}else{die"32-bit not supported"}
s"Platform: Windows ($a)";$a
}
function prereq{
t"Checking prerequisites"
$m=@()
if(-not(gcm "curl"-ea 0)){$m+="curl"}
if(-not(gcm "git"-ea 0)){$m+="git"}
if($m){die"Missing: $($m-join', ')"}
s"curl and git available"
}
function method{
param($f,$c)
if($c-eq"beta"){
if($f-ne"auto"-and$f-ne"go"){die"Beta needs -Method go"}
i"Beta via go";"go"
}elseif($f-ne"auto"){i"Using: $f";$f
}else{t"Detecting method";i"Binary from GitHub";"binary"}
}
function envpat{
param($n,$p)
$c=[Environment]::GetEnvironmentVariable($n,0)
if(-not$c){si "Env:$n"$p;return}
$k=$c.Split(',',1).Trim()
if($k-contains$p){return}
si "Env:$n"("{0},{1}"-f$p,$c)
}
function goinst{
param($c="stable")
t"Go install..."
$v=if($c-eq"beta"){"main"}else{"latest"}
$g="github.com/$($o.ToLower())/$r/cmd/$b@$v"
i"Running: go install $g"
if($c-eq"beta"){"GONOSUMDB","GOPRIVATE","GONOPROXY"|%{envpat $_ $gu}}
& go install $g
if($LASTEXITCODE){die"Go failed"}
$b2=& go env GOBIN 2>$null
if(-not$b2){$p=& go env GOPATH 2>$null;$b2=jp $p"bin"}
if($env:PATH-notlike"*$b2*"){w"$b2 missing PATH";w"Add it to PATH"}
s"Installed $b"
}
function bininst{
param($a)
$I=0
i"Fetching..."
try{$rel=irm "https://api.github.com/repos/$o/$r/releases/latest"-Headers @{'User-Agent'='gentle-ai-installer'}}catch{die"Failed. Try -Method go"}
$v=$rel.tag_name
if(-not$v){die"Unknown version"}
s"Latest: $v"
$vn=$v.TrimStart("v")
$zf="${b}_${vn}_windows_${a}.zip"
$du="https://github.com/$o/$r/releases/download/$v/$zf"
$cu="https://github.com/$o/$r/releases/download/$v/checksums.txt"
$td=jp $env:TEMP"gentle-ai-install-$(Get-Random)"
ni-ItemType Directory $td-Force|Out-Null
try{
i"Dl $zf..."
$ap=jp $td $zf
iwr $du -OutFile $ap -UseBasicParsing
$fs=(gi $ap).Length
if($fs-lt1000){die"Too small ($fs bytes)"}
s"Got ($fs bytes)"
i"Verify..."
try{
$cp=jp $td"checksums.txt"
iwr $cu -OutFile $cp -UseBasicParsing
$ln=(gc $cp)|?{$_-match $zf}
if($ln){
$ex=($ln-split"\s+")[0]
$ac=(Get-FileHash $ap).Hash.ToLower()
if($ac-ne$ex){die"Bad checksum: $ex vs $ac"}
s"Checksum OK"
}else{
if($I){w"No checksum"}
else{die"No checksum. Use -Insecure"}
}
}catch{
if($I){w"No checksum file"}
else{die"No checksum file. Use -Insecure"}
}
i"Extracting..."
Expand-Archive $ap $td -Force
$bp=jp $td"$b.exe"
if(-not(Test-Path $bp)){die"No bin"}
$id=jp $env:LOCALAPPDATA"gentle-ai\bin"
if(-not(Test-Path $id)){ni-ItemType Directory $id-Force|Out-Null}
$dt=jp $id"$b.exe"
i"To $dt..."
cp $bp $dt -Force
s"Installed $b to $dt"
$up=[Environment]::GetEnvironmentVariable("PATH",1)
$pr=$up-split';'|?{$_ -and$_.TrimEnd('\')-ieq$id.TrimEnd('\')}
if(-not$pr){
[Environment]::SetEnvironmentVariable("PATH",$(if($up){"$up;$id"}else{$id}),1)
s"PATH += $id"
}
$ps=$env:PATH-split';'|?{$_ -and$_.TrimEnd('\')-ieq$id.TrimEnd('\')}
if(-not$ps){$env:PATH+=";$id"}
}finally{
ri $td -Recurse -Force -ea 0
}
}
function verify{
t"Verifying installation"
$gp=$null
if(gcm "go"-ea 0){$gp=& go env GOPATH 2>$null}
$locs=@(jp $env:LOCALAPPDATA"gentle-ai\bin\$b.exe")
if($gp){$locs+=jp $gp"bin\$b.exe"}
foreach($loc in $locs){
if(-not($loc -and(Test-Path $loc))){continue}
$env:GENTLE_AI_NO_SELF_UPDATE="1"
$vo=& $loc --version 2>&1
ri Env:GENTLE_AI_NO_SELF_UPDATE -ea 0
s"$b at $loc`: $vo"
$up=[Environment]::GetEnvironmentVariable("PATH",1)
$bd=Split-Path $loc
if($up-notlike"*$bd*"){w"Binary not in PATH"}
return
}
w"Cannot verify. Restart terminal."
}
function next{
param($c="stable")
$t=if($c-eq"beta"){"'`$env:GENTLE_AI_CHANNEL=`"beta`";$b install' to persist"}else{"'$b' to start TUI"}
Write-Host "`nDone!`n"-fo Green
Write-Host "Next:"-fo White
Write-Host"1. Run $t"-fo Cyan
Write-Host"2. Pick agents/tools"-fo Cyan
Write-Host"3. Follow prompts"-fo Cyan
Write-Host"`nHelp: $b --help"-fo DarkGray
Write-Host"Docs: https://github.com/$o/$r"-fo DarkGray
}
function Main {
param(
[ValidateSet("auto","go","binary")]$M="auto",
[ValidateSet("stable","beta","nightly")]$C=$(if($env:GENTLE_AI_CHANNEL){$env:GENTLE_AI_CHANNEL}else{"stable"}),
$D="",
[switch]$I
)
$arch=plat;prereq
if($C-eq"nightly"){$C="beta"}
$m=method $M $C
switch($m){"go"{goinst $C}"binary"{bininst $arch}}
verify;next $C
}
Main @args