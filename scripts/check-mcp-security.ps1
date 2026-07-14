#requires -Version 7.6
<#
.SYNOPSIS
  MCP Security Audit — verify servers in opencode.json against security policies.
.DESCRIPTION
  Reads opencode.json, inspects every configured MCP server, and reports:
  source trust, transport security, token exposure, tool budget, supply chain risk.
.PARAMETER Json  Output results as JSON.
.PARAMETER Quiet  Suppress informational output, show only errors/warnings.
#>
param([switch]$Json,[switch]$Quiet,[string]$ConfigPath=(Join-Path $PSScriptRoot "..\opencode.json"))
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'

$repoRoot=Resolve-Path (Join-Path $PSScriptRoot "..")
$configPath=Resolve-Path (Join-Path $repoRoot "opencode.json")
$archivedServers=@('server-postgres','server-puppeteer','server-slack','server-sentry','server-sqlite','server-brave-search','server-github','server-google-drive','server-google-maps','server-redis','server-filesystem','server-git')
$trustedVendors=@('@modelcontextprotocol','@upstash','@playwright','github/github-mcp-server','brave/','mcp/','zencoderai/','@anthropic','engram','sentry','docker')
$knownToolCounts=@{context7=2;engram=18;memory=9;sequential-thinking=3;fetch=1;playwright=22;'github-mcp-server'=56;filesystem=12;git=12}

function Write-Status{param([string]$M)if(-not$Quiet -and -not$Json){Write-Host "  $M"}}
function Test-ArchivedServer{param([string]$Name,[string[]]$Command);foreach($a in $archivedServers){if($Name-like"*$a*"-or($Command-join' ')-like"*$a*"){return $true}};return $false}
function Test-TrustedSource{param([string[]]$Command);$cmd=($Command-join' ').ToLowerInvariant();foreach($t in $trustedVendors){if($cmd-like"*$($t.ToLowerInvariant())*"){return $true}};if($cmd-like"*registry.modelcontextprotocol.io*"){return $true};return $false}
function Test-HardcodedToken{param([string[]]$Command);$pats=@('--api-key\s+\S+','--token\s+\S+','--secret\s+\S+','--password\s+\S+','--key\s+\S+','GH_TOKEN\s*=\s*\S+','GITHUB_TOKEN\s*=\s*\S+','API_KEY\s*=\s*\S+','ctx7sk_','ghp_','gho_','github_pat_');$cmd=($Command-join' ');foreach($p in $pats){if($cmd-match$p){$m=$matches[0];if($m-notmatch'\{env:'){return $true}}};return $false}
function Get-ServerIdentifier{param([string]$Name,[string[]]$Command);$cmd=($Command-join' ');if($cmd-match'@[\w-]+(?:/[\w-]+)?'){$matches[0]}else{$Name}}
function Get-EstimatedToolCount{param([string]$Name);foreach($k in $knownToolCounts.Keys){if($Name-like"*$k*"){return $knownToolCounts[$k]}};return $null}

if(-not(Test-Path $configPath)){Write-Error "Config not found: $configPath";exit 1}
$config=Get-Content $configPath -Raw -Encoding UTF8|ConvertFrom-Json
$mcpServers=$config.mcp;if(-not$mcpServers){Write-Error "No 'mcp' section found in $configPath";exit 1}
$serverNames=$mcpServers|Get-Member -MemberType NoteProperty|Select-Object -ExpandProperty Name
$results=@();$totalTools=0;$passCount=0;$warnCount=0;$failCount=0
Write-Status "MCP Security Audit | Config: $configPath | Servers: $($serverNames.Count)"

