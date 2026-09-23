#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess=$true)]
# PSSA FP: $aborted is assigned in ForEach closures and read at :222 (abort guard) — PSSA cannot trace cross-scope control flow; $null pattern doesn't reduce assignment count
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'aborted')]
<#
.SYNOPSIS
  Clean temporary worktree artifacts: %TEMP%\opencode and repo *.tmp-* / *.bak-*.
  SAFE BY DEFAULT: with no -Apply, lists targets without touching anything.

.DESCRIPTION
  Scans a CLOSED set of roots for temporary files:
    1. %TEMP%\opencode\* (opencode session temp files)
    2. *.tmp-* and *.bak-* inside the repo (age-gated)
  Never touches tool-output (opt-in only via -IncludeToolOutput, >14d and never locked).
  Every deletion target is validated against the allowed root set.
  If any path escapes the allowed roots, the entire operation aborts.

.PARAMETER RepoRoot
  Repository root. Default: current directory (walks up to git root).

.PARAMETER OlderThanDays
  Only target files older than this many days. Default: 7.

.PARAMETER Apply
  Actually delete files. Without this, only lists targets.

.PARAMETER Json
  Output machine-readable JSON instead of human text.

.PARAMETER IncludeToolOutput
  Also scan ~/.local/share/opencode/tool-output for files >14 days old.
  Disabled by default: tool-output is active session state.

.PARAMETER Force
  Bypass ShouldProcess confirmation prompts in apply mode (implies -Confirm:$false).
  Never bypasses -WhatIf: -Force -WhatIf still only reports.

.EXAMPLE
  & scripts/clean-worktree-temp.ps1                # list only (default)
  & scripts/clean-worktree-temp.ps1 -Apply         # delete matching files
  & scripts/clean-worktree-temp.ps1 -Apply -Json   # delete + JSON summary
  & scripts/clean-worktree-temp.ps1 -IncludeToolOutput -Apply
