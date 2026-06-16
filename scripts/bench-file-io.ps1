# bench-file-io.ps1 — Benchmark de 3 métodos de file I/O × 3 runs
# Uso: .\scripts\bench-file-io.ps1 [target.ps1]
#       .\scripts\bench-file-io.ps1 -Dir D:\project -Runs 5

param(
  [string]$Path = "",
  [string]$Dir = "D:\gentleman-agent-gh",
  [ValidateRange(1,10)]
  [int]$Runs = 3
)

$ErrorActionPreference = 'Stop'

if (-not $Path -and $Dir) {
  # Find the largest PS1 file in the project
  $files = Get-ChildItem $Dir -Recurse -Filter "*.ps1" -File | Sort-Object Length -Descending
  if ($files.Count -eq 0) {
    Write-Host "No .ps1 files found" -ForegroundColor Red
    exit 1
  }
  $Path = $files[0].FullName
  Write-Host "Auto-selected: $Path ($($files[0].Length) bytes)"
}

if (-not (Test-Path $Path)) {
  Write-Host "File not found: $Path" -ForegroundColor Red
  exit 1
}

Write-Host "=== FILE I/O BENCHMARK ===" -ForegroundColor Cyan
Write-Host "Target: $Path ($((Get-Item $Path).Length) bytes)"
Write-Host "Runs: $Runs"
Write-Host "Methods: Get-Content | Read raw | StreamReader"
Write-Host ""

$methods = @(
  @{name="Get-Content (cmdlet)"; script={
    param($f) Get-Content -Path $f -Raw -Encoding utf8
  }}
  @{name="Read raw bytes + UTF8"; script={
    param($f) [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
  }}
  @{name="StreamReader"; script={
    param($f)
    $sr = New-Object System.IO.StreamReader($f, [System.Text.Encoding]::UTF8)
    try {
      $content = $sr.ReadToEnd()
    } finally {
      $sr.Close()
    }
    $content
  }}
)

$allResults = @()

foreach ($method in $methods) {
  Write-Host "--- $($method.name) ---" -ForegroundColor Yellow
  $times = @()
  $sizes = @()
  
  1..$Runs | ForEach-Object {
    # Warm-up: 1 run
    & $method.script $Path > $null
    
    $ms = Measure-Command {
      $content = & $method.script $Path
    }
    $elapsed = $ms.TotalMilliseconds
    $times += $elapsed
    $sizes += $content.Length
    Write-Host "  Run $_ : ${elapsed}ms | ${($content.Length/1KB).ToString('F1')} KB"
  }
  
  $avg = ($times | Measure-Object -Average).Average
  $min = ($times | Measure-Object -Minimum).Minimum
  $max = ($times | Measure-Object -Maximum).Maximum
  
  $allResults += [PSCustomObject]@{
    Method = $method.name
    AvgMs = [math]::Round($avg, 1)
    MinMs = [math]::Round($min, 1)
    MaxMs = [math]::Round($max, 1)
    AvgKB = [math]::Round(($sizes | Measure-Object -Average).Average / 1KB, 1)
  }
  
  Write-Host "  >> AVG: ${avg}ms (min ${min} / max ${max})" -ForegroundColor Green
  Write-Host ""
}

Write-Host "=== I/O BENCHMARK SUMMARY ===" -ForegroundColor Cyan
$allResults | Format-Table Method, AvgMs, MinMs, MaxMs, AvgKB -AutoSize

# Identify fastest
if ($allResults.Count -gt 0) {
  $fastest = $allResults | Sort-Object AvgMs | Select-Object -First 1
  Write-Host "Fastest: $($fastest.Method) @ $($fastest.AvgMs)ms" -ForegroundColor Green
}
