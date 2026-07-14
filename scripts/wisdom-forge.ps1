#requires -Version 7.6
<#
.SYNOPSIS
    Auto-forge a skill from a pattern when it reaches its promotion threshold.
.DESCRIPTION
    Reads a pattern, checks severity-based thresholds, generates SKILL.md, runs 9 quality gates, registers as lazy-load skill.
.THRESHOLDS
    CRITICAL: >=1 hit/1 project | HIGH: >=2 hits/2 projects | MEDIUM: >=3 hits/2 projects | LOW: >=5 hits/3 projects
.PARAMETER PatternId  Pattern ID (e.g. "ux/a11y/hero-btn-contrast").
.PARAMETER PatternFile  Path to pattern JSON (alternative to PatternId).
.PARAMETER Force  Skip threshold check.
.PARAMETER DryRun  Run gates but don't write.
.PARAMETER Quiet  Output JSON only.
#>
param([string]$PatternId="",[string]$PatternFile="",[switch]$Force,[switch]$DryRun,[switch]$Quiet)
Set-StrictMode -Version Latest;$ErrorActionPreference = "Stop"

$repoRoot=Split-Path -Parent $PSScriptRoot
$patternsDir=Join-Path (Join-Path (Join-Path $repoRoot "docs") "cross-project") "patterns"
$skillsDir=Join-Path (Join-Path $repoRoot ".agents") "skills"
$thresholds=@{CRITICAL=@{Hits=1;Projects=1};HIGH=@{Hits=2;Projects=2};MEDIUM=@{Hits=3;Projects=2};LOW=@{Hits=5;Projects=3}}

function Load-Pattern{param([string]$Id,[string]$File);if($Id){$found=@(Get-ChildItem $patternsDir -Filter "*.json"|Where-Object{try{(Get-Content $_.FullName -Raw|ConvertFrom-Json).id-eq $Id}catch{$false}});if($found.Length-eq 0){Write-Error "Pattern not found: $Id";exit 1};$fp=$found[0].FullName}elseif($File){if(-not(Test-Path $File)){Write-Error "File not found: $File";exit 1};$fp=$File}else{Write-Error "Provide -PatternId or -PatternFile";exit 1};try{$p=Get-Content $fp -Raw|ConvertFrom-Json}catch{Write-Error "Invalid JSON: $_";exit 1};return $p,$fp}

function Test-ForgeThreshold{param($P);if($Force){return $true,"forced"};$sev=if($P.severity-and$thresholds.ContainsKey($P.severity)){$P.severity}else{"MEDIUM"};$t=$thresholds[$sev];$hits=if($P.hits){[int]$P.hits}else{0};$proj=0;if($P.context-and$P.context.files){$proj=@($P.context.files|Select-Object -Unique).Length};if($proj-lt 1){$proj=1};if($hits-ge$t.Hits-and$proj-ge$t.Projects){return $true,"met ($sev: $($t.Hits)x$($t.Projects))"};return $false,"needs $([Math]::Max(0,$t.Hits-$hits)) hits, $([Math]::Max(0,$t.Projects-$proj)) projects"}

