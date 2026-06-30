#requires -Version 7.6
<#
.SYNOPSIS
  MCP Security Audit — verify servers in opencode.json against security policies.
.DESCRIPTION
  Reads opencode.json, inspects every configured MCP server, and reports:
  - Source trustworthiness (vendor/MCP Steering Group vs unknown)
  - Transport security (STDIO preferred, remote must be HTTPS)
  - Archived/server status (no unmaintained servers)
  - Token exposure (no hardcoded secrets)
  - Tool budget (total tools < 50 threshold)
  - Supply chain risk (npx -y usage)
.PARAMETER Json
  Output results as JSON (instead of formatted text).
.PARAMETER Quiet
  Suppress informational output, show only errors/warnings.
.PARAMETER ConfigPath
  Path to opencode.json (default: repo root).
.EXAMPLE
  .\scripts\check-mcp-security.ps1
  .\scripts\check-mcp-security.ps1 -Json
  .\scripts\check-mcp-security.ps1 -Quiet
#>
param(
  [switch]$Json,
  [switch]$Quiet,
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\opencode.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve paths ──────────────────────────────────────────────────────
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$configPath = Resolve-Path (Join-Path $repoRoot "opencode.json")
$securityDoc = Join-Path $repoRoot "docs\operations\mcp-security-checkpoint.md"

# ── Known-trusted sources ──────────────────────────────────────────────
# servers-archived list: these are no longer maintained
$archivedServers = @(
  'server-postgres', 'server-puppeteer', 'server-slack', 'server-sentry',
  'server-sqlite', 'server-brave-search', 'server-github',
  'server-google-drive', 'server-google-maps', 'server-redis',
  'server-filesystem', 'server-git'  # NOTE: these were replaced, not fully archived
)

$trustedVendors = @(
  '@modelcontextprotocol',   # MCP Steering Group
  '@upstash',                # Context7
  '@playwright',             # Microsoft Playwright
  'github/github-mcp-server',# GitHub official
  'brave/',                  # Brave Search official
  'mcp/',                    # Docker MCP Toolkit
  'zencoderai/',             # Slack MCP (Zencoder)
  '@anthropic',              # Anthropic
  'engram',                  # Engram memory system (local SDK)
  'sentry',                  # Sentry official
  'docker'                   # Docker
)

# Known tool counts (from real READMEs, verified)
$knownToolCounts = @{
  'context7'              = 2
  'engram'                = 18
  'memory'                = 9
  'sequential-thinking'   = 3
  'fetch'                 = 1
  'playwright'            = 22
  'github-mcp-server'     = 56
  'filesystem'            = 12
  'git'                   = 12
}

# ── Helpers ────────────────────────────────────────────────────────────
function Write-Status { param([string]$M) if (-not $Quiet -and -not $Json) { Write-Host "  $M" } }

function Test-ArchivedServer {
  param([string]$Name, [string[]]$Command)
  # Check if server name or command matches an archived server
  foreach ($a in $archivedServers) {
    if ($Name -like "*$a*" -or ($Command -join ' ') -like "*$a*") { return $true }
  }
  return $false
}

function Test-TrustedSource {
  param([string[]]$Command)
  $cmdStr = ($Command -join ' ').ToLowerInvariant()
  foreach ($t in $trustedVendors) {
    if ($cmdStr -like "*$($t.ToLowerInvariant())*") { return $true }
  }
  # Also check if it references a known registry
  if ($cmdStr -like "*registry.modelcontextprotocol.io*") { return $true }
  return $false
}

function Test-HardcodedToken {
  param([string[]]$Command)
  # Look for anything that looks like a secret inline in the command
  $suspicious = @(
    '--api-key\s+\S+', '--token\s+\S+', '--secret\s+\S+',
    '--password\s+\S+', '--key\s+\S+', 'GH_TOKEN\s*=\s*\S+',
    'GITHUB_TOKEN\s*=\s*\S+', 'API_KEY\s*=\s*\S+',
    'ctx7sk_', 'ghp_', 'gho_', 'github_pat_'
  )
  $cmdStr = ($Command -join ' ')
  foreach ($p in $suspicious) {
    # Only flag if value is a literal, not an env var reference
    if ($cmdStr -match $p) {
      $match = $matches[0]
      # If it ends with an env var reference, it's fine
      if ($match -notmatch '\{env:') { return $true }
    }
  }
  return $false
}

function Get-ServerIdentifier {
  param([string]$Name, [string[]]$Command)
  # Derive a normalized server identity from the command
  $cmdStr = ($Command -join ' ')
  # Extract package name
  if ($cmdStr -match '@[\w-]+(?:/[\w-]+)?') { return $matches[0] }
  return $Name
}

function Get-EstimatedToolCount {
  param([string]$Name)
  foreach ($k in $knownToolCounts.Keys) {
    if ($Name -like "*$k*") { return $knownToolCounts[$k] }
  }
  return $null  # unknown
}

# ── Main ───────────────────────────────────────────────────────────────
if (-not (Test-Path $configPath)) {
  Write-Error "Config not found: $configPath"
  exit 1
}

$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$mcpServers = $config.mcp
if (-not $mcpServers) {
  Write-Error "No 'mcp' section found in $configPath"
  exit 1
}

$serverNames = $mcpServers | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

$results = @()
$totalTools = 0
$passCount = 0
$warnCount = 0
$failCount = 0

Write-Status "MCP Security Audit"
Write-Status "Config: $configPath"
Write-Status "Servers found: $($serverNames.Count)"
Write-Status ""

foreach ($srvName in $serverNames) {
  $srv = $mcpServers.$srvName
  $type = $srv.type
  $command = $srv.command
  $hasUrl = $srv.PSObject.Properties.Match('url').Count -gt 0
  $url = if ($hasUrl) { $srv.url } else { $null }
  $hasEnabled = $srv.PSObject.Properties.Match('enabled').Count -gt 0
  $enabled = if ($hasEnabled -and $srv.enabled -eq $false) { $false } else { $true }
  $hasEnv = $srv.PSObject.Properties.Match('environment').Count -gt 0
  $environment = if ($hasEnv) { $srv.environment } else { $null }
  $hasHeaders = $srv.PSObject.Properties.Match('headers').Count -gt 0
  $headers = if ($hasHeaders) { $srv.headers } else { $null }
  $cmdStr = if ($command) { ($command -join ' ') } else { '' }

  $check = [PSCustomObject]@{
    Server        = $srvName
    Enabled       = $enabled
    Type          = if ($type) { $type } else { 'unknown' }
    Transport     = if ($type -eq 'local') { 'STDIO' } elseif ($url) { 'HTTP' } else { 'unknown' }
    Tools         = if ($enabled) { Get-EstimatedToolCount -Name $srvName } else { 0 }
    Source        = if ($command) { Get-ServerIdentifier -Name $srvName -Command $command } else { $url }
    Issues        = @()
    Warnings      = @()
    Status        = 'PASS'
  }

  if ($enabled) {
    if ($check.Tools) { $totalTools += $check.Tools }
    else { $check.Warnings += "Unknown tool count (not in known list)" }
  }

  # ── Rule 1: Source trustworthiness ───────────────────────────────────
  if ($command) {
    if (-not (Test-TrustedSource -Command $command)) {
      $check.Issues += "Untrusted source: '$($check.Source)' — not in trusted vendors list"
      $check.Status = 'FAIL'
    }
  } elseif ($url) {
    # Remote servers: check domain
    if ($url -notlike "https://*") {
      $check.Issues += "Non-HTTPS remote URL: $url"
      $check.Status = 'FAIL'
    }
    # Known trusted remote domains
    $trustedDomains = @('mcp.context7.com', 'registry.modelcontextprotocol.io')
    $domain = ([System.Uri]$url).Host
    if ($domain -notin $trustedDomains) {
      $check.Warnings += "Remote domain not in trusted list: $domain"
      if ($check.Status -eq 'PASS') { $check.Status = 'WARN' }
    }
  }

  # ── Rule 2: Archived server check ────────────────────────────────────
  if ($command -and (Test-ArchivedServer -Name $srvName -Command $command)) {
    $check.Issues += "Archived/unmaintained server — use official vendor replacement"
    $check.Status = 'FAIL'
  }

  # ── Rule 3: Token exposure ───────────────────────────────────────────
  if ($command -and (Test-HardcodedToken -Command $command)) {
    $check.Issues += "Hardcoded credential in command — use {env:VAR} or environment block"
    $check.Status = 'FAIL'
  }

  # ── Rule 4: Environment block check ──────────────────────────────────
  if ($command -and $cmdStr -match '\{env:') {
    # Command references env vars — good, but check if environment block exists
    $envRefs = [regex]::Matches($cmdStr, '\{env:([^}]+)\}') | ForEach-Object { $_.Groups[1].Value }
    if ($envRefs.Count -gt 0 -and (-not $environment -or @($environment.PSObject.Properties).Count -eq 0)) {
      $check.Warnings += "Command uses {env:...} refs ($($envRefs -join ', ')) but no 'environment' block defined — vars come from host shell"
    }
  }

  # ── Rule 5: Supply chain risk warning ────────────────────────────────
  if ($command -and $cmdStr -match 'npx\s+-y') {
    $check.Warnings += "npx -y: executes unverified npm code on every start — pin version or use lockfile"
  }
  if ($command -and $cmdStr -match 'npx') {
    $check.Warnings += "npx dependency: supply chain risk — verify source integrity"
  }

  # ── Accumulate status ────────────────────────────────────────────────
  switch ($check.Status) {
    'FAIL' { $failCount++ }
    'WARN' { $warnCount++ }
    'PASS' { $passCount++ }
  }

  $results += $check
}

# ── Global tool budget check ──────────────────────────────────────────
$toolBudgetIssue = $null
if ($totalTools -gt 50) {
  $toolBudgetIssue = "TOOL BUDGET EXCEEDED: ~$totalTools tools active (limit: 50) — reduce enabled servers or disable unused ones"
  $failCount++
} elseif ($totalTools -gt 40) {
  $toolBudgetIssue = "TOOL BUDGET WARNING: ~$totalTools tools active — approaching 50 limit"
  $warnCount++
}

# ── Output ────────────────────────────────────────────────────────────
if ($Json) {
  $output = [PSCustomObject]@{
    timestamp     = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    configPath    = $configPath
    serverCount   = $serverNames.Count
    passCount     = $passCount
    warnCount     = $warnCount
    failCount     = $failCount
    totalTools    = $totalTools
    toolBudget    = if ($toolBudgetIssue) { $toolBudgetIssue } else { 'OK' }
    servers       = $results | Select-Object Server, Enabled, Type, Transport, Tools, Source, Status,
                      @{N='Issues';E={if ($_.Issues.Count -gt 0) { $_.Issues -join '; ' } else { $null }}},
                      @{N='Warnings';E={if ($_.Warnings.Count -gt 0) { $_.Warnings -join '; ' } else { $null }}}
  }
  $output | ConvertTo-Json -Depth 5
} else {
  Write-Host "========================================"
  Write-Host " MCP Security Audit"
  Write-Host " $((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
  Write-Host " Config: $($configPath | Split-Path -Leaf)"
  Write-Host "========================================"
  Write-Host ""

  if ($toolBudgetIssue) {
    $color = if ($totalTools -gt 50) { 'Red' } else { 'Yellow' }
    Write-Host "  [WARN] $toolBudgetIssue" -ForegroundColor $color
    Write-Host ""
  }

  foreach ($r in $results) {
    $color = switch ($r.Status) { 'PASS' { 'Green' } 'WARN' { 'Yellow' } 'FAIL' { 'Red' } }
    $icon = switch ($r.Status) { 'PASS' { '[PASS]' } 'WARN' { '[WARN]' } 'FAIL' { '[FAIL]' } }
    $state = if ($r.Enabled) { 'ON' } else { 'OFF' }

    Write-Host " $icon [$state] $($r.Server) ($($r.Type), $($r.Transport))" -ForegroundColor $color
    if ($r.Tools) { Write-Host "      Tools: ~$($r.Tools)" }
    Write-Host "      Source: $($r.Source)"
    Write-Host "      Status: $($r.Status)"

    if ($r.Issues.Count -gt 0) {
      Write-Host "      Issues:" -ForegroundColor Red
      foreach ($issue in $r.Issues) { Write-Host "        • $issue" -ForegroundColor Red }
    }
    if ($r.Warnings.Count -gt 0) {
      Write-Host "      Warnings:" -ForegroundColor Yellow
      foreach ($warn in $r.Warnings) { Write-Host "        • $warn" -ForegroundColor Yellow }
    }
    Write-Host ""
  }

  Write-Host "----------------------------------------"
  Write-Host " Summary: $passCount PASS | $warnCount WARN | $failCount FAIL"
  Write-Host " Total tools: ~$totalTools / 50 limit"
  Write-Host "----------------------------------------"

  # Exit code for automation
  if ($failCount -gt 0) { exit 1 }
}