foreach($srvName in $serverNames){
  $srv=$mcpServers.$srvName;$type=$srv.type;$command=$srv.command
  $hasUrl=$srv.PSObject.Properties.Match('url').Count-gt0;$url=if($hasUrl){$srv.url}else{$null}
  $hasEnabled=$srv.PSObject.Properties.Match('enabled').Count-gt0;$enabled=if($hasEnabled-and$srv.enabled-eq$false){$false}else{$true}
  $hasEnv=$srv.PSObject.Properties.Match('environment').Count-gt0;$environment=if($hasEnv){$srv.environment}else{$null}
  $cmdStr=if($command){($command-join' ')}else{''}

  $check=[PSCustomObject]@{Server=$srvName;Enabled=$enabled;Type=if($type){$type}else{'unknown'};Transport=if($type-eq'local'){'STDIO'}elseif($url){'HTTP'}else{'unknown'};Tools=if($enabled){Get-EstimatedToolCount -Name $srvName}else{0};Source=if($command){Get-ServerIdentifier -Name $srvName -Command $command}else{$url};Issues=@();Warnings=@();Status='PASS'}

  if($enabled){if($check.Tools){$totalTools+=$check.Tools}else{$check.Warnings+="Unknown tool count"}}

  # Rule 1: Source trust
  if($command){if(-not(Test-TrustedSource -Command $command)){$check.Issues+="Untrusted source: '$($check.Source)'";$check.Status='FAIL'}}
  elseif($url){if($url-notlike"https://*"){$check.Issues+="Non-HTTPS remote URL: $url";$check.Status='FAIL'};$trustedDomains=@('mcp.context7.com','registry.modelcontextprotocol.io');$domain=([System.Uri]$url).Host;if($domain-notin$trustedDomains){$check.Warnings+="Remote domain not in trusted list: $domain";if($check.Status-eq'PASS'){$check.Status='WARN'}}}

  # Rule 2: Archived server
  if($command-and(Test-ArchivedServer -Name $srvName -Command $command)){$check.Issues+="Archived/unmaintained server";$check.Status='FAIL'}

  # Rule 3: Token exposure
  if($command-and(Test-HardcodedToken -Command $command)){$check.Issues+="Hardcoded credential in command";$check.Status='FAIL'}

  # Rule 4: Env block check
  if($command-and$cmdStr-match'\{env:'){;$envRefs=[regex]::Matches($cmdStr,'\{env:([^}]+)\}')|ForEach-Object{$_.Groups[1].Value};if($envRefs.Count-gt0-and(-not$environment-or@($environment.PSObject.Properties).Count-eq0)){$check.Warnings+="Command uses {env:...} but no 'environment' block defined"}}

  # Rule 5: Supply chain
  if($command-and$cmdStr-match'npx\s+-y'){$check.Warnings+="npx -y: executes unverified npm code on every start"}
  if($command-and$cmdStr-match'npx'){$check.Warnings+="npx dependency: supply chain risk"}

  switch($check.Status){'FAIL'{ $failCount++ }'WARN'{ $warnCount++ }'PASS'{ $passCount++ }}
  $results+=$check
}

# Tool budget
$toolBudgetIssue=$null
if($totalTools-gt50){$toolBudgetIssue="TOOL BUDGET EXCEEDED: ~$totalTools tools (limit: 50)";$failCount++}
elseif($totalTools-gt40){$toolBudgetIssue="TOOL BUDGET WARNING: ~$totalTools tools approaching 50 limit";$warnCount++}

# Output
if($Json){
  [PSCustomObject]@{timestamp=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss');configPath=$configPath;serverCount=$serverNames.Count;passCount=$passCount;warnCount=$warnCount;failCount=$failCount;totalTools=$totalTools;toolBudget=if($toolBudgetIssue){$toolBudgetIssue}else{'OK'};servers=$results|Select-Object Server,Enabled,Type,Transport,Tools,Source,Status,@{N='Issues';E={if($_.Issues.Count-gt0){$_.Issues-join'; '}else{$null}}},@{N='Warnings';E={if($_.Warnings.Count-gt0){$_.Warnings-join'; '}else{$null}}}}|ConvertTo-Json -Depth 5
}else{
  Write-Host "=== MCP Security Audit === $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Cyan
  if($toolBudgetIssue){$c=if($totalTools-gt50){'Red'}else{'Yellow'};Write-Host "  [WARN] $toolBudgetIssue" -ForegroundColor $c}
  foreach($r in $results){$c=switch($r.Status){'PASS'{'Green'}'WARN'{'Yellow'}'FAIL'{'Red'}};$i=switch($r.Status){'PASS'{'[PASS]'}'WARN'{'[WARN]'}'FAIL'{'[FAIL]'}};$st=if($r.Enabled){'ON'}else{'OFF'};Write-Host " $i [$st] $($r.Server) ($($r.Type), $($r.Transport))" -ForegroundColor $c;if($r.Tools){Write-Host "      Tools: ~$($r.Tools)"};Write-Host "      Source: $($r.Source)";if($r.Issues.Count-gt0){foreach($is in $r.Issues){Write-Host "      [X] $is" -ForegroundColor Red}};if($r.Warnings.Count-gt0){foreach($w in $r.Warnings){Write-Host "      [!] $w" -ForegroundColor Yellow}}}
  Write-Host "--- Summary: $passCount PASS | $warnCount WARN | $failCount FAIL | Tools: ~$totalTools/50 ---"
  if($failCount-gt0){exit 1}
}
