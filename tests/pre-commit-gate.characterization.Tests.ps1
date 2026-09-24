#requires -Version 7
<#
.SYNOPSIS
  Characterization harness for .githooks/pre-commit-gate.ps1 (MVP Step 0 of gate refactor).

.DESCRIPTION
  Captures the CURRENT behavior of the pre-commit gate over controlled staged
  fixtures so future refactors can prove behavior preservation. This file does
  NOT refactor anything — it only snapshots the baseline.

  Isolation trick (verified 2026-09-24): the gate reads staged files from the
  CWD (`git diff --cached`, pre-commit-gate.ps1 L21) but resolves
  scripts/binaries/markers from -RepoRoot (L34 bin/fast.exe, L135 scripts/*,
  L161 .jd-cleared/). So each scenario creates a TEMP git repo, Push-Location
  into it, stages fixtures there, and invokes the gate as
  `pwsh -File <realRepo>/.githooks/pre-commit-gate.ps1 -RepoRoot <realRepo>`.
  The staged set comes from the temp repo; the checks come from the real repo.

  Two isolation requirements discovered during characterization:
  1. The temp repo needs an initial (empty) commit so HEAD exists. Without it,
     [16/26] Write-scope check fails (validate-write-scope.ps1 diffs staged
     against HEAD -> no HEAD -> non-zero exit -> BLOCKING) in EVERY scenario,
     masking the intended signals.
  2. Fixture paths must fall inside .gentleman/write-scope.json allowed_paths
     (single `*` crosses `/`, so `docs/*` and `scripts/*` match one-level
     files). Otherwise [16/26] BLOCKS for scope reasons, again masking the
     intended signal. Fixtures were chosen to avoid heavy checks (no
     .Tests.ps1, no .agents/skills/, no scripts/opencode-config/).
  #
  #   Harness discipline (the gate runs this suite IN-PROCESS, so its
  #   `Set-StrictMode -Version Latest` + `$ErrorActionPreference='Stop'` leak
  #   into the suite; observed failure: `$r.ExitCode` -> PropertyNotFound):
  #   3. Single-object return: native calls pipe to Out-Null and
  #      `[void]$script:TempDirs.Remove($dir)` — a leaked [bool] turns $r
  #      into an array. Call sites additionally take `@(...)[-1]`.
  #   4. Pre-initialized `$out=''` / `$code=-1` / sentinel Summary so a gate
  #      that never runs fails LOUDLY via assertions, not StrictMode errors.
  #   5. Verdict parsing strips ANSI SGR (a raw `ESC[32mOKESC[0m` line never
  #      matches `^\s*OK\s*$`). GIT_* env vars sanitized like the gate does.

  Baseline snapshot (captured 2026-09-24, real repo HEAD as-is):
    A. empty staged            -> exit 0, 28 headers, Gate 28/28,  0 BLOCKING (ALL CLEAR)
    B. docs/*.txt trailing ws  -> exit 0, 28 headers, Gate 28/28,  0 BLOCKING ([1/26] WARN, non-blocking!)
    C. scripts/*.ps1, no marker-> exit 1, 28 headers, Gate 27/28,  1 BLOCKING ([10/26] ROZA)
    D. scripts/*.ps1 + EMPTY (0-byte) legacy marker
                               -> exit 0, 28 headers, Gate 28/28,  0 BLOCKING ([10/26] OK, legacy-clear)
       Isolation note: markers + stale-check resolve against -RepoRoot
       (the REAL repo), so D creates a REAL probe file
       (scripts/gate-char-probe.ps1) + a REAL 0-byte legacy marker
       (.jd-cleared/scripts_gate-char-probe.ps1), stages the probe path in
       the TEMP repo, and removes both real files in `finally`.

  NOTE on B: the plan guessed [1/26] would Fail with exit != 0. The gate code
  (L51) calls Warn, not Fail, for trailing whitespace — Warn counts as passed
  and never sets $blocked. The harness asserts the ACTUAL behavior (WARN +
  exit 0). If a future refactor makes trailing whitespace blocking, test B
  will fail loudly, which is exactly what a characterization test should do.

  Only targeted per-header verdicts are hardcoded (the checks each scenario
  exercises). A full 28-verdict map is intentionally NOT snapshotted: several
  always-run checks ([5/26] overweight skills, [19/26] backlog integrity,
  [20/26]/[25/26] token budgets, [27/28] e2e smoke) depend on live repo state
  and would make the harness brittle. The verdict parser still records every
  header/verdict and the test asserts header count = 28 plus exit code plus
  BLOCKING presence/absence, per the MVP contract.

  Runtime: ~6s per gate invocation, ~25-35s total (budget < 90s).
#>

BeforeAll {
  # HERMETIC + STRICTMODE discipline (required: gate runs this suite IN-PROCESS,
  # L243-281, inheriting `Set-StrictMode -Version Latest` (L9) and
  # `$ErrorActionPreference='Stop'` (L10), and strips GIT_* (L250-253)):
  # 1. Sanitize GIT_* here too so temp repos never resolve against the real repo
  #    (same rationale as the gate's own defense-in-depth comment).
  foreach ($gitEnvVar in 'GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY') {
    Remove-Item "Env:$gitEnvVar" -ErrorAction SilentlyContinue
  }
  $script:RealRepo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  $script:Gate     = Join-Path $script:RealRepo '.githooks/pre-commit-gate.ps1'
  $script:TempDirs = [System.Collections.Generic.List[string]]::new()

  function New-GateTempRepo {
    $base = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
    $dir = Join-Path $base ('gate-char-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir | Out-Null
    $script:TempDirs.Add($dir)
    # Silence native stdout so it can never leak into the caller's success
    # stream (under StrictMode an extra object turns $r into an array and
    # `$r.ExitCode` throws PropertyNotFoundException). LASTEXITCODE survives.
    git -C $dir init -q | Out-Null
    git -C $dir config user.email 'gate-char@test.local' | Out-Null
    git -C $dir config user.name 'gate-char' | Out-Null
    # Empty initial commit so HEAD exists (see header comment: [16/26] needs it).
    git -C $dir commit -q --allow-empty -m init | Out-Null
    return $dir
  }

  function Invoke-GateScenario {
    param(
      [Parameter(Mandatory)][string]$Name,
      [hashtable]$Fixtures = @{}
    )
    $dir = New-GateTempRepo
    # Pre-initialize so StrictMode never sees unassigned variables: if the
    # nested gate never runs, assertions below fail LOUDLY (exit -1, no
    # summary) instead of throwing PropertyNotFoundException.
    [string]$out = ''
    [int]$code = -1
    try {
      foreach ($rel in $Fixtures.Keys) {
        $full = Join-Path $dir $rel
        $parent = Split-Path $full -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
        # -NoNewline:$false would append an extra newline; write bytes exactly as given.
        Set-Content -LiteralPath $full -Value $Fixtures[$rel] -NoNewline -Encoding UTF8
        git -C $dir add -- $rel | Out-Null
      }
      Push-Location -LiteralPath $dir
      try {
        $out = & pwsh -NoProfile -File $script:Gate -RepoRoot $script:RealRepo 2>&1 | Out-String
        $code = $LASTEXITCODE
      } finally { Pop-Location }
    } finally {
      if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue }
      # List.Remove() returns [bool] — MUST void it: finally-block output is
      # part of the function's return value, and a second object turns $r
      # into an array (StrictMode `$r.ExitCode` -> PropertyNotFoundException).
      [void]$script:TempDirs.Remove($dir)
    }
    # Strip ANSI SGR sequences (gate emits hardcoded ESC[32m/ESC[33m/ESC[31m):
    # a raw `  ESC[32mOKESC[0m` line never matches `^\s*OK\s*$`, so without
    # this every verdict degrades to WARN and 'OK' is unassertable.
    $lines = @($out -split "`r?`n" | ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' })

    # Parse headers: [n/N] <name>
    $headers = @()
    foreach ($ln in $lines) {
      if ($ln -match '^\[(\d+)/(\d+)\]\s*(.+?)\s*$') {
        $headers += [PSCustomObject]@{ Index = [int]$Matches[1]; Total = [int]$Matches[2]; Name = $Matches[3] }
      }
    }

    # Verdict per header from lines until the next header or the summary.
    $verdicts = @{}
    $current = $null; $bucket = @()
    $flush = {
      if ($null -ne $current) {
        $v = 'WARN'
        if ($bucket -match 'BLOCKING') { $v = 'BLOCKING' }
        elseif ($bucket -match '^\s*OK\s*$') { $v = 'OK' }
        $verdicts[$current] = $v
      }
    }
    foreach ($ln in $lines) {
      if ($ln -match '^\[(\d+)/(\d+)\]') { & $flush; $current = $Matches[1]; $bucket = @() }
      elseif ($ln -match '===\s*Gate:') { & $flush; $current = $null; $bucket = @() }
      elseif ($null -ne $current) { $bucket += $ln }
    }
    & $flush

    # Sentinel (not $null): `$r.Summary.Passed` must stay StrictMode-safe.
    # Missing summary => Passed/Total = -1 => assertions fail LOUDLY.
    $summary = [PSCustomObject]@{ Passed = -1; Total = -1 }
    $status = $null
    foreach ($ln in $lines) {
      if ($ln -match '===\s*Gate:\s*(\d+)/(\d+)\s*passed\s*===') {
        $summary = [PSCustomObject]@{ Passed = [int]$Matches[1]; Total = [int]$Matches[2] }
      }
      if ($ln -match 'BLOCKED') { $status = 'BLOCKED' }
      elseif ($ln -match 'ALL CLEAR') { $status = 'ALL CLEAR' }
    }

    return [PSCustomObject]@{
      Name       = $Name
      ExitCode   = $code
      Headers    = $headers
      Verdicts   = $verdicts
      Summary    = $summary
      Status     = $status
      RawOutput  = $out
    }
  }
}

AfterAll {
  foreach ($d in $script:TempDirs) {
    if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
  }
}

Describe 'pre-commit-gate characterization (baseline snapshot)' {

  It 'A: empty staged -> exit 0, 28 headers, Gate 28/28, no BLOCKING' {
    # [-1] normalization: take the result object even if a helper ever leaks
    # an extra object into the success stream (array `$r.ExitCode` throws
    # under StrictMode inherited from the in-process gate run).
    $r = @(Invoke-GateScenario -Name 'A-empty')[-1]
    $r.ExitCode | Should -Be 0
    $r.Headers.Count | Should -Be 28
    $r.RawOutput | Should -Not -Match 'BLOCKING'
    $r.Summary.Passed | Should -Be 28
    $r.Summary.Total | Should -Be 28
    $r.Status | Should -Be 'ALL CLEAR'
    $r.Verdicts['16'] | Should -Be 'OK'  # write-scope passes on empty staged (HEAD exists)
  }

  It 'B: trailing whitespace -> [1/26] WARN (non-blocking), exit 0, 28 headers, Gate 28/28' {
    $r = @(Invoke-GateScenario -Name 'B-trailing-ws' -Fixtures @{
      'docs/gate-char-trailing.txt' = "hello   `nworld`n"
    })[-1]
    $r.ExitCode | Should -Be 0
    $r.Headers.Count | Should -Be 28
    $r.RawOutput | Should -Not -Match 'BLOCKING'
    $r.Verdicts['1'] | Should -Be 'WARN'  # gate L51: Warn, NOT Fail
    $r.RawOutput | Should -Match 'trailing whitespace'
    $r.Summary.Passed | Should -Be 28
    $r.Summary.Total | Should -Be 28
    $r.Status | Should -Be 'ALL CLEAR'
  }

  It 'C: scripts/*.ps1 without JD marker -> [10/26] BLOCKING, exit 1, 28 headers, Gate 27/28' {
    $r = @(Invoke-GateScenario -Name 'C-roza' -Fixtures @{
      'scripts/gate-char-foo.ps1' = "#requires -Version 7`nWrite-Host 'hi'`n"
    })[-1]
    $r.ExitCode | Should -Not -Be 0
    $r.Headers.Count | Should -Be 28
    $r.Verdicts['10'] | Should -Be 'BLOCKING'
    $r.RawOutput | Should -Match 'ROZA zone files staged without JD dual review'
    $r.Summary.Passed | Should -Be 27
    $r.Summary.Total | Should -Be 28
    $r.Status | Should -Be 'BLOCKED'
    $r.Verdicts['16'] | Should -Be 'OK'  # scripts/* is scope-allowed; only [10/26] blocks
  }

  It 'D: scripts/*.ps1 with EMPTY (0-byte) legacy marker -> no crash, [10/26] OK, exit 0, 28 headers, Gate 28/28' {
    $probeRel = 'scripts/gate-char-probe.ps1'
    $probeFull = Join-Path $script:RealRepo $probeRel
    $markerFull = Join-Path $script:RealRepo '.jd-cleared/scripts_gate-char-probe.ps1'
    # Pre-clean so a leftover from an aborted run cannot mask the signal.
    Remove-Item -LiteralPath $probeFull -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $markerFull -Force -ErrorAction SilentlyContinue
    try {
      Set-Content -LiteralPath $probeFull -Value "#requires -Version 7`nWrite-Host 'probe'`n" -NoNewline -Encoding UTF8
      New-Item -ItemType File -Path $markerFull -Force | Out-Null
      [System.IO.File]::WriteAllBytes($markerFull, [byte[]]@())
      (Get-Item -LiteralPath $markerFull).Length | Should -Be 0
      $r = @(Invoke-GateScenario -Name 'D-empty-marker' -Fixtures @{
        'scripts/gate-char-probe.ps1' = "#requires -Version 7`nWrite-Host 'probe'`n"
      })[-1]
      # The bug: Get-Content -Raw on a 0-byte file returns $null and .Trim()
      # throws (PropertyNotFound/InvalidOperation), aborting the whole gate.
      $r.RawOutput | Should -Not -Match 'You cannot call a method on a null-valued expression'
      $r.RawOutput | Should -Not -Match 'InvalidOperation'
      $r.ExitCode | Should -Be 0
      $r.Headers.Count | Should -Be 28
      $r.Verdicts['10'] | Should -Be 'OK'  # empty marker = legacy-clear, target exists -> no prune
      $r.RawOutput | Should -Not -Match 'BLOCKING'
      $r.Summary.Passed | Should -Be 28
      $r.Summary.Total | Should -Be 28
      $r.Status | Should -Be 'ALL CLEAR'
    } finally {
      # ALWAYS leave the real repo as it was: no probe, no marker.
      Remove-Item -LiteralPath $probeFull -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $markerFull -Force -ErrorAction SilentlyContinue
    }
  }
}
