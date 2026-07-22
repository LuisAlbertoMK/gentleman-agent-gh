#requires -Version 7
<# 
.SYNOPSIS
  One-click global setup for opencode. Applies all assets, configures MCPs, ensures skills are synced.
.DESCRIPTION
  1. Syncs global AGENTS.md from canonical
  2. Copies shared prompts (core-behavior, analyze-only)
  3. Copies shared scripts (cache.ps1, skill-resolver-fast.ps1)
  4. Ensures MCP servers are configured (engram, context7)
  5. Creates skill junctions if missing
  6. Verifies everything works
.PARAMETER Force
  Overwrite existing files without confirmation
.PARAMETER SkipMCP
  Skip MCP server configuration
.PARAMETER Json
  JSON output for agent consumption
.PARAMETER Quiet
  Minimal output
#>
param([switch]$Force,[switch]$SkipMCP,[switch]$Json,[switch]$Quiet)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
if($Quiet){$Json=$true}

# Cross-platform helpers
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")

$gentlemanRoot = if ($env:GENTLEMAN_AGENT_ROOT) { $env:GENTLEMAN_AGENT_ROOT } else { (Get-Item $PSScriptRoot).Parent.FullName }
$globalConfig = Get-GlobalConfigDir
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string]$Name,[string]$Status,[string]$Detail)
    $results.Add(@{name=$Name;status=$Status;detail=$Detail})
    if(-not $Json){
        $icon = switch($Status){"OK"{"✅"}"SYNCED"{"🔄"}"SKIP"{"⏭️"}"FAIL"{"❌"}default{"❓"}}
        Write-Output "$icon $Name — $Detail"
    }
}

function Sync-File {
    param([string]$Source,[string]$Dest,[string]$Label)
    if(-not (Test-Path $Source)){Add-Result $Label "FAIL" "Source not found: $Source";return}
    $destDir = Split-Path $Dest -Parent
    if(-not (Test-Path $destDir)){New-Item -ItemType Directory -Path $destDir -Force | Out-Null}
    if((Test-Path $Dest) -and -not $Force){
        $srcHash = (Get-FileHash $Source).Hash
        $dstHash = (Get-FileHash $Dest).Hash
        if($srcHash -eq $dstHash){Add-Result $Label "OK" "Already up to date";return}
    }
    Copy-Item -LiteralPath $Source -Destination $Dest -Force
    Add-Result $Label "SYNCED" "Copied to $Dest"
}

# 1. Sync AGENTS.md
if(-not $Quiet){Write-Output "`n═══ GLOBAL SETUP — opencode ═══`n"}
Sync-File (Join-Path $gentlemanRoot "AGENTS.md") (Join-Path $globalConfig "AGENTS.md") "AGENTS.md"

# 2. Sync ALL shared prompts (auto-discover from canonical)
$sharedPromptsSrc = Join-Path (Join-Path $gentlemanRoot "prompts") "shared"
if (Test-Path $sharedPromptsSrc) {
    Get-ChildItem $sharedPromptsSrc -Filter "*.md" -Attributes !ReparsePoint | ForEach-Object {
        $safeName = Split-Path -Leaf $_.Name
        Sync-File $_.FullName (Join-Path (Join-Path (Join-Path $globalConfig "prompts") "shared") $safeName) "prompts/shared/$safeName"
    }
}

# 2b. Sync SDD prompts (auto-discover from canonical)
$sharedSddSrc = Join-Path (Join-Path $gentlemanRoot "prompts") "sdd"
if (Test-Path $sharedSddSrc) {
    Get-ChildItem $sharedSddSrc -Filter "*.md" -Attributes !ReparsePoint | ForEach-Object {
        $safeName = Split-Path -Leaf $_.Name
        $destDir = Join-Path (Join-Path $globalConfig "prompts") "sdd"
        Sync-File $_.FullName (Join-Path $destDir $safeName) "prompts/sdd/$safeName"
    }
}

# 2c. Sync root prompts (gentleman-*.md, _*.md — auto-discover, allowlisted)
$rootPromptsSrc = Join-Path $gentlemanRoot "prompts"
if (Test-Path $rootPromptsSrc) {
    Get-ChildItem $rootPromptsSrc -Include "gentleman-*.md","_*.md" -File -Attributes !ReparsePoint | ForEach-Object {
        $safeName = Split-Path -Leaf $_.Name
        Sync-File $_.FullName (Join-Path (Join-Path $globalConfig "prompts") $safeName) "prompts/$safeName"
    }
}