function New-SkillContent{param($P);$slug=($P.id -replace '[/\s]+','-').ToLower();if($slug-notlike"cross-project-*"){$slug="cross-project-$slug"};$slug=$slug-replace '-+$','';$desc=if($P.rule-and$P.rule.summary){$d=$P.rule.summary -replace '[\u201c\u201d]','"' -replace "'","'";if($d.Length-gt 115){$d.Substring(0,112)+"..."}else{$d}}else{$P.title};$tkw=@($P.title);if($P.tags){$tkw+=$P.tags};if($P.signal-and$P.signal.keywords){$tkw+=$P.signal.keywords};if($P.signal-and$P.signal.css_selectors){$tkw+=$P.signal.css_selectors};$ts=($tkw|Select-Object -Unique)-join', '
$det=if($P.rule-and$P.rule.details){$P.rule.details}else{""};$chk=if($P.rule-and$P.rule.check){$P.rule.check}else{""};$fix=if($P.rule-and$P.rule.fix){$P.rule.fix}else{""}
return "---`nname: $slug`ndescription: `"$desc`"`nlicense: Apache-2.0`nmetadata:`n  tags: [$($P.tags -join ', ')]`n  author: gentleman-vMK (auto-forged)`n  version: `"1.0`"`n  source_pattern: `"$($P.id)`"`n  source_severity: `"$($P.severity)`"`ntriggers: `"$ts`"`n---`n`n## Rule`n$det`n`n## Check`n$chk`n`n## Fix`n$fix`n`n## Source Pattern`nForged from **$($P.id)**. Updated: $($P.updated). Confidence: $($P.confidence)."}

# Quality gates
$gr=@()
function Add-Gate{param([string]$N,[scriptblock]$C);try{$ok=&$C;$gr+=[PSCustomObject]@{Gate=$N;Status=if($ok){"PASS"}else{"FAIL"}};return $ok}catch{$gr+=[PSCustomObject]@{Gate=$N;Status="FAIL";Error=$_.Exception.Message};return $false}}
function Test-YamlFrontmatter{param([string]$C);$t=$C.TrimStart();return $t.StartsWith("---")-and($C-match'(?s)---\s*\n.*?\n---')}
function Test-TriggerUnique{param([string[]]$Triggers);$all=@(Get-ChildItem $skillsDir -Filter "SKILL.md" -Recurse -EA SilentlyContinue);$txt=@();foreach($f in $all){try{$c=Get-Content $f.FullName -Raw;if($c-match'(?s)triggers:\s*"([^"]+)"'){$txt+=($Matches[1]-split',')|ForEach-Object{$_.Trim().ToLower()}}}catch{continue}};foreach($t in $Triggers){$tl=$t.Trim().ToLower();if($tl-ne""-and$txt -contains $tl){return $false}};return $true}
function Test-NoSecrets{param([string]$C);foreach($p in @('-----BEGIN (RSA|OPENSSH|PRIVATE|EC) KEY-----','(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*[''"][^''"]{8,}')){if($C-match$p){return $false}};return $true}
function Test-NoConflict{param([string]$N){return @(Get-ChildItem $skillsDir -Directory|Where-Object{$_.Name-eq $N}).Length-eq 0}}

# Main
$pattern,$fp=Load-Pattern -Id $PatternId -File $PatternFile
$sev=if($pattern.severity){$pattern.severity}else{"MEDIUM"};$id=$pattern.id;$hits=if($pattern.hits){[int]$pattern.hits}else{0}
if(-not$Quiet){Write-Host "=== Wisdom Forge | $id | $sev (hits: $hits) ===" -Fore Cyan;if($DryRun){Write-Host "[DRY-RUN]" -Fore Yellow}}

# Threshold
if(-not$Force){$ok,$reason=Test-ForgeThreshold $pattern;if(-not$ok){if(-not$Quiet){Write-Host "[X] $reason" -Fore Red};[PSCustomObject]@{Status="BLOCKED";Reason=$reason;PatternId=$id;Gates=$gr}|ConvertTo-Json -Depth 3;exit 0};if(-not$Quiet){Write-Host "[OK] $reason" -Fore Green}}

# Generate
$slug=($pattern.id -replace '[/\s]+','-').ToLower();if($slug-notlike"cross-project-*"){$slug="cross-project-$slug"};$slug=$slug-replace '-+$',''
$sd=Join-Path $skillsDir $slug;$sf=Join-Path $sd "SKILL.md"
$sc=New-SkillContent $pattern;$ss=[System.Text.Encoding]::UTF8.GetByteCount($sc)
if(-not$Quiet){Write-Host "[GEN] $slug ($ss bytes)" -Fore Cyan}

# Quality gates
$allPass=$true
$checks=@(@{N="yaml-frontmatter";C={Test-YamlFrontmatter $sc}},@{N="name-prefix";C={$slug-like"cross-project-*"}},@{N="desc-length";C={$dv=if($sc-match'(?m)^description:\s*"([^"]+)"'){$Matches[1]}else{""};$dv.Length-le-120}},@{N="triggers-nonempty";C={$triggers=if($pattern.tags){@($pattern.tags)}else{@()};$triggers.Length-gt0}},@{N="triggers-unique";C={Test-TriggerUnique $triggers}},@{N="has-rules";C={$pattern.rule-and($pattern.rule.check-or-$pattern.rule.fix-or-$pattern.rule.details)}},@{N="size-max-2kb";C={$ss-le-2048}},@{N="no-conflict";C={Test-NoConflict $slug}},@{N="no-secrets";C={Test-NoSecrets $sc}})
foreach($ck in $checks){$ok=Add-Gate $ck.N $ck.C;if(-not$ok){$allPass=$false}}
if(-not$Quiet){Write-Host "`n--- Gates ---" -Fore Yellow;foreach($g in $gr){Write-Host "  $(if($g.Status-eq"PASS"){"[OK]"}else{"[X]"}) $($g.Gate)$(if($g.Detail){" ($($g.Detail))"}else{""})"}}
if(-not$allPass){if(-not$Quiet){Write-Host "`n[X] BLOCKED" -Fore Red};[PSCustomObject]@{Status="BLOCKED";Reason="Gates failed";PatternId=$id;Gates=$gr}|ConvertTo-Json -Depth 4;exit 0}
if(-not$Quiet){Write-Host "`n[OK] All gates PASSED" -Fore Green}

# Dry-run
if($DryRun){if(-not$Quiet){Write-Host "[DRY] Would create: $sd" -Fore Yellow};[PSCustomObject]@{Status="DRY_RUN";PatternId=$id;SkillName=$slug;SkillPath=$sd;SkillSize=$ss;Gates=$gr}|ConvertTo-Json -Depth 4;exit 0}

# Write
if(-not(Test-Path $sd)){New-Item -ItemType Directory -Path $sd -Force|Out-Null}
Set-Content -Path $sf -Value $sc -Encoding UTF8
if(-not$Quiet){Write-Host "[WRITE] $sf" -Fore Green}

# Update pattern
$pattern|Add-Member -NotePropertyName "skill_ref" -NotePropertyValue $slug -Force
$pattern|Add-Member -NotePropertyName "status" -NotePropertyValue "promoted" -Force
$pattern|Add-Member -NotePropertyName "promoted_at" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -Force
$pattern|ConvertTo-Json -Depth 6|Set-Content $fp -Encoding UTF8
if(-not$Quiet){Write-Host "[UPDATE] Pattern -> promoted" -Fore Green}

# Output
$r=[PSCustomObject]@{Status="FORGED";PatternId=$id;SkillName=$slug;SkillPath=$sd;SkillFile=$sf;SkillSize=$ss;Gates=$gr;EngramPayload=[PSCustomObject]@{TopicKey="forge/$slug";Type="architecture";Title="Forged: $slug";Content="**What**: Auto-forged from ``$id`` ($sev, $hits hits)`n**Where**: $sf`n**Learned**: 9 quality gates passed"}}
if(-not$Quiet){Write-Host "`n=== FORGED: $slug ===" -Fore Green}
$r|ConvertTo-Json -Depth 5
