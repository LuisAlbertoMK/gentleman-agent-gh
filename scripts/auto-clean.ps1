# auto-clean.ps1 — Delete temp files older than 24h in opencode temp dir
# Usage: powershell -File auto-clean.ps1 [-MaxAgeHours 24]
# Should run at session start per AGENTS.md "AUTO-CLEAN" rule

param(
    [int]$MaxAgeHours = 24,
    [string]$TempDir = "$env:LOCALAPPDATA\Temp\opencode"
)

# Verify dir exists
if (-not (Test-Path $TempDir)) {
    Write-Host "[auto-clean] No temp dir: $TempDir" -ForegroundColor Yellow
    exit 0
}

# Find files older than threshold
$cutoff = (Get-Date).AddHours(-$MaxAgeHours)
$oldFiles = Get-ChildItem -Path $TempDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }

if (-not $oldFiles) {
    Write-Host "[auto-clean] 0 files older than $MaxAgeHours h" -ForegroundColor Green
    exit 0
}

# Delete
$count = 0
$size = 0
foreach ($f in $oldFiles) {
    $size += $f.Length
    Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
    $count++
}

$sizeMB = [math]::Round($size / 1MB, 2)
Write-Host "[auto-clean] Deleted $count files ($sizeMB MB) older than $MaxAgeHours h" -ForegroundColor Cyan
