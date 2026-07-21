#requires -Version 7
<#.SYNOPSIS Benchmark system — score skill fitness, system health, track trends.#>param([switch]$Snapshot,[switch]$Gate,[switch]$Json)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot "lib" "platform.ps1")
$r=Convert-Path "$PSScriptRoot\.."
$cd="$r\.agents\skills";$am="$r\AGENTS.md";$sd="$r\scripts";$sn="$r\docs\metricas\snapshots"
$sk=@(Get-ChildItem $cd -Directory).PSWhere({$_.Name -ne '_shared'}).PSForEach({$m="$($_.FullName)\SKILL.md";if(!(test-path $m)){return};$c=Get-Content $m -Raw;@{Name=$_.Name;Bytes=$c.Length;Lines=($c-split"`n").Count;F=$c-match"^---";W=$c-match"(?m)^## When to Use";R=$c-match"(?m)^## (Rules|Critical Rules)"}})
$ac=if(test-path $am){Get-Content $am -Raw}else{""}
$sc=Get-ChildItem $sd -Filter *.ps1 -EA 0
$gd=Join-Path (Get-GlobalConfigDir) "skills";$jo=0
foreach($i in $sk){$it=Get-Item "$gd\$($i.Name)"-EA 0;if($it -and $it.LinkType -in @("Junction", "SymbolicLink")){$jo++}}
$ab=($sk.PSForEach({$_.Bytes}) | Measure-Object -Sum).Sum;$al=($sk.PSForEach({$_.Lines}) | Measure-Object -Sum).Sum
$o3=$sk.PSWhere({$_.Bytes -gt 3072}).Count;$sb=@($sk.PSForEach({$_.Bytes}) | Sort-Object);$ct=$sb.Count
$md=if($ct-gt0){if($ct%2-eq1){$sb[($ct-1)/2]}else{[math]::Round(($sb[$ct/2-1]+$sb[$ct/2])/2)}}else{0}
$sys=@{AgentsMdBytes=[int]($ac.Length);AgentsMdLines=($ac-split"`n").Count;TotalSkills=$sk.Count;TotalSkillBytes=[int]$ab;TotalSkillLines=[int]$al;SkillsOver3kb=$o3;AvgSkillBytes=if($ct-gt0){[math]::Round($ab/$ct)}else{0};MedianSkillBytes=$md;MinSkillBytes=if($ct-gt0){$sb[0]}else{0};MaxSkillBytes=if($ct-gt0){$sb[-1]}else{0};ScriptsCount=$sc.Count;GlobalJunctionsOk=$jo;FrontmatterPct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.F}).Count)/$ct*100,1)}else{0};WhenToUsePct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.W}).Count)/$ct*100,1)}else{0};RulesPct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.R}).Count)/$ct*100,1)}else{0}}
$cmit=try{(git rev-parse --short HEAD 2>$null).Trim()}catch{"unknown"}
$ts=(Get-Date -Format "o");$snap=@{version="1.0";timestamp=$ts;commit="$cmit";system=$sys}
function dump($x){Write-Output ("  AGENTS.md: {0}B ({1} lines)"-f $x.AgentsMdBytes,$x.AgentsMdLines) ("  Skills: {0} | Total: {1}B ({2} lines)"-f $x.TotalSkills,$x.TotalSkillBytes,$x.TotalSkillLines) ("  >3KB: {0} | Junctions: {1}/{2}"-f $x.SkillsOver3kb,$x.GlobalJunctionsOk,$x.TotalSkills) ("  Avg: {0}B | Median: {1}B | Range: {2}-{3}B"-f $x.AvgSkillBytes,$x.MedianSkillBytes,$x.MinSkillBytes,$x.MaxSkillBytes) ("  Frontmatter: {0}% | WhenToUse: {1}% | Rules: {2}%"-f $x.FrontmatterPct,$x.WhenToUsePct,$x.RulesPct) ("  Scripts: {0}"-f $x.ScriptsCount)}
if(!(test-path $cd)){Write-Error "Canonical skills dir not found: $cd";exit 2}
if($Snapshot){
  try{
    if(!(test-path $sn)){New-Item $sn -ItemType Directory -Force | Out-Null}
    $fn="{0:yyyyMMdd-HHmmss}_benchmark.json"-f(Get-Date);$js=$snap|ConvertTo-Json -Depth 3
    Set-Content "$sn\$fn" $js -Encoding UTF8;Set-Content "$sn\LATEST_benchmark.json" $js -Encoding UTF8
    if(!$Json){Write-Output "Snapshot saved: $sn\$fn"}
  }catch{Write-Warning "benchmark: snapshot save failed ($($_.Exception.Message))"}
}
if($Gate){
  $reg=@();$lp="$sn\LATEST_benchmark.json"
  if(test-path $lp){
    try{
      $pr=Get-Content $lp -Raw | ConvertFrom-Json;$pz=$pr.system
      if($sys.AgentsMdBytes-gt$pz.AgentsMdBytes*1.1){$reg+="AGENTS.md grew >10% ($($pz.AgentsMdBytes)->$($sys.AgentsMdBytes))"}
      if($sys.TotalSkillBytes-gt$pz.TotalSkillBytes*1.05){$reg+="Total skill bytes grew >5% ($($pz.TotalSkillBytes)->$($sys.TotalSkillBytes))"}
      if($sys.SkillsOver3kb-gt$pz.SkillsOver3kb){$reg+="Skills >3KB increased ($($pz.SkillsOver3kb)->$($sys.SkillsOver3kb))"}
      if($sys.GlobalJunctionsOk-lt$pz.GlobalJunctionsOk){$reg+="Global junctions decreased ($($pz.GlobalJunctionsOk)->$($sys.GlobalJunctionsOk))"}
    }catch{Write-Debug "bench: snapshot compare failed ($($_.Exception.Message))"}
  }
  if($reg.Count-gt0){Write-Output "BENCHMARK REGRESSIONS:";$reg | ForEach-Object {Write-Output "  - $_"}}else{dump $sys}
  if(!$Json){Write-Output "   Skills: $($sys.TotalSkills) | Total: $($sys.TotalSkillBytes)B | >3KB: $($sys.SkillsOver3kb) | Junctions: $($sys.GlobalJunctionsOk)/$($sys.TotalSkills)"}
}
if(!$Snapshot -and !$Gate -or $Json){
  if($Json){Write-Output (@{timestamp=$ts;commit="$cmit";system=$sys} | ConvertTo-Json -Depth 3)}else{Write-Output "  Commit: $cmit";dump $sys}
}
