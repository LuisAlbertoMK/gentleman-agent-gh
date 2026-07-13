#requires -Version 7.6
#Requires -Module @{ModuleName='PSScriptAnalyzer'; ModuleVersion='1.20.0'}
<#
.SYNOPSIS Self-Healing PSSA Gate.
.DESCRIPTION Check: scan+report. Fix: auto-fix BOM+switch defaults. Trend: compare vs baseline.
#>
[CmdletBinding()]param(
[Parameter(Position=0)][ValidateSet('Check','Fix','Trend','Incremental')][string]$Mode='Check',
[string]$Path=(Get-Location).Path,[switch]$Quiet,
[string]$BaselineFile=(Join-Path $Path 'docs\metricas\pssa-baseline.json'))
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$xd=@('experiments','skills');$fr=@('PSUseBOMForUnicodeEncodedFile','PSAvoidDefaultValueSwitchParameter');$tr=@('PSAvoidUsingWriteHost')

function Write-Status { param([string]$Message) if (-not $Quiet) { Write-Host "  $Message" } }
function Get-PSSAViolation { param([string]$TargetPath,[string[]]$Files)
if($Files -and $Files.Count -gt 0){$all=@();foreach($f in $Files){if(Test-Path $f){$all+=@(Invoke-ScriptAnalyzer -Path $f -Severity Warning,Error 2>$null)}};return $all}
@(Invoke-ScriptAnalyzer -Path (Resolve-Path $TargetPath) -Recurse -Severity Warning,Error 2>$null) }
function Get-FullPath { param([string]$ScriptName,[string]$BasePath)
if ([System.IO.Path]::IsPathRooted($ScriptName)){return $ScriptName}
$j=Join-Path $BasePath $ScriptName;if(Test-Path $j){return (Resolve-Path $j).Path}
$j=Join-Path (Join-Path $BasePath 'scripts') $ScriptName;if(Test-Path $j){return (Resolve-Path $j).Path}
$j=Join-Path (Get-Location).Path $ScriptName;if(Test-Path $j){return (Resolve-Path $j).Path}
return $ScriptName }

function Resolve-BomEncoding { param([array]$Violations);$n=0;$s=@{}
foreach($v in $Violations){$fp=Get-FullPath -ScriptName $v.ScriptName -BasePath $target;if($s.ContainsKey($fp)){continue};$s[$fp]=$true
try{$raw=[System.IO.File]::ReadAllBytes($fp)}catch{Write-Warning "  BOM: no read $fp";continue}
$bom=$raw.Length-ge3-and$raw[0]-eq0xEF-and$raw[1]-eq0xBB-and$raw[2]-eq0xBF;if($bom){Write-Status "  BOM: present - $fp";continue}
$na=$false;foreach($b in $raw){if($b-gt127){$na=$true;break}};if(-not$na){Write-Status "  BOM: skip ASCII - $fp";continue}
try{$p=[System.Text.Encoding]::UTF8.GetPreamble();$t=[System.Text.Encoding]::UTF8.GetString($raw);[System.IO.File]::WriteAllBytes($fp,$p+[System.Text.Encoding]::UTF8.GetBytes($t));Write-Status "  BOM: FIXED - $fp";$n++}catch{Write-Warning "  BOM: ERR $fp - $_"}}
return $n }

function Resolve-SwitchDefault { param([array]$Violations);$n=0;$s=@{}
foreach($v in $Violations){$fp=Get-FullPath -ScriptName $v.ScriptName -BasePath $target;$k="$($fp):$($v.Line)";if($s.ContainsKey($k)){continue};$s[$k]=$true
try{$ln=Get-Content -LiteralPath $fp}catch{Write-Warning "  SWITCH: no read $fp";continue}
$idx=$v.Line-1;$o=$ln[$idx];$nw=$o-replace'(\[switch\]\s*\$\w+)\s*=\s*\$(?:false|true)','$1'
if($nw-ne$o){$ln[$idx]=$nw;try{Set-Content -LiteralPath $fp -Value $ln -Encoding UTF8;Write-Status "  SWITCH: FIXED - ${fp}:$($v.Line)";$n++}catch{Write-Warning "  SWITCH: ERR ${fp}:$($v.Line) - $_"}}}
return $n }

