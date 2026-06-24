#requires -Version 5.1
<#
.SYNOPSIS
  Check skill drift between canonical (.agents/skills/) and global config (~/.config/opencode/skills/). Optionally sync agent definitions.
#>
param([switch]$Thorough,[switch]$AutoFix,[switch]$SyncAgents,[switch]$Json)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$cd=Join-Path $PSScriptRoot "..\.agents\skills"
$gd="$env:USERPROFILE\.config\opencode\skills"
$e=@();$w=@();$d=@()
if(-not (Test-Path $cd)){Write-Error "Canonical dir not found: $cd";exit 2}
if(-not (Test-Path $gd)){Write-Error "Global dir not found: $gd";exit 2}
$cs=@(gci $cd -Directory|?{$_.Name-ne'_shared'})
foreach($s in $cs){
  $sn=$s.Name
  $cp=Join-Path $s.FullName "SKILL.md"
  if(-not (Test-Path $cp)){$e+=[PSCustomObject]@{Skill=$sn;Status="CANON_MISSING";Detail="No SKILL.md"};continue}
  $gi=gi (Join-Path $gd $sn) -EA SilentlyContinue
  if(-not $gi){$e+=[PSCustomObject]@{Skill=$sn;Status="GLOBAL_MISSING";Detail="No global dir"};continue}
  if($gi.LinkType-ne"Junction"){$w+=[PSCustomObject]@{Skill=$sn;Status="GLOBAL_NOT_JUNCTION";Detail="Real file, not junction"}}
  if($gi.LinkType-ne"Junction"){
    if($Thorough){$m=(Get-FileHash $cp).Hash-eq(Get-FileHash (Join-Path $gd "$sn\SKILL.md")).Hash}
    else{$cl=(gc $cp|measure -l).Lines;$gl=(gc (Join-Path $gd "$sn\SKILL.md")|measure -l).Lines;$m=$cl-eq$gl}
    if(-not$m){$d+=[PSCustomObject]@{Skill=$sn;Status="DRIFT";Detail=if($Thorough){"Hash mismatch"}else{"Lines: canon=$cl glob=$gl"}}}
  }
}
if($AutoFix){
  $fix=@($e)|?{$_-and$_.Status-eq"GLOBAL_MISSING"}
  if(@($fix).Count-gt0){
    Write-Output "Creating $($fix.Count) junctions..."
    foreach($x in $fix){
      $t=Join-Path $cd $x.Skill;$l=Join-Path $gd $x.Skill
      try{ni -ItemType Junction -Path $l -Target $t -Force|Out-Null;Write-Output "  $l -> $t"}catch{Write-Warning "FAIL $l ($($_.Exception.Message))"}
    }
    $e=@($e)|?{$_-and$_.Status-ne"GLOBAL_MISSING"}
  }
  $gsd="$env:USERPROFILE\.config\opencode\scripts"
  $rsd=Join-Path $PSScriptRoot "."
  if(-not (Test-Path $gsd)){Write-Output "Creating scripts junction...";try{ni -ItemType Junction -Path $gsd -Target $rsd -Force|Out-Null;Write-Output "  $gsd -> $rsd"}catch{Write-Warning "FAIL $gsd ($($_.Exception.Message))"}}
}
$r=@{
  timestamp=(Get-Date -Format "o")
  totalSkills=$cs.Count
  junctionSkills=($cs|%{$g=gi (Join-Path $gd $_.Name)-EA SilentlyContinue;if($g-and$g.LinkType-eq"Junction"){$_}else{$null}}|measure).Count
  realFileSkills=($cs|%{$g=gi (Join-Path $gd $_.Name)-EA SilentlyContinue;if($g-and$g.LinkType-ne"Junction"){$_}else{$null}}|measure).Count
  warnings=$w;drifted=$d;errors=$e
  allSynced=($d.Count-eq0-and$e.Count-eq0-and$w.Count-eq0)
}
if($Json){Write-Output ($r|ConvertTo-Json -Depth 3)}else{
  $wc=@($r.warnings);$dc=@($d);$ec=@($e)
  if($wc.Count-gt0){Write-Output "WARNINGS: $($wc.Count)";$r.warnings|Format-Table Skill,Status,Detail -AutoSize -EA SilentlyContinue}
  if($r.allSynced){Write-Output "OK ALL $($r.totalSkills) skills in sync! ($($r.junctionSkills) junctions, $($r.realFileSkills) real files)"}else{
    if($dc.Count-gt0){Write-Output "DRIFT: $($dc.Count)";$d|Format-Table Skill,Status,Detail -AutoSize -EA SilentlyContinue}
    if($ec.Count-gt0){Write-Output "ERRORS: $($ec.Count)";$e|Format-Table Skill,Status,Detail -AutoSize -EA SilentlyContinue}
    exit 1
  }
}
function Sync-AgentDefinition{
<#
.SYNOPSIS
  Sync gentleman-* agent definitions + AGENTS.md from project to global config.
  Project opencode.json is canonical source; global config gets a copy for cross-project availability.
#>
  $pcp=Join-Path $PSScriptRoot "..\opencode.json";$gcp="$env:USERPROFILE\.config\opencode\opencode.json"
  $an=@("gentleman-vMK","gentleman-deep","gentleman-codex","gentleman-quick")
  $sr=@{synced=@();skipped=@()}
  Write-Output "--- Syncing agents (project -> global) ---"
  if(-not (Test-Path $pcp)){Write-Warning "No project opencode.json at $pcp";return $sr}
  if(-not (Test-Path $gcp)){Write-Warning "No global opencode.json at $gcp";return $sr}
  $pj=(gc $pcp -Raw)|ConvertFrom-Json;$gj=(gc $gcp -Raw)|ConvertFrom-Json
  # Ensure agent section exists in global
  $gha=$gj.PSObject.Properties.Match('agent').Count -gt 0
  if(-not $gha){$gj|Add-Member -Name agent -Value @{} -MemberType NoteProperty -Force}
  # Sync each gentleman agent
  foreach($n in $an){
    $sp=$pj.agent.PSObject.Properties[$n]
    if($null-eq$sp){Write-Output "  [skipped] $n (not in project)";$sr.skipped+=$n;continue}
    $gj.agent|Add-Member -Name $n -Value $sp.Value -MemberType NoteProperty -Force
    Write-Output "  [synced] $n";$sr.synced+=$n
  }
  # Sync AGENTS.md for {file:AGENTS.md} reference
  $sa=Join-Path (Split-Path $pcp -Parent) "AGENTS.md"
  $da=Join-Path (Split-Path $gcp -Parent) "AGENTS.md"
  if(Test-Path $sa -PathType Leaf){Copy-Item -LiteralPath $sa -Destination $da -Force;Write-Output "  [synced] AGENTS.md"}
  else{Write-Warning "  AGENTS.md not found at $sa"}
  # Write updated config
  $gj|ConvertTo-Json -Depth 10|Set-Content $gcp -Encoding UTF8 -Force
  Write-Output "  -> Updated $gcp ($($sr.synced.Count) agents, AGENTS.md)"
  return $sr
}
if($SyncAgents){Sync-AgentDefinition}
