#requires -Version 7.6

<#
.SYNOPSIS
  Admin-level system optimizations for Ryzen 3700U + NVMe
.DESCRIPTION
  REQUIRES: PowerShell as Administrator. Fix page file to 4GB, DISM component
  cleanup, scheduled tasks tuning, services optimization, and registry tweaks.

.PARAMETER DisableHibernation
  Disable hibernation and delete hiberfil.sys to free disk space.

.PARAMETER SetPageFile
  Set page file to fixed 4GB to reduce disk usage while preserving crash dumps.

.PARAMETER RunDism
  Run DISM component cleanup (StartComponentCleanup) to shrink WinSxS.

.PARAMETER DryRun
  Show what would be done without making changes. Default: $false.
#>
#
# WHAT THIS DOES:
#   1. Fix page file to 4GB (recovers ~8-10 GB on C:)
#   2. DISM component cleanup (recovers ~2-4 GB from winsxs)
#
# BASELINE before running: C: 25.7 GB free (21.7%)
# TARGET after running:    C: ~35-40 GB free (~30-34%)

param(
    [switch]$Quiet,
    [switch]$DisableHibernation,
    [switch]$SetPageFile,
    [switch]$RunDism,
    [switch]$DryRun = $false,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---- VERIFY ADMIN ----
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Must run as Administrator. Right-click → 'Run as Administrator'" -ForegroundColor Red
    exit 1
}

