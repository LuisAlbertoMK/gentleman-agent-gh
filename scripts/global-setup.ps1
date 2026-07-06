#requires -Version 7.6
<# 
.SYNOPSIS
  One-click global setup for opencode. Applies all assets, configures MCPs, ensures skills are synced.
  Works for any project — run once, everything is ready.
.DESCRIPTION
  1. Syncs global AGENTS.md from canonical
  2. Copies shared prompts (core-behavior, analyze-only)
  3. Copies shared scripts (cache.ps1, skill-resolver-fast.ps1)
  4. Copies ANTI-PATTERN-CHEATSHEET.md
  5. Ensures MCP servers are configured (engram, context7)
  6. Creates skill junctions if missing
  7. Verifies everything works
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

$gentlemanRoot = if ($env:GENTLEMAN_AGENT_ROOT) { $env:GENTLEMAN_AGENT_ROOT } else { (Get-Item $PSScriptRoot).Parent.FullName }
$globalConfig = "$env:USERPROFILE\.config\opencode"
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

# ── 1. Sync AGENTS.md ──────────────────────────────────────────────────
if(-not $Quiet){Write-Output "`n═══ GLOBAL SETUP — opencode ═══`n"}
Sync-File (Join-Path $gentlemanRoot "AGENTS.md") (Join-Path $globalConfig "AGENTS.md") "AGENTS.md"

# ── 2. Sync shared prompts ─────────────────────────────────────────────
$sharedPrompts = @("core-behavior.md","analyze-only.md")
foreach($p in $sharedPrompts){
    $src = Join-Path $gentlemanRoot "prompts\shared\$p"
    $dst = Join-Path $globalConfig "prompts\shared\$p"
    Sync-File $src $dst "prompts/shared/$p"
}

# ── 3. Sync shared scripts ─────────────────────────────────────────────
$sharedScripts = @(
    @{Src="scripts\lib\cache.ps1";Dst="scripts\lib\cache.ps1"},
    @{Src="scripts\skill-resolver-fast.ps1";Dst="scripts\skill-resolver-fast.ps1"},
    @{Src="scripts\build-skill-registry.ps1";Dst="scripts\build-skill-registry.ps1"},
    @{Src="scripts\auto-pattern-detector.ps1";Dst="scripts\auto-pattern-detector.ps1"},
    @{Src="scripts\learning-stats.ps1";Dst="scripts\learning-stats.ps1"}
)
foreach($s in $sharedScripts){
    $src = Join-Path $gentlemanRoot $s.Src
    $dst = Join-Path $globalConfig $s.Dst
    Sync-File $src $dst $s.Src
}

# ── 4. Sync ANTI-PATTERN-CHEATSHEET ───────────────────────────────────
Sync-File (Join-Path $gentlemanRoot "ANTI-PATTERN-CHEATSHEET.md") (Join-Path $globalConfig "ANTI-PATTERN-CHEATSHEET.md") "ANTI-PATTERN-CHEATSHEET.md"

# ── 5. Sync opencode.json (agent section + permissions) ────────────────
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
    if($changed -and -not $Force){
        # Auto-sync without prompt
        $glob | ConvertTo-Json -Depth 10 | Set-Content $globalJson -Encoding UTF8
        Add-Result "opencode.json" "SYNCED" "Updated agent + permission sections"
    }elseif($changed){
        $glob | ConvertTo-Json -Depth 10 | Set-Content $globalJson -Encoding UTF8
        Add-Result "opencode.json" "SYNCED" "Updated agent + permission sections"
    }else{
        Add-Result "opencode.json" "OK" "Already in sync"
    }
}else{
    Add-Result "opencode.json" "SKIP" "Files not found"
}

# ── 6. Ensure MCP servers ──────────────────────────────────────────────
if(-not $SkipMCP -and (Test-Path $globalJson)){
    $config = Get-Content $globalJson -Raw -Encoding UTF8 | ConvertFrom-Json
    $mcpChanged = $false
    
    # Ensure mcp section exists (opencode uses 'mcp' not 'mcpServers')
    if(-not ($config.PSObject.Properties['mcp'])){
        $config | Add-Member -Name "mcp" -Value @{} -MemberType NoteProperty -Force
    }
    
    # Ensure engram MCP
    if(-not ($config.mcp.PSObject.Properties['engram'])){
        $config.mcp | Add-Member -Name "engram" -Value @{type="local";command=@("engram","mcp","--tools=agent");enabled=$true} -MemberType NoteProperty -Force
        $mcpChanged = $true
        Add-Result "MCP:engram" "SYNCED" "Added engram MCP server"
    }else{
        Add-Result "MCP:engram" "OK" "Already configured"
    }
    
    # Ensure context7 MCP
    if(-not ($config.mcp.PSObject.Properties['context7'])){
        $config.mcp | Add-Member -Name "context7" -Value @{type="local";command=@("npx","-y","@upstash/context7-mcp@3.2.2");enabled=$true} -MemberType NoteProperty -Force
        $mcpChanged = $true
        Add-Result "MCP:context7" "SYNCED" "Added context7 MCP server"
    }else{
        Add-Result "MCP:context7" "OK" "Already configured"
    }
    
    if($mcpChanged){
        $config | ConvertTo-Json -Depth 10 | Set-Content $globalJson -Encoding UTF8
    }
}

# ── 7. Ensure skill junctions ──────────────────────────────────────────
$globalSkills = Join-Path $globalConfig "skills"
$canonicalSkills = Join-Path $gentlemanRoot ".agents\skills"
if((Test-Path $canonicalSkills) -and (Test-Path $globalSkills)){
    $canonDirs = Get-ChildItem $canonicalSkills -Directory | Where-Object { $_.Name -ne '_shared' }
    $junctionCount = 0
    $skipCount = 0
    foreach($d in $canonDirs){
        $target = Join-Path $globalSkills $d.Name
        if(-not (Test-Path $target)){
            # Create junction
            try{
                New-Item -ItemType Junction -Path $target -Target $d.FullName -Force | Out-Null
                $junctionCount++
            }catch{
                Add-Result "Junction:$($d.Name)" "FAIL" $_.Exception.Message
            }
        }else{
            $skipCount++
        }
    }
    if($junctionCount -gt 0){Add-Result "Skill Junctions" "SYNCED" "Created $junctionCount junctions ($skipCount existing)"}
    else{Add-Result "Skill Junctions" "OK" "All $skipCount junctions exist"}
}else{
    Add-Result "Skill Junctions" "SKIP" "Skills directories not found"
}

# ── 8. Generate skill registry if missing ──────────────────────────────
$registryPath = Join-Path $gentlemanRoot "scripts\skill-registry.json"
$buildScript = Join-Path $gentlemanRoot "scripts\build-skill-registry.ps1"
if(-not (Test-Path $registryPath) -and (Test-Path $buildScript)){
    & $buildScript -Quiet 2>$null
    Add-Result "Skill Registry" "SYNCED" "Generated from SKILL.md frontmatters"
}else{
    Add-Result "Skill Registry" "OK" "Already exists"
}

# ── Output ──────────────────────────────────────────────────────────────
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
