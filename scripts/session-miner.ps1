<# .SYNOPSIS Mine session histories for error patterns and propose corrections #>
param([ValidateSet('scan','apply','check')][string]$Mode='scan',[switch]$Json,[int]$Threshold=2)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$rr=Split-Path -Parent $PSScriptRoot
$cp=Join-Path $rr 'ANTI-PATTERN-CATALOG.md';$ld=Join-Path $rr '.learnings'
$ep=Join-Path $ld 'ERRORS.md';$lp=Join-Path $ld 'LEARNINGS.md'
$ro='Multiline'
function rc{if(-not(Test-Path $cp)){return @()}
try{$c=Get-Content $cp -Raw}catch{Write-Debug "sm: cannot read catalog ($($_.Exception.Message))";return @()}
$p=@();$rows=[regex]::Matches($c,'^\|\s*\d+\s*\|.*?\|.*?\|.*?\|.*?\|.*?\|.*?\|',$ro)
foreach($r in $rows){$parts=$r.Value -split '\|' | ForEach-Object {$_.Trim()}
if($parts.Count-ge8){$id=0;if($parts[1]){[int]::TryParse($parts[1],[ref]$id) | Out-Null}
$p+=[PSCustomObject]@{Id=$id;Date=$parts[2];Pattern=$parts[3];Symptom=$parts[4];RootCause=$parts[5];Fix=$parts[6];Prevention=$parts[7]}}}
return $p}
function rl{if(-not(Test-Path $lp)){return @()}
try{$c=Get-Content $lp -Raw}catch{Write-Debug "sm: cannot read learnings ($($_.Exception.Message))";return @()}
$k=@();$m=[regex]::Matches($c,'Pattern-Key:\s*([^\n\r]+)',$ro)
foreach($x in $m){$k+=$x.Groups[1].Value.Trim()};return $k}
function re{if(-not(Test-Path $ep)){return @()}
try{$c=Get-Content $ep -Raw}catch{Write-Debug "sm: cannot read errors ($($_.Exception.Message))";return @()}
$e=@();$entries=[regex]::Matches($c,'##\s+\[\w+-\d+-\d+\]\s+(.+?)$',$ro)
foreach($entry in $entries){$e+=$entry.Groups[1].Value.Trim()};return $e}
function frp{param([array]$cp,[array]$pk,[int]$mn)
$kc=@{};foreach($k in $pk){if($kc.ContainsKey($k)){$kc[$k]++}else{$kc[$k]=1}}
$r=@();foreach($e in $kc.GetEnumerator()){if($e.Value-ge$mn){$cat=$false
foreach($c in $cp){if($c.Pattern -cmatch [regex]::Escape($e.Name)){$cat=$true;break}}
$r+=[PSCustomObject]@{PatternKey=$e.Name;Count=$e.Value;Cataloged=$cat}}};return $r}
$catalog=rc;$patternKeys=rl;$errors=re;$repeated=frp -cp $catalog -pk $patternKeys -mn $Threshold
if($Mode-eq'check'){$data=[PSCustomObject]@{CatalogEntries=@($catalog).Count;PatternKeys=@($patternKeys).Count;ErrorEntries=@($errors).Count;RepeatedPatterns=@($repeated).Count;Mode='check';Status=if(@($repeated).Count-gt0){'PATTERNS_FOUND'}else{'CLEAN'}}
if($Json){return($data | ConvertTo-Json -Comp)}
Write-Host "  Catalog: $(@($catalog).Count) entries`n  Patterns: $(@($patternKeys).Count) keys`n  Errors: $(@($errors).Count) entries`n  Repeated: $(@($repeated).Count) patterns`n  Status: $($data.Status)";return}
if($Mode-eq'scan'){$uncataloged=@($repeated | Where-Object {-not $_.Cataloged})
$data=[PSCustomObject]@{CatalogCount=@($catalog).Count;PatternKeyCount=@($patternKeys).Count;ErrorCount=@($errors).Count;RepeatedPatterns=$repeated;UnCatalogedCount=$uncataloged.Count;CanApply=$uncataloged.Count-gt0}
if($Json){return($data | ConvertTo-Json -Depth 3 -Comp)}
Write-Host "Catalog: $($catalog.Count) anti-patterns cataloged`nPattern keys: $($patternKeys.Count) from learnings`nErrors: $($errors.Count) entries"
if($repeated.Count-eq0){Write-Host "[OK] No repeated patterns found (threshold: $Threshold)";return}
Write-Host '[WARN] Repeated patterns detected:';foreach($r in $repeated){$s=if($r.Cataloged){'[cataloged]'}else{'[uncataloged]'};Write-Host "  [$($r.Count)x] $($r.PatternKey) -- $s"}
if($uncataloged.Count-gt0){Write-Host "Proposal: run with -Mode apply to add $($uncataloged.Count) new anti-pattern(s)"};return}
if($Mode-eq'apply'){$uncataloged=@($repeated | Where-Object {-not $_.Cataloged})
if($uncataloged.Count-eq0){Write-Host '[OK] Nothing to apply';return}
Write-Host "Would add $($uncataloged.Count) new anti-pattern(s):";foreach($u in $uncataloged){$sk=$u.PatternKey -replace '[^\w-]','_';Write-Host "  - [$($u.Count)x] $($u.PatternKey) -> ANTI-PATTERN-CATALOG.md + docs/anti-patterns/$sk.md"}
Write-Host 'Run manually: edit ANTI-PATTERN-CATALOG.md with pattern details'}