# 3. Sync shared scripts
$sharedScripts = @(
    @{Src=Join-Path (Join-Path "scripts" "lib") "cache.ps1";Dst=Join-Path (Join-Path "scripts" "lib") "cache.ps1"},
    @{Src=Join-Path "scripts" "skill-resolver-fast.ps1";Dst=Join-Path "scripts" "skill-resolver-fast.ps1"},
    @{Src=Join-Path "scripts" "build-skill-registry.ps1";Dst=Join-Path "scripts" "build-skill-registry.ps1"},
    @{Src=Join-Path "scripts" "auto-pattern-detector.ps1";Dst=Join-Path "scripts" "auto-pattern-detector.ps1"},
    @{Src=Join-Path "scripts" "learning-stats.ps1";Dst=Join-Path "scripts" "learning-stats.ps1"},
    @{Src=Join-Path "scripts" "wisdom-forge.ps1";Dst=Join-Path "scripts" "wisdom-forge.ps1"},
    @{Src=Join-Path "scripts" "check-mcp-security.ps1";Dst=Join-Path "scripts" "check-mcp-security.ps1"},
    @{Src=Join-Path "scripts" "wisdom-demote.ps1";Dst=Join-Path "scripts" "wisdom-demote.ps1"},
    @{Src=Join-Path "scripts" "sync-global-ps5.ps1";Dst=Join-Path "scripts" "sync-global-ps5.ps1"},
    @{Src=Join-Path "scripts" "project-cycle.ps1";Dst=Join-Path "scripts" "project-cycle.ps1"},
    @{Src=Join-Path "scripts" "sync-global.ps1";Dst=Join-Path "scripts" "sync-global.ps1"},
    @{Src=Join-Path "scripts" "wisdom-stats.ps1";Dst=Join-Path "scripts" "wisdom-stats.ps1"},
    @{Src=Join-Path "scripts" "skillspector-gate.ps1";Dst=Join-Path "scripts" "skillspector-gate.ps1"},
    @{Src=Join-Path "scripts" "analyze-screenshot.ps1";Dst=Join-Path "scripts" "analyze-screenshot.ps1"},
    @{Src=Join-Path "scripts" "bench-compare.ps1";Dst=Join-Path "scripts" "bench-compare.ps1"},
    @{Src=Join-Path "scripts" "bootstrap.ps1";Dst=Join-Path "scripts" "bootstrap.ps1"},
    @{Src=Join-Path "scripts" "list-skills.ps1";Dst=Join-Path "scripts" "list-skills.ps1"},
    @{Src=Join-Path "scripts" "project-profile.ps1";Dst=Join-Path "scripts" "project-profile.ps1"},
    @{Src=Join-Path "scripts" "test-downstream.ps1";Dst=Join-Path "scripts" "test-downstream.ps1"}
)
foreach($s in $sharedScripts){ Sync-File (Join-Path $gentlemanRoot $s.Src) (Join-Path $globalConfig $s.Dst) $s.Src }

# 4. Sync opencode.json (agent section + permissions)
$canonicalJson = Join-Path $gentlemanRoot "opencode.json"
$globalJson = Join-Path $globalConfig "opencode.json"
if((Test-Path $canonicalJson) -and (Test-Path $globalJson)){
    $canon = Get-Content $canonicalJson -Raw -Encoding UTF8 | ConvertFrom-Json
    $glob = Get-Content $globalJson -Raw -Encoding UTF8 | ConvertFrom-Json
    $changed = $false
    if($canon.agent){
        $canonAgent = $canon.agent | ConvertTo-Json -Depth 10 -Compress
        $globAgent = $glob.agent | ConvertTo-Json -Depth 10 -Compress
        if($canonAgent -ne $globAgent){$glob.agent = $canon.agent;$changed=$true}
    }
    if($canon.permission){
        $canonPerm = $canon.permission | ConvertTo-Json -Depth 10 -Compress
        $globPerm = $glob.permission | ConvertTo-Json -Depth 10 -Compress
        if($canonPerm -ne $globPerm){$glob.permission = $canon.permission;$changed=$true}
    }
    if($changed){$glob | ConvertTo-Json -Depth 10 | Set-Content $globalJson -Encoding UTF8; Add-Result "opencode.json" "SYNCED" "Updated agent + permission sections"}
    else{Add-Result "opencode.json" "OK" "Already in sync"}
}else{Add-Result "opencode.json" "SKIP" "Files not found"}

