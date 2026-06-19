Set-StrictMode -Version 5.1
$ErrorActionPreference = 'Stop'

# tokenize.ps1 â€” Compare tokenization of before/after text
# Usage: .\tokenize.ps1 "verbose text" "concise text"
#        .\tokenize.ps1 -FileBefore path -FileAfter path

param(
    [string]$TextBefore,
    [string]$TextAfter,
    [string]$FileBefore,
    [string]$FileAfter
)

# Load from files if specified
if ($FileBefore) { $TextBefore = Get-Content $FileBefore -Raw -Encoding Utf8 }
if ($FileAfter) { $TextAfter = Get-Content $FileAfter -Raw -Encoding Utf8 }

if (-not $TextBefore -or -not $TextAfter) {
    Write-Host "Usage: .\tokenize.ps1 `"verbose text`" `"concise text`""
    Write-Host "       .\tokenize.ps1 -FileBefore a.txt -FileAfter b.txt"
    exit 1
}

# Tier 1: Word count
$wBefore = @($TextBefore -split '\s+' | Where-Object { $_ }).Count
$wAfter  = @($TextAfter -split '\s+' | Where-Object { $_ }).Count

# Tier 2: Chars + heuristic
$cBefore = $TextBefore.Length
$cAfter  = $TextAfter.Length
$hBefore = [math]::Round($cBefore / 3.5)
$hAfter  = [math]::Round($cAfter / 3.5)

# Tier 3: tiktoken (if available)
$tBefore = $null; $tAfter = $null
$tiktokAvailable = $false
try {
    $result = & python -c "import tiktoken; e=tiktoken.get_encoding('cl100k_base'); print(len(e.encode('''$($TextBefore.Replace("'","''"))''')), len(e.encode('''$($TextAfter.Replace("'","''"))''')))" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $parts = ($result | Out-String).Trim() -split '\s+'
        $tBefore = [int]$parts[0]
        $tAfter = [int]$parts[1]
        $tiktokAvailable = $true
    }
} catch {
    # tiktoken not available, heuristic fallback used below
    Write-Verbose "tiktoken unavailable, using character heuristic"
}

# Display
$border = "=" * 60
Write-Host $border
Write-Host "TOKENIZACION METRICS" -ForegroundColor Cyan
Write-Host $border
Write-Host ""

Write-Host "ANTES: $TextBefore" -ForegroundColor Yellow
Write-Host "DESPUES: $TextAfter" -ForegroundColor Green
Write-Host ""

Write-Host ("{0,-14} {1,8} {2,8} {3,8} {4,8}" -f "Metrica", "Antes", "Despues", "Delta", "Delta%") -ForegroundColor White
Write-Host ("{0,-14} {1,8} {2,8} {3,8} {4,8}" -f ("-"*14), ("-"*8), ("-"*8), ("-"*8), ("-"*8))

function Show-Row($name, $before, $after) {
    if ($before -eq 0 -and $after -eq 0) { return }
    $d = $after - $before
    if ($before -ne 0) { $p = [math]::Round(($d / $before) * 100, 1) } else { $p = 0 }
    $arrow = if ($d -lt 0) { "GREEN" } elseif ($d -gt 0) { "RED" } else { "GRAY" }
    $color = if ($arrow -eq "GREEN") { "Green" } elseif ($arrow -eq "RED") { "Red" } else { "Gray" }
    $dp = if ($d -ge 0) { "+$d" } else { "$d" }
    $pp = if ($p -ge 0) { "+$p%" } else { "$p%" }
    Write-Host ("{0,-14} {1,8} {2,8} {3,8} {4,8}" -f $name, $before, $after, $dp, $pp) -ForegroundColor $color
}

Show-Row "Palabras" $wBefore $wAfter
Show-Row "Caracteres" $cBefore $cAfter
Show-Row "Tokens(heur)" $hBefore $hAfter
if ($tiktokAvailable) { Show-Row "Tokens(real)" $tBefore $tAfter }

Write-Host ""
if ($tiktokAvailable) {
    $tr = if ($tBefore -ne 0) { [math]::Round(($tAfter - $tBefore) / $tBefore * 100, 1) } else { 0 }
    Write-Host "Compresion REAL: $([math]::Abs($tr))% menos tokens (tiktoken)" -ForegroundColor Magenta
} else {
    $hr = if ($hBefore -ne 0) { [math]::Round(($hAfter - $hBefore) / $hBefore * 100, 1) } else { 0 }
    Write-Host "Compresion EST: $([math]::Abs($hr))% menos tokens (heuristic)" -ForegroundColor Magenta
    Write-Host "TIP: Instala tiktoken para precision real: pip install tiktoken" -ForegroundColor DarkYellow
}
Write-Host $border