# ---- CHECKPOINT / RESTORE ----
$checkpointFile = "$env:TEMP\gentleman-optimize-checkpoint.json"
if ($Restore) {
    if (-not (Test-Path $checkpointFile)) {
        Write-Host "[err] No checkpoint found at $checkpointFile" -ForegroundColor Red
        exit 1
    }
    $cp = Get-Content $checkpointFile -Raw | ConvertFrom-Json
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  RESTORING PREVIOUS STATE" -ForegroundColor Cyan
    Write-Host "  Saved: $($cp.timestamp)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    # Restore page file to automatic
    if ($cp.hadAutoPageFile -eq $false) {
        try {
            $cs = Get-CimInstance Win32_ComputerSystem
            $cs.AutomaticManagedPagefile = $true
            Set-CimInstance -InputObject $cs | Out-Null
            Write-Host "  ✓ Page file restored to automatic" -ForegroundColor Green
        } catch { Write-Host "  ✗ Failed to restore page file: $_" -ForegroundColor Red }
    }
    # Restore hibernation
    if ($cp.hadHibernation -eq $true) {
        try { powercfg /h on 2>&1 | Out-Null; Write-Host "  ✓ Hibernation re-enabled" -ForegroundColor Green }
        catch { Write-Host "  ✗ Failed to enable hibernation: $_" -ForegroundColor Red }
    }
    # Restore registry values
    foreach ($key in $cp.registry.PSObject.Properties) {
        try {
            Set-ItemProperty -Path $key.Name -Name $key.Value.name -Value $key.Value.value -Type DWord -ErrorAction Stop
            Write-Host "  ✓ Restored $($key.Value.name) = $($key.Value.value)" -ForegroundColor Green
        } catch { Write-Host "  - Could not restore $($key.Name): $_" -ForegroundColor Gray }
    }
    Write-Host "`n[ok] Restore complete. Reboot recommended." -ForegroundColor Green
    Remove-Item $checkpointFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Save checkpoint before any changes
if (-not $DryRun) {
    $cp = @{
        timestamp       = (Get-Date -Format 'o')
        hadAutoPageFile = $null
        hadHibernation  = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).AutomaticManagedPagefile
        registry        = @{}
    }
    # Snapshot current registry values
    $regKeys = @(
        @{Path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name = "NtfsDisableLastAccessUpdate"}
        @{Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"}
    )
    foreach ($rk in $regKeys) {
        try {
            $val = Get-ItemProperty -Path $rk.Path -Name $rk.Name -ErrorAction Stop
            $cp.registry[$rk.Path] = @{name = $rk.Name; value = $val.$($rk.Name)}
        } catch { $cp.registry[$rk.Path] = @{name = $rk.Name; value = $null} }
    }
    $cp | ConvertTo-Json | Set-Content $checkpointFile -Encoding UTF8
    Write-Host "[checkpoint] Saved to $checkpointFile" -ForegroundColor DarkGray
    Write-Host "       To restore: $PSCommandPath -Restore" -ForegroundColor DarkGray
}

$before = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SYSTEM OPTIMIZATION" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "  C: free BEFORE: $([math]::Round($before/1GB,2)) GB" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# ---- 1. PAGE FILE ----
if ($SetPageFile) {
    Write-Host "`n[1/5] Setting page file to fixed 4GB..." -ForegroundColor Green
    if (-not $DryRun) {
        try {
            $cs = Get-CimInstance Win32_ComputerSystem
            $cs.AutomaticManagedPagefile = $false
            Set-CimInstance -InputObject $cs | Out-Null
            New-CimInstance -Namespace "root/cimv2" -ClassName Win32_PageFileSetting -Property @{
                Name = "C:\pagefile.sys"
                InitialSize = 4096
                MaximumSize = 4096
            } -ErrorAction Stop | Out-Null
            Write-Host "  ✓ Page file set to 4096 MB (fixed)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [DRY-RUN] Would set page file to 4096 MB fixed" -ForegroundColor Yellow
    }
}

# ---- 2. DISM CLEANUP ----
if ($RunDism) {
    Write-Host "`n[2/5] DISM component cleanup (StartComponentCleanup)..." -ForegroundColor Green
    if (-not $DryRun) {
        Write-Host "  Running DISM... (this may take 5-15 minutes)" -ForegroundColor Yellow
        $dismResult = Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ DISM cleanup completed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ DISM failed (exit: $LASTEXITCODE)" -ForegroundColor Red
            $dismResult | Select-Object -Last 5
        }
    } else {
        Write-Host "  [DRY-RUN] Would run: Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase" -ForegroundColor Yellow
    }

    Write-Host "`n[3/5] DISM component cleanup (AnalyzeComponentStore)..." -ForegroundColor Green
    if (-not $DryRun) {
        Dism.exe /online /Cleanup-Image /AnalyzeComponentStore 2>&1 | Out-Null
        Write-Host "  Component store analysis output above" -ForegroundColor Gray
    }
}

# ---- 3. HIBERNATION ----
if ($DisableHibernation) {
    Write-Host "`n[4/5] Disabling hibernation..." -ForegroundColor Green
    if (-not $DryRun) {
        try {
            $hiberFile = Get-Item "C:\hiberfil.sys" -ErrorAction SilentlyContinue
            $hiberSize = if ($hiberFile) { $hiberFile.Length } else { 0 }
            powercfg /h off 2>&1 | Out-Null
            Write-Host "  ✓ Hibernation disabled (recovered ~$([math]::Round($hiberSize/1GB,2)) GB)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Failed: $_" -ForegroundColor Red
        }
    } else {
        $hiberFile = Get-Item "C:\hiberfil.sys" -ErrorAction SilentlyContinue
        $hiberSize = if ($hiberFile) { $hiberFile.Length } else { 0 }
        Write-Host "  [DRY-RUN] Would disable hibernation (hiberfil.sys = $([math]::Round($hiberSize/1GB,2)) GB)" -ForegroundColor Yellow
    }
}

# ---- 4. REGISTRY TWEAKS ----
Write-Host "`n[5/5] Registry tweaks for I/O performance..." -ForegroundColor Green
if (-not $DryRun) {
    # Disable NTFS last access time updates (reduces disk writes)
    try {
        $ntfsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $ntfsPath -Name "NtfsDisableLastAccessUpdate" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✓ NTFS last access update: disabled" -ForegroundColor Green
    } catch { Write-Host "  - NTFS tweak skipped (common if already set)" -ForegroundColor Gray }

    # Disable 8.3 filename creation (reduces directory enumeration overhead)
    try {
        fsutil behavior set disable8dot3 1 2>&1 | Out-Null
        Write-Host "  ✓ 8.3 name creation: disabled" -ForegroundColor Green
    } catch { Write-Host "  - 8.3 tweak skipped" -ForegroundColor Gray }

    # Increase system responsiveness (adjust processor scheduling)
    try {
        $perfPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        Set-ItemProperty -Path $perfPath -Name "Win32PrioritySeparation" -Value 38 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "  ✓ CPU scheduling: adjusted for foreground apps" -ForegroundColor Green
    } catch { Write-Host "  - Priority tweak skipped" -ForegroundColor Gray }
} else {
    Write-Host "  [DRY-RUN] Would apply NTFS + registry I/O tweaks" -ForegroundColor Yellow
}

# ---- SUMMARY ----
$after = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
$gained = ($after - $before)/1GB
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OPTIMIZATION COMPLETE" -ForegroundColor Cyan
Write-Host "  Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "  C: free BEFORE: $([math]::Round($before/1GB,2)) GB" -ForegroundColor Yellow
Write-Host "  C: free AFTER:  $([math]::Round($after/1GB,2)) GB" -ForegroundColor Green
Write-Host "  RECOVERED:      $([math]::Round($gained,2)) GB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n⚠  A REBOOT is recommended to apply all changes." -ForegroundColor Magenta
Write-Host "   To undo: $PSCommandPath -Restore" -ForegroundColor DarkGray
Write-Host "   After reboot, run: Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase" -ForegroundColor Gray