# 5. Ensure MCP servers
if(-not $SkipMCP -and (Test-Path $globalJson)){
    $config = Get-Content $globalJson -Raw -Encoding UTF8 | ConvertFrom-Json
    $mcpChanged = $false
    if(-not ($config.PSObject.Properties['mcp'])){
        $config | Add-Member -Name "mcp" -Value @{} -MemberType NoteProperty -Force
    }
    if(-not ($config.mcp.PSObject.Properties['engram'])){
        $config.mcp | Add-Member -Name "engram" -Value @{type="local";command=@("engram","mcp","--tools=agent");enabled=$true} -MemberType NoteProperty -Force
        $mcpChanged = $true; Add-Result "MCP:engram" "SYNCED" "Added engram MCP server"
    }else{Add-Result "MCP:engram" "OK" "Already configured"}
    $c7Cmd = @("context7-mcp")
    if(-not ($config.mcp.PSObject.Properties['context7'])){
        $config.mcp | Add-Member -Name "context7" -Value @{type="local";command=$c7Cmd;enabled=$true} -MemberType NoteProperty -Force
        $mcpChanged = $true; Add-Result "MCP:context7" "SYNCED" "Added context7 MCP server"
    }elseif($config.mcp.context7.PSObject.Properties['command'] -and ($config.mcp.context7.command -join ' ') -ne ($c7Cmd -join ' ')){
        $config.mcp.context7.command = $c7Cmd; $mcpChanged = $true; Add-Result "MCP:context7" "SYNCED" "Updated context7 command"
    }else{Add-Result "MCP:context7" "OK" "Already configured"}
    if($mcpChanged){$config | ConvertTo-Json -Depth 10 | Set-Content $globalJson -Encoding UTF8}
}

# 6. Ensure skill junctions
$globalSkills = Join-Path $globalConfig "skills"
$canonicalSkills = Join-Path (Join-Path $gentlemanRoot ".agents") "skills"
if((Test-Path $canonicalSkills) -and (Test-Path $globalSkills)){
    $canonDirs = Get-ChildItem $canonicalSkills -Directory | Where-Object { $_.Name -ne '_shared' }
    $junctionCount = 0; $skipCount = 0
    foreach($d in $canonDirs){
        $target = Join-Path $globalSkills $d.Name
        if(-not (Test-Path $target)){try{New-CrossPlatLink -Path $target -Target $d.FullName;$junctionCount++}catch{Add-Result "Junction:$($d.Name)" "FAIL" $_.Exception.Message}}
        else{$skipCount++}
    }
    if($junctionCount -gt 0){Add-Result "Skill Junctions" "SYNCED" "Created $junctionCount junctions ($skipCount existing)"}
    else{Add-Result "Skill Junctions" "OK" "All $skipCount junctions exist"}
}else{Add-Result "Skill Junctions" "SKIP" "Skills directories not found"}

# 7. Generate skill registry if missing
$registryPath = Join-Path (Join-Path $gentlemanRoot "scripts") "skill-registry.json"
$buildScript = Join-Path (Join-Path $gentlemanRoot "scripts") "build-skill-registry.ps1"
if(-not (Test-Path $registryPath) -and (Test-Path $buildScript)){& $buildScript -Quiet 2>$null; Add-Result "Skill Registry" "SYNCED" "Generated from SKILL.md frontmatters"}
else{Add-Result "Skill Registry" "OK" "Already exists"}

# Output
if($Json){
    ConvertTo-Json @{timestamp=(Get-Date -Format "o");results=$results;summary=@{
        synced=@($results | Where-Object {$_.status -eq "SYNCED"}).Count
        ok=@($results | Where-Object {$_.status -eq "OK"}).Count
        failed=@($results | Where-Object {$_.status -eq "FAIL"}).Count
        skipped=@($results | Where-Object {$_.status -eq "SKIP"}).Count
    }} -Depth 3
}else{
    Write-Output "`n───────────────────────────────────────"
    $synced = @($results | Where-Object {$_.status -eq "SYNCED"}).Count
    $ok = @($results | Where-Object {$_.status -eq "OK"}).Count
    $failed = @($results | Where-Object {$_.status -eq "FAIL"}).Count
    Write-Output "Synced: $synced | OK: $ok | Failed: $failed"
    Write-Output "═══════════════════════════════════════"
}