#>
param(
  [string]$RepoRoot = (Get-Location).Path,
  [ValidateRange(1, 365)]
  [int]$OlderThanDays = 7,
  [switch]$Apply,
  [switch]$Json,
  [switch]$IncludeToolOutput,
  [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# -Force bypasses ShouldProcess confirmation prompts; -WhatIf is still honored
# because ShouldProcess checks WhatIfPreference regardless of ConfirmPreference.
if ($Force) { $ConfirmPreference = 'None' }

# ---- resolve git root ----
$gitRoot = $null
$resolved = Resolve-Path -LiteralPath $RepoRoot -ErrorAction SilentlyContinue
if (-not $resolved) {
  if ($Json) {
    Write-Output (@{ ok = $false; error = "Path not found: $RepoRoot" } | ConvertTo-Json -Compress)
  } else {
    Write-Error "Path not found: $RepoRoot"
  }
  exit 2
}
$dir = $resolved.Path
while ($dir) {
  if (Test-Path -LiteralPath (Join-Path -Path $dir -ChildPath ".git")) {
    $gitRoot = $dir
    break
  }
  $parent = Split-Path -Parent $dir
  if (-not $parent -or $parent -eq $dir) { break }
  $dir = $parent
}
if (-not $gitRoot) {
  if ($Json) {
    Write-Output (@{ ok = $false; error = "Not inside a git repository: $RepoRoot" } | ConvertTo-Json -Compress)
  } else {
    Write-Error "Not inside a git repository: $RepoRoot"
  }
  exit 2
}

# ---- resolve canonical paths (avoid 8.3 short-name mismatch) ----
function Get-CanonicalPath {
  param([string]$Path)
  # GetFullPath normalizes 8.3 short names to long names on Windows
  return [System.IO.Path]::GetFullPath($Path)
}

# ---- allowed root set (closed scope) ----
$allowedRoots = @()

$tempRoot = Join-Path -Path $env:TEMP -ChildPath "opencode"
$tempRoot = Get-CanonicalPath -Path $tempRoot
if (Test-Path -LiteralPath $tempRoot) {
  $allowedRoots += $tempRoot
}

if ($IncludeToolOutput) {
  $toolOutputRoot = Join-Path -Path $env:USERPROFILE -ChildPath ".local\share\opencode\tool-output"
  $toolOutputRoot = Get-CanonicalPath -Path $toolOutputRoot
  if (Test-Path -LiteralPath $toolOutputRoot) {
    $allowedRoots += $toolOutputRoot
  }
}

$allowedRoots += $gitRoot

# ---- helper: validate path stays within allowed roots ----
function Test-PathInScope {
  param([string]$FilePath)
  $current = $FilePath.Replace('/', '\')
  # strip trailing separators and trailing dot (e.g. C:\dir\. -> C:\dir)
  while ($current.EndsWith('\') -or $current.EndsWith('.')) {
    $current = $current.TrimEnd('\').TrimEnd('.')
  }

  # Junction safety: PS 5.1 Get-ChildItem -Recurse silently follows junctions.
  # A junction inside an allowed root pointing outside would pass the prefix
  # check below. Walk ancestors and resolve any reparse point to its real target.
  $resolved = $current
  $ancestor = Split-Path $resolved -Parent
  while ($ancestor -and $ancestor -ne (Split-Path $ancestor -Parent)) {
    try {
      $item = Get-Item -LiteralPath $ancestor -Force -ErrorAction Stop
      if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $target = $item.Target
        if ($target) {
          $junctionParent = Split-Path $ancestor -Parent
          $resolvedBase = [System.IO.Path]::GetFullPath((Join-Path $junctionParent $target))
          $belowJunction = $resolved.Substring($ancestor.Length).TrimStart('\')
          $resolved = if ($belowJunction) {
            [System.IO.Path]::GetFullPath((Join-Path $resolvedBase $belowJunction))
          } else { $resolvedBase }
          # Restart walk from the newly resolved path
          $ancestor = Split-Path $resolved -Parent
          continue
        }
      }
    } catch { }
    $parent = Split-Path $ancestor -Parent
    if ($parent -eq $ancestor) { break }
    $ancestor = $parent
  }

  $normalizedLower = $resolved.Replace('/', '\').ToLowerInvariant()
  foreach ($root in $allowedRoots) {
    $rootNorm = $root.Replace('/', '\').TrimEnd('\').ToLowerInvariant()
    if ($normalizedLower -eq $rootNorm) { return $true }
    if ($normalizedLower.StartsWith($rootNorm + '\')) { return $true }
  }
  return $false
}

$items = [System.Collections.ArrayList]::new()
$aborted = $false

# ---- scan 1: %TEMP%\opencode\* ----
if (Test-Path -LiteralPath $tempRoot) {
  Get-ChildItem -LiteralPath $tempRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer } |
    ForEach-Object {
      if (Test-PathInScope -FilePath $_.FullName) {
        [void]$items.Add(@{
          Path     = $_.FullName
          SizeMB   = [math]::Round($_.Length / 1MB, 2)
          AgeDays  = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalDays, 1)
          Category = 'temp-opencode'
        })
      } else {
        Write-Warning "ABORT: path escapes allowed roots: $($_.FullName)"
        $aborted = $true
      }
    }
}

# ---- scan 2: repo *.tmp-* and *.bak-* ----
$tmpPatterns = @('*.tmp-*', '*.bak-*')
foreach ($pattern in $tmpPatterns) {
  Get-ChildItem -LiteralPath $gitRoot -Recurse -File -Filter $pattern -Force -ErrorAction SilentlyContinue |
    Where-Object {
      $ageDays = ((Get-Date) - $_.LastWriteTime).TotalDays
      (-not $_.PSIsContainer) -and ($ageDays -ge $OlderThanDays)
    } |
    ForEach-Object {
      if (Test-PathInScope -FilePath $_.FullName) {
        [void]$items.Add(@{
          Path     = $_.FullName
          SizeMB   = [math]::Round($_.Length / 1MB, 2)
          AgeDays  = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalDays, 1)
          Category = 'repo-temp'
        })
      } else {
        Write-Warning "ABORT: path escapes allowed roots: $($_.FullName)"
        $aborted = $true
      }
    }
}

# ---- scan 3: tool-output (opt-in, >14 days only) ----
if ($IncludeToolOutput) {
  $toolOutputRoot = Join-Path -Path $env:USERPROFILE -ChildPath ".local\share\opencode\tool-output"
  if (Test-Path -LiteralPath $toolOutputRoot) {
    Get-ChildItem -LiteralPath $toolOutputRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
      Where-Object {
        $ageDays = ((Get-Date) - $_.LastWriteTime).TotalDays
        (-not $_.PSIsContainer) -and ($ageDays -ge 14)
      } |
      ForEach-Object {
        if (Test-PathInScope -FilePath $_.FullName) {
          [void]$items.Add(@{
            Path     = $_.FullName
            SizeMB   = [math]::Round($_.Length / 1MB, 2)
            AgeDays  = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalDays, 1)
            Category = 'tool-output'
          })
        } else {
          Write-Warning "ABORT: path escapes allowed roots: $($_.FullName)"
          $aborted = $true
        }
      }
  }
}

# ---- abort guard ----
if ($aborted) {
  $msg = "Aborted: one or more paths escaped the allowed root set. No files were removed."
  if ($Json) {
    Write-Output (@{ ok = $false; error = $msg; items = @() } | ConvertTo-Json -Compress)
  } else {
    Write-Error $msg
  }
  exit 1
}

# ---- summary metrics ----
$totalItems = @($items).Count
$totalSizeMB = 0
if ($totalItems -gt 0) {
  foreach ($item in $items) {
    $totalSizeMB += $item.SizeMB
  }
}
$totalSizeMB = [math]::Round($totalSizeMB, 2)

# ---- apply mode: deletions via ShouldProcess ----
$removed = 0
if ($Apply -and $totalItems -gt 0) {
  foreach ($item in $items) {
    $target = $item.Path
    if ($PSCmdlet.ShouldProcess($target, "Remove temporary file")) {
      # TOCTOU guard: re-validate path (junction may have been swapped since scan)
      if (-not (Test-PathInScope -FilePath $target)) {
        Write-Warning "ABORT: path escaped scope during apply: $target"
        $aborted = $true
        break
      }
      try {
        Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        $removed++
      } catch {
        Write-Warning "Could not remove '$target': $($_.Exception.Message)"
      }
    }
  }
}

# ---- output ----
$effectiveApply = $Apply -and (-not $WhatIfPreference)
if ($Json) {
  $result = @{
    ok          = $true
    mode        = $(if ($effectiveApply) { 'apply' } else { 'dry-run' })
    repo        = $gitRoot
    olderThan   = $olderThanDays
    totalItems  = $totalItems
    totalSizeMB = $totalSizeMB
    removed     = $removed
    includeToolOutput = [bool]$IncludeToolOutput
    items       = @($items | ForEach-Object {
      @{ path = $_.Path; sizeMB = $_.SizeMB; ageDays = $_.AgeDays; category = $_.Category }
    })
  }
  Write-Output ($result | ConvertTo-Json -Compress -Depth 3)
  exit 0
}

# ---- human report ----
$modeLabel = if ($effectiveApply) { 'APPLY' } else { 'DRY-RUN' }
Write-Output "== clean-worktree-temp | mode: $modeLabel | repo: $gitRoot =="
Write-Output ""

if ($totalItems -eq 0) {
  Write-Output "No temporary files found."
} else {
  Write-Output ("Found {0} file(s) totaling {1} MB:" -f $totalItems, $totalSizeMB)
  Write-Output ""
  foreach ($item in $items) {
    Write-Output ("  [{0}] {1} ({2} MB, {3}d old)" -f $item.Category, $item.Path, $item.SizeMB, $item.AgeDays)
  }
}

Write-Output ""
if ($effectiveApply) {
  Write-Output ("Applied: removed {0} of {1} file(s)." -f $removed, $totalItems)
} else {
  $extra = ''
  if (-not $IncludeToolOutput) {
    $extra = " (tool-output excluded; pass -IncludeToolOutput to include)"
  }
  $whatIfNote = ''
  if ($WhatIfPreference) { $whatIfNote = " (-WhatIf active)" }
  Write-Output "Dry-run: nothing removed. Re-run with -Apply to delete$extra$whatIfNote."
}
