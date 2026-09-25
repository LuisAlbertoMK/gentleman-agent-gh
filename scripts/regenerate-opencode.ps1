#requires -Version 7
# NOTE (Refactor-AP S2b single-mode): RETIRED for -auto/-semi purposes — single-mode SSoT has 0 -auto agents; wrapper logic untouched.
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Regenerate opencode.json from the SSoT (scripts/lib/*) via the node generator, then verify the result.

.DESCRIPTION
  Wraps `node scripts/lib/generate-opencode-config.js` so the orchestrator can regenerate
  opencode.json without invoking node directly (node * is in the orchestrator deny list).
  Two modes:
    - Validate (default): runs `--validate` against the existing opencode.json.
      Exit 0 = in sync. Exit 1 = mismatch (opencode.json is stale vs SSoT).
    - -Yes: writes opencode.json, then runs structural verification:
      1. The 4 subagent twins exist (mode: subagent, hidden: true)
      2. Orchestrator task whitelist is fail-closed ("*": "deny") and allows the 4 twins
      3. Strict permission parity with gentle-ai: no agent carries a
         bash/read/write/edit delta — every agent inherits the global overlay
      4. JSON is parseable and opencode.json is valid against the node generator --validate
  SAFE BY DEFAULT: without -Yes this script never writes anything.

  PIPELINE (two steps — do NOT collapse into one):
    1. The node generator emits the MINIFIED SSoT contract
       (scripts/lib/generate-opencode-config.js) — it owns NO profile keys.
    2. scripts/hardware-profile.ps1 -Tier <low|medium|high> re-parses that
       output, injects exactly the tier keys (watcher, compaction, mcp,
       agent.default, model, small_model, memory_monitoring) and rewrites
       opencode.json PRETTY via ConvertTo-Json -Depth 10.
  Consequence: -Yes output ALWAYS drops profile-injected keys. When the repo
  carries the .opencode-hw-tier sidecar marker (hardware-managed file), this
  script prints a WARNING (never fails for this) — re-apply the tier BEFORE
  committing, or the commit silently disables it. Without the marker the repo
  is SSoT-only, regen is lossless, and no warning is emitted. The node
  --validate compare is semantic for exactly this reason (pretty +
  profile-injected runtime file vs minified contract).

.PARAMETER Yes
  Write opencode.json (regenerate). Without it, only validates.

.PARAMETER RepoRoot
  Repository root. Default: git root detected from the current directory.

.PARAMETER Quiet
  JSON-only summary on stdout.

.PARAMETER MaxBytes
  Size budget for opencode.json (default: 65536). Fails the post-write verification
  if the regenerated file exceeds it — guards against unbounded config growth.

.EXAMPLE
  & scripts/regenerate-opencode.ps1            # validate: is opencode.json in sync?
  & scripts/regenerate-opencode.ps1 -Yes       # regenerate + verify
  & scripts/regenerate-opencode.ps1 -Yes -Quiet  # machine-readable summary
#>
param(
  [switch]$Yes,
  [string]$RepoRoot = (Get-Location).Path,
  [switch]$Quiet,
  [int]$MaxBytes = 98304
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Locate repo root (walk up to .git) ---
$root = (Resolve-Path -LiteralPath $RepoRoot).Path
while ($root -and -not (Test-Path (Join-Path $root '.git'))) {
  $root = Split-Path $root -Parent
}
if (-not $root) { throw "No git root found under: $RepoRoot" }

$generator = Join-Path $root 'scripts\lib\generate-opencode-config.js'
$output = Join-Path $root 'opencode.json'
if (-not (Test-Path -LiteralPath $generator)) { throw "Generator not found: $generator" }

# --- Locate node (wrapper is the ONLY sanctioned path for the orchestrator) ---
$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $node) { throw 'node not found on PATH — cannot regenerate opencode.json' }

$result = [ordered]@{ status = 'fail'; mode = 'validate'; checks = @(); warnings = @() }

function Add-Check {
  param([string]$Name, [bool]$Pass, [string]$Detail)
  $script:result.checks += [ordered]@{ name = $Name; pass = $Pass; detail = $Detail }
}

# Strict-safe property access (Fix A): member access on a PSCustomObject
# property that does not exist THROWS under Set-StrictMode -Version Latest
# (PropertyNotFoundStrict) instead of returning $null — this crashed the -Yes
# verification right after the generator's [5/5] written OK (auto-sub agents
# carry no bash.* key; see Get-EffectiveBashStar). Indexer access via
# PSObject.Properties NEVER throws — it returns $null when missing.
function Get-Prop {
  param($Obj, [string]$Prop)
  if ($null -eq $Obj) { return $null }
  $p = $Obj.PSObject.Properties[$Prop]
  if ($null -eq $p) { return $null }
  return $p.Value
}

# Effective bash.* (Fix A): opencode merges the SSoT root `permission` default
# with each agent delta at runtime, and the generator delta-strips every agent
# key byte-identical to the root default (e.g. bash.*=allow lives on the root,
# so auto-sub deltas omit it). A missing agent key therefore means "inherits
# root", not "denied" — resolve agent delta first, root default second, $null
# only when neither defines it (a REAL missing → explicit FAIL downstream).
function Get-EffectiveBashStar {
  param($AgentNode, $RootCfg)
  $star = Get-Prop (Get-Prop (Get-Prop $AgentNode 'permission') 'bash') '*'
  if ($null -ne $star) { return $star }
  return (Get-Prop (Get-Prop (Get-Prop $RootCfg 'permission') 'bash') '*')
}

# --- Mode 1: validate against existing opencode.json ---
& $node $generator --validate 2>&1 | ForEach-Object { $_ }
$validateExit = $LASTEXITCODE

if ($validateExit -ne 0) {
  Add-Check 'pre-write-validate' $false 'MISMATCH — opencode.json was stale vs SSoT (expected pre-write). Run with -Yes to regenerate.'
} else {
  Add-Check 'pre-write-validate' $true 'in sync with SSoT'
}

if (-not $Yes) {
  $result.status = if ($validateExit -eq 0) { 'ok' } else { 'stale' }
  if ($Quiet) { $result | ConvertTo-Json -Depth 5 | Write-Output } else {
    Write-Output "[regenerate-opencode] validate-only: $(if ($validateExit -eq 0) { 'OK — in sync' } else { 'STALE — run -Yes to regenerate' })"
  }
  exit $validateExit
}

# In write mode the pre-write mismatch is EXPECTED (that's why we regenerate) —
# reclassify it as informational so it never flips the final status.
$preWrite = @($result.checks | Where-Object { $_.name -eq 'pre-write-validate' })[0]
if ($preWrite) { $preWrite.pass = $true; $preWrite.detail = 'pre-write state: stale (regenerated below)' }

# --- Fix C: snapshot pre-existing profile-injected keys BEFORE the write ---
# The generator emits the minified SSoT contract (no tier keys); the tier is
# re-applied afterwards by scripts/hardware-profile.ps1, which injects
# exactly: watcher, compaction, mcp, agent.default (depth), model,
# small_model, memory_monitoring. The authoritative discriminator is the
# sidecar marker .opencode-hw-tier: hardware-profile overwrites opencode.json
# ONLY when the marker exists, so marker-absent means SSoT-only (regen is
# lossless there — no warning). Marker-present means hardware-managed: regen
# strips that state → warn LOUDLY so the -Yes output is never committed with
# the tier silently disabled. Watchlist keys are DIAGNOSTIC DETAIL only.
# The tier name comes from the marker content (never guessed).
# Warning only — never fails.
$profileKeys = @()
$profileTier = $null
$tierManaged = $false
try {
  if (Test-Path -LiteralPath $output) {
    $preCfg = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    foreach ($k in @('watcher', 'compaction', 'mcp', 'model', 'small_model', 'memory_monitoring')) {
      if ($null -ne (Get-Prop $preCfg $k)) { $profileKeys += $k }
    }
    if ($null -ne (Get-Prop (Get-Prop $preCfg 'agent') 'default')) { $profileKeys += 'agent.default' }
  }
  $tierMarker = Join-Path $root '.opencode-hw-tier'
  if (Test-Path -LiteralPath $tierMarker) {
    $tierManaged = $true
    $markerRaw = Get-Content -LiteralPath $tierMarker -Raw
    if ($null -ne $markerRaw) {
      $markerTier = $markerRaw.Trim()
      if (-not [string]::IsNullOrWhiteSpace($markerTier)) { $profileTier = $markerTier }
    }
  }
} catch {
  $profileKeys = @(); $profileTier = $null; $tierManaged = $false
  Write-Warning 'pre-write profile-key check skipped (existing opencode.json unparseable)'
}

# --- Mode 2: write ---
& $node $generator 2>&1 | ForEach-Object { $_ }
if ($LASTEXITCODE -ne 0) { throw 'Generator write failed — opencode.json left untouched (write is atomic-ish, verify before retry)' }
$result.mode = 'write'

# --- Verify written opencode.json ---
try {
  $cfg = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
  Add-Check 'json-parse' $true 'opencode.json parses as JSON'
} catch {
  Add-Check 'json-parse' $false $_.Exception.Message
  $result.status = 'fail'
  if ($Quiet) { $result | ConvertTo-Json -Depth 5 | Write-Output }
  exit 1
}

$sizeBytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $output)).Length
if ($sizeBytes -gt $MaxBytes) {
  Add-Check 'config-size-budget' $false "$sizeBytes B > budget $MaxBytes B (grew unbounded — review agent/permission additions)"
} else {
  Add-Check 'config-size-budget' $true "$sizeBytes B within budget $MaxBytes B"
}

$agentTable = Get-Prop $cfg 'agent'
$twins = @('gentleman-deep-sub', 'gentleman-quick-sub', 'gentleman-implementer-sub', 'gentleman-security-sub', 'gentleman-seo-sub', 'gentleman-infra-sub', 'gentleman-frontend-sub', 'gentleman-performance-sub', 'gentleman-datascience-sub', 'gentleman-docs-sub', 'gentleman-aem-sub')
# Single-mode (Refactor-AP S5): the -auto twin family was deleted in S1 — no
# $autoTwins list; absence is asserted by zero-auto-agents below.
foreach ($t in $twins) {
  $a = Get-Prop $agentTable $t
  if (-not $a) { Add-Check "twin-$t" $false 'missing from opencode.json' }
  else {
    $tMode = Get-Prop $a 'mode'; $tHidden = Get-Prop $a 'hidden'
    if ($null -eq $tMode -or $null -eq $tHidden) { Add-Check "twin-$t" $false 'mode/hidden missing (expected subagent/true)' }
    elseif ($tMode -ne 'subagent' -or $tHidden -ne $true) { Add-Check "twin-$t" $false "mode=$tMode hidden=$tHidden (expected subagent/true)" }
    else { Add-Check "twin-$t" $true 'mode:subagent hidden:true' }
  }
}
# Single-mode (Refactor-AP S5): 44 agents, 0 -auto. The retired auto-twin
# checks (which verified against the auto-sub template deleted in S1) are
# replaced by absence assertions — resurrecting any -auto agent trips these.
$agentNames = @($agentTable.PSObject.Properties.Name)
if ($agentNames.Count -ne 44) { Add-Check 'agent-count-44' $false "found $($agentNames.Count) agents (expected 44 single-mode)" }
else { Add-Check 'agent-count-44' $true '44 agents (single-mode)' }
$staleAuto = @($agentNames | Where-Object { $_ -match '-auto$' })
if ($staleAuto.Count -gt 0) { Add-Check 'zero-auto-agents' $false "retired -auto agents present: $($staleAuto -join ', ') (expected 0)" }
else { Add-Check 'zero-auto-agents' $true '0 -auto agents (single-mode)' }

$orchAgent = Get-Prop $agentTable 'gentle-MK'
if (-not $orchAgent) { $orchAgent = Get-Prop $agentTable 'gentleman-vMK' }
$orch = Get-Prop $orchAgent 'permission'
$orchTask = Get-Prop $orch 'task'
if (-not $orchTask) {
  Add-Check 'orch-task-failclosed' $false 'task block missing (expected fail-closed deny + twin allows)'
} else {
  $orchStar = Get-Prop $orchTask '*'
  if ($orchStar -ne 'deny') {
    if ($null -eq $orchStar) { Add-Check 'orch-task-failclosed' $false 'task.* missing (expected deny — fail-closed)' }
    else { Add-Check 'orch-task-failclosed' $false "task.* = $orchStar (expected deny)" }
  } else {
    $missing = @($twins | Where-Object { (Get-Prop $orchTask $_) -ne 'allow' })
    if ($missing.Count -gt 0) { Add-Check 'orch-task-failclosed' $false "twins not allowed: $($missing -join ', ')" }
    else { Add-Check 'orch-task-failclosed' $true "fail-closed with all $($twins.Count) base twins allowed" }
  }
}

# Single-mode (Refactor-AP S5): the -auto orchestrator twin was deleted in S1 —
# assert absence (fail-closed: resurrecting it must trip this check).
$staleOrchAuto = @($agentNames | Where-Object { $_ -eq 'gentle-MK-auto' -or $_ -eq 'gentleman-vMK-auto' })
if ($staleOrchAuto.Count -gt 0) { Add-Check 'no-orch-auto-agent' $false "retired auto orchestrator present: $($staleOrchAuto -join ', ')" }
else { Add-Check 'no-orch-auto-agent' $true 'no gentle-MK-auto / gentleman-vMK-auto (single-mode)' }

# R11 STRICT PARITY with gentle-ai (docs/mejoras/2026-09-25-permission-parity-gentle-ai.md):
# the global overlay owns bash+read only (no write/edit; gentle-ai has no
# read-only agents). The former 'readonly-bash-deny' assertion is RETIRED —
# read-only specialization now lives in each agent's prompt, not the permission
# gate. Replacement: assert STRICT parity — every agent resolves its effective
# bash.* to the global default AND carries no per-agent bash/read/write/edit
# delta (catches a re-introduced write/edit or read override inexactly matching
# the global root).
$rootBashStar = (Get-Prop (Get-Prop (Get-Prop $cfg 'permission') 'bash') '*')
$parityFail = @()
foreach ($n in $agentNames) {
  $ap = Get-Prop (Get-Prop $agentTable $n) 'permission'
  if ($null -eq $ap) { continue }
  foreach ($k in @('bash', 'read', 'write', 'edit')) {
    if ($null -ne (Get-Prop $ap $k)) { $parityFail += "$n.$k" }
  }
  $eff = Get-EffectiveBashStar (Get-Prop $agentTable $n) $cfg
  if ($eff -ne $rootBashStar) { $parityFail += "$n.bash.*=$eff" }
}
if ($parityFail) { Add-Check 'permission-parity-global' $false "per-agent permission deltas present (strict parity broken): $($parityFail -join ', ')" }
else { Add-Check 'permission-parity-global' $true "$($agentNames.Count) agents inherit the global overlay (no bash/read/write/edit deltas)" }

# --- Final: re-validate (the written file MUST satisfy --validate) ---
& $node $generator --validate 2>&1 | ForEach-Object { $_ }
if ($LASTEXITCODE -eq 0) { Add-Check 'post-write-validate' $true 'regenerated file in sync' }
else { Add-Check 'post-write-validate' $false 'post-write validation failed (should never happen)' }

$failed = @($result.checks | Where-Object { -not $_.pass })
$result.status = if ($failed.Count -eq 0) { 'ok' } else { 'fail' }

# --- Fix C: profile-key-loss warning (warning only — never flips status) ---
# Gated on the sidecar marker: only hardware-managed files can lose tier
# state. Marker absent → silent (normal SSoT-only case, regen is lossless).
if ($tierManaged) {
  $tierHint = if ($profileTier) { "-Tier $profileTier" } else { '-Tier <tier>' }
  if ($profileKeys.Count -gt 0) { $keyDetail = "dropped profile-injected keys ($($profileKeys -join ', '))" }
  else { $keyDetail = 'no watchlist keys detected in pre-write file — managed state still stripped' }
  $result.warnings += "Regenerated opencode.json was hardware-managed (.opencode-hw-tier present): $keyDetail. Do NOT commit as-is while a hardware tier is active — re-apply it first: scripts/hardware-profile.ps1 $tierHint"
}

if ($Quiet) {
  $result | ConvertTo-Json -Depth 5 | Write-Output
} else {
  Write-Output ''
  Write-Output "[regenerate-opencode] $($result.status.ToUpper()) — $($result.checks.Count) checks, $($failed.Count) failed"
  foreach ($c in $result.checks) {
    $icon = if ($c.pass) { 'OK ' } else { 'FAIL' }
    Write-Output "  [$icon] $($c.name): $($c.detail)"
  }
  foreach ($w in $result.warnings) {
    Write-Output ''
    Write-Output "  !!! WARNING: $w"
  }
  Write-Output '  opencode.json regenerated from SSoT — no commit made (git status will show it modified).'
}
exit $failed.Count -eq 0 ? 0 : 1