function Save-Baseline { param([array]$Results,[int]$AmpersandCount)
$bl=@{timestamp=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss');total=$Results.Count;byRule=$Results | Group-Object RuleName | ForEach-Object {@{rule=$_.Name;count=$_.Count}};byFile=$Results | Group-Object ScriptName | ForEach-Object {@{file=$_.Name;count=$_.Count}};autoFixableCount=($Results | Where-Object {$_.RuleName -in $fr}).Count;trackedCount=($Results | Where-Object {$_.RuleName -in $tr}).Count;manualCount=($Results | Where-Object {$_.RuleName -notin ($fr+$tr)}).Count;ampersandCount=$AmpersandCount}
$di=Split-Path $BaselineFile -Parent;if(-not(Test-Path $di)){New-Item -ItemType Directory -Path $di -Force | Out-Null}
$bl | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $BaselineFile -Encoding UTF8;return $bl}

$target=Resolve-Path $Path
$scanFiles=$null
if($Mode -eq 'Incremental'){
  $changed=@(git diff --cached --name-only --diff-filter=ACMR -- '*.ps1' 2>$null | Where-Object {$_ -and (Test-Path $_)})
  if($changed.Count -gt 0){$scanFiles=$changed;Write-Status "Incremental: $($changed.Count) changed file(s)"}
  else{Write-Status "Incremental: no cached .ps1 changes — falling back to full scan"}
}
if(-not$Quiet){Write-Host "== PSSA Gate - $Mode ==";Write-Host "  Target: $target"}
Write-Status "Scanning..."
$results=Get-PSSAViolation -TargetPath $target -Files $scanFiles

if($Mode -eq 'Fix'){Write-Host "`n-- Auto-fix --";$bf=Resolve-BomEncoding -Violations ($results | Where-Object {$_.RuleName -eq 'PSUseBOMForUnicodeEncodedFile'});$sf=Resolve-SwitchDefault -Violations ($results | Where-Object {$_.RuleName -eq 'PSAvoidDefaultValueSwitchParameter'});Write-Host "  BOM: $bf | Switch: $sf";Write-Status "Re-scanning...";$results=Get-PSSAViolation -TargetPath $target -Files $scanFiles}

$af=@($results | Where-Object {$_.RuleName -in $fr});$td=@($results | Where-Object {$_.RuleName -in $tr});$manual=@($results | Where-Object {$_.RuleName -notin ($fr+$tr)})
$ev=@($manual | Where-Object {$sp=$_.ScriptPath.Replace('\','/');$sk=$false;foreach($d in $xd){if($sp-match"/$d/"){$sk=$true;break}};$sk})
$manual=@($manual | Where-Object {$sp=$_.ScriptPath.Replace('\','/');$sk=$false;foreach($d in $xd){if($sp-match"/$d/"){$sk=$true;break}};-not$sk})

$kx=@('bash-safe.ps1','pssa-gate.ps1');$av=[IO.Directory]::EnumerateFiles($target, '*.ps1', [IO.SearchOption]::AllDirectories) | ForEach-Object -Parallel {$rp=$_.Replace($using:target,'').TrimStart('\');$sk=$false;foreach($ex in $using:kx){if($rp-match[regex]::Escape($ex)){$sk=$true}};foreach($d in $using:xd){if($rp-match"^$d[\\/]"){$sk=$true}};if($sk){return}
try{$ln=[IO.File]::ReadAllText($_)}catch{return};$ln=$ln -split '\r?\n'
$results=@();for($i=0;$i-lt$ln.Count;$i++){$t=$ln[$i].Trim();if($t-eq''-or$t.StartsWith('#')){continue};if($t-match'(^|[^""])&&([^""]|$)'){$results+=[PSCustomObject]@{ScriptName=$rp;Line=$i+1;Text=$t}}};$results} -ThrottleLimit 4
$av=@($av|Where-Object{$_})
$ac=$av.Count

if(-not$Quiet){Write-Host "`n-- Summary --"
$modeLabel=if($Mode -eq 'Incremental' -and $scanFiles){" (incremental: $($scanFiles.Count) files)"}else{""}
Write-Host "  Total: $($results.Count)$modeLabel | &&: $ac | Auto: $($af.Count) | Tracked: $($td.Count) | Excluded: $(@($ev).Count) | Manual: $($manual.Count)"
if($ac-gt0){Write-Host "`n-- && violations (PS5.1) --";$av | Select-Object ScriptName,Line,Text | Format-Table -AutoSize | Out-String | Write-Host}
if($manual.Count-gt0){Write-Host "`n-- Manual review (PSSA) --";$manual | Group-Object RuleName | ForEach-Object {Write-Host "  $($_.Name): $($_.Count)"};$manual | Select-Object RuleName,Line,ScriptName | Format-Table -AutoSize | Out-String | Write-Host}}

switch($Mode){
'Trend'{$bl=Save-Baseline -Results $results -AmpersandCount $ac;$prior=if(Test-Path $BaselineFile){Get-Content -LiteralPath $BaselineFile -Raw | ConvertFrom-Json}else{$null}
if($prior){$d=$results.Count-$prior.total;$s=if($d-gt0){'+'}else{''};$pa=if($prior.PSObject.Properties['ampersandCount']){($prior.ampersandCount -as[int])}else{0};$ad=$ac-$pa;$as=if($ad-gt0){'+'}else{''}
Write-Host "`n-- Trend --";Write-Host "  PSSA: $($prior.total)->$($results.Count)|D:$s$d";Write-Host "  &&: $($prior.ampersandCount)->$ac|D:$as$ad"
if($d-gt0-or$ad-gt0){Write-Warning "  Some INCREASED"}elseif($d-lt0-and$ad-le0){Write-Host "  DECREASED - good!"}else{Write-Host "  Steady."}}else{Write-Host "  No prior data."}}
{$_ -in 'Check','Incremental'}{if(-not(Test-Path $BaselineFile)){Save-Baseline -Results $results -AmpersandCount $ac | Out-Null;Write-Status "Baseline saved to $BaselineFile"}}}

$ec=0
if($manual.Count-gt0-and$Mode-ne'Trend'){Write-Warning "PSSA Gate: $($manual.Count) need manual review.";$ec=1}
if($ac-gt0-and$Mode-ne'Trend'){Write-Warning "PSSA Gate: $ac && violations. Use bash-safe.ps1.";$ec=1}
if($ec-eq0){Write-Host "`nPSSA Gate PASSED."}
exit $ec
