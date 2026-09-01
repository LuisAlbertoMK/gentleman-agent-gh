#requires -Version 7
<#
.SYNOPSIS
    MCP Security Audit — checks opencode.json MCP config against
    official Security Best Practices (modelcontextprotocol.io 2026-07-28).
.DESCRIPTION
    Vectors (from r2-mcp-security-bestpractices, 11 sections, KB):
      - Confused Deputy (proxy + static client ID) → we have NO proxy MPs
      - Tool poisoning / prompt injection via tool responses → local preferred
      - SSRF via remote MCP servers → allowlist check
      - Credential exposure via env vars → secret pattern scan
      - Supply-chain versioning → npx @version pinning
      - Path scoping (CBM_ALLOWED_ROOT) → no root

    PESTER_TEST-aware: always reports; never mutates repo.
    Exit code 0 = PASS, 1 = FAIL (CI mode).
.NOTES
    P0-2 (id:857) — fixes prior spec confusion (GitHub ecosystem:mcp has 0 GHSA
    as of 2026-09-01; authoritative source is the official spec, not landing page).
#>
[CmdletBinding()]
param([switch]$CI)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'opencode.json')) { $repoRoot = Split-Path $PSScriptRoot -Parent }
if (-not (Test-Path (Join-Path $repoRoot 'opencode.json'))) { $repoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

$json = Get-Content (Join-Path $repoRoot 'opencode.json') -Raw | ConvertFrom-Json
$mcp = $json.mcp
if (-not $mcp) { Write-Host "No opencode.json:mcp section found"; exit 1 }

# --- Helpers ---
$failed = 0; $warned = 0
function Pass([string]$m) { Write-Host "  [OK]  $m" -ForegroundColor Green }
function Warn([string]$m) { $script:warned++; Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Fail([string]$m) { $script:failed++; Write-Host "  [FAIL] $m" -ForegroundColor Red }

# --- 1. Inventory ---
Write-Host "=== MCP Inventory ===" -ForegroundColor Cyan
$names = @($mcp.PSObject.Properties.Name)
Write-Host "  servers: $($names -join ', ')"
$enabled = @($names | Where-Object { $mcp.$_.enabled -eq $true })
$remote = @($names | Where-Object { $mcp.$_.type -eq 'remote' -and $mcp.$_.enabled -eq $true })
Write-Host "  enabled: $($enabled -join ', ') ($($enabled.Count)/$($names.Count))"
Write-Host "  remote-enabled: $($remote -join ', ')"

# --- 2. Remote allowlist (SSRF) ---
Write-Host "`n[1/5] Remote allowlist (SSRF)..." -ForegroundColor Cyan
$allowedRemotes = @('https://mcp.context7.com/mcp')
foreach ($n in $remote) {
    $url = $mcp.$n.url
    if ($allowedRemotes -contains $url) { Pass "$n url allowlisted: $url" }
    elseif ($url -match '^https://mcp\.context7\.com' -or $url -match '^https://learn\.microsoft\.com') {
        Warn "$n url on trusted prefix but not exact allowlist entry: $url — add to allowlist if legit"
    } else { Fail "$n remote url NOT allowlisted: $url  — add to allowlist or disable" }
}
if ($remote.Count -eq 0) { Pass "no remote-enabled servers (SSRF surface: none)" }

# --- 3. Env / credential exposure ---
Write-Host "`n[2/5] Env credential exposure..." -ForegroundColor Cyan
$secretRx = '(?i)(api' + '[_-]?' + 'key|secret|token|password|bearer|aws_|sk-|ghp_|github_token)'
foreach ($n in $names) {
    if (-not ($mcp.$n.PSObject.Properties.Name -contains 'environment')) { continue }
    $envBlock = $mcp.$n.environment
    if (-not $envBlock) { continue }
    foreach ($p in $envBlock.PSObject.Properties) {
        $v = [string]$p.Value
        if ($v -match $secretRx -and $v -notmatch 'GENTLEMAN_AGENT_ROOT|CBM_ALLOWED_ROOT|HEADROOM_PROXY_URL') {
            Warn "$n env $($p.Name) value looks like a secret (`$v` — review; prefer .env or vault)"
        }
    }
}
# Resolve CBM_ALLOWED_ROOT scoping
$cbm = $null
if ($mcp.'codebase-memory-mcp' -and ($mcp.'codebase-memory-mcp'.PSObject.Properties.Name -contains 'environment') -and $mcp.'codebase-memory-mcp'.environment.PSObject.Properties.Name -contains 'CBM_ALLOWED_ROOT') {
    $cbm = $mcp.'codebase-memory-mcp'.environment.CBM_ALLOWED_ROOT
}
if ($cbm) {
    $resolved = $cbm -replace '\{env:GENTLEMAN_AGENT_ROOT\}', ($env:GENTLEMAN_AGENT_ROOT ?? $repoRoot)
    if ($resolved -match '^(C:\\|C:/|/)$') { Fail "CBM_ALLOWED_ROOT resolves to filesystem root: $resolved" }
    elseif ($cbm -eq '{env:GENTLEMAN_AGENT_ROOT}') { Pass "CBM_ALLOWED_ROOT scoped via GENTLEMAN_AGENT_ROOT: $cbm" }
    else { Warn "CBM_ALLOWED_ROOT raw: $cbm (resolved: $resolved) — verify least-privilege" }
}

# --- 4. Supply-chain versioning ---
Write-Host "`n[3/5] Version pinning..." -ForegroundColor Cyan
foreach ($n in $names) {
    if (-not ($mcp.$n.PSObject.Properties.Name -contains 'command')) { continue }
    $cmd = @($mcp.$n.command)
    $joined = $cmd -join ' '
    if ($joined -match 'npx\b') {
        if ($joined -match '@\d+\.\d+') { Pass "$n npx version pinned: $joined" }
        else { Fail "$n npx without @version pin: $joined — pin to prevent supply-chain drift" }
    }
}
# Local binary presence hint (informational)
if ($mcp.'codebase-memory-mcp' -and $mcp.'codebase-memory-mcp'.command -contains 'codebase-memory-mcp') {
    Pass "codebase-memory-mcp uses local binary (supply-chain: local, not npx)"
}
if ($mcp.engram -and $mcp.engram.command -contains 'engram') {
    Pass "engram uses local binary (supply-chain: local)"
}

# --- 5. Disabled hygiene ---
Write-Host "`n[4/5] Disabled hygiene..." -ForegroundColor Cyan
foreach ($n in @('headroom','chrome-devtools-mcp')) {
    if ($mcp.$n) {
        if ($mcp.$n.enabled -eq $false) { Pass "$n disabled (correct — no surface)" }
        else { Warn "$n ENABLED — verify you need it; it widens exposed tools" }
    }
}

# --- 6. Confused Deputy (proxy check) ---
Write-Host "`n[5/5] Confused Deputy / proxy..." -ForegroundColor Cyan
$hasProxy = $false
foreach ($n in $names) {
    $hasProxyProp = $false
    if ($mcp.$n.PSObject.Properties.Name -contains 'environment' -and $mcp.$n.environment) {
        $hasProxyProp = ($mcp.$n.environment.PSObject.Properties.Name -join ' ') -match 'proxy'
    }
    $isProxyName = $mcp.$n.PSObject.Properties.Name -contains 'proxy'
    if ($isProxyName -or $hasProxyProp) {
        if ($mcp.$n.enabled -eq $true) { $hasProxy = $true; Warn "$n has proxy-like env and is enabled — review Confused Deputy conditions in KB" }
    }
}
if (-not $hasProxy) { Pass "no enabled proxy-like MCP — Confused Deputy N/A" }

# --- Summary ---
Write-Host "`n=== MCP Security Audit: Summary ===" -ForegroundColor Cyan
Write-Host "  FAIL=$failed  WARN=$warned"
if ($failed -gt 0) { Write-Host "  Result: FAIL" -ForegroundColor Red; if ($CI) { exit 1 } }
elseif ($warned -gt 0) { Write-Host "  Result: PASS with warnings" -ForegroundColor Yellow }
else { Write-Host "  Result: PASS" -ForegroundColor Green }
