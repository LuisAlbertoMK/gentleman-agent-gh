#requires -Version 7.6
<#
.SYNOPSIS
  Tokenize every SKILL.md in the repo (parallel python subprocess)
.DESCRIPTION
  Escanea todos los skills y calcula tokens usando tiktoken (si instalado)
  o heurística chars/3.5 como fallback. Output opcional a CSV.
  Usa ForEach-Object -Parallel para tokenizar skills concurrentemente.
.PARAMETER Path
  Directorio de skills (default: .agents/skills/).
.PARAMETER OutCsv
  Ruta para exportar resultados a CSV.
.PARAMETER ThrottleLimit
  Max concurrent python processes (default: 5, CPU-based).
#>
#requires -Version 7.6

param(
    [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent) ".agents\skills"),
    [string]$OutCsv = "",
    [int]$ThrottleLimit = 5
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path $Path)) { Write-Host "[tokenize] Skills dir not found: $Path" -ForegroundColor Red; exit 1 }

$skills = Get-ChildItem $Path -Directory
$rows = $skills | ForEach-Object -Parallel {
    $md = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $md)) { return }
    $content = Get-Content $md -Raw
    $chars = $content.Length
    $heur = [int]($chars / 3.5)
    $tokens = $null
    try {
        $escaped = $md -replace "'", "''"
        $tokens = & python -c "import tiktoken; e=tiktoken.get_encoding('cl100k_base'); print(len(e.encode(open(r'$escaped',encoding='utf-8').read())))" 2>$null
        if ($tokens -notmatch '^\d+$') { $tokens = $null }
    } catch { Write-Warning "[tokenize] tiktoken error for $($_.Name): $_" }
    [PSCustomObject]@{
        Skill = $_.Name
        Chars = $chars
        TokensHeur = $heur
        TokensReal = if ($tokens) { [int]$tokens } else { -1 }
    }
} -ThrottleLimit $ThrottleLimit
$rows | Sort-Object Chars -Descending | Format-Table Skill, Chars, TokensHeur, TokensReal -AutoSize
$totalChars = ($rows | Measure-Object -Property Chars -Sum).Sum
$totalTokens = ($rows | Where-Object { $_.TokensReal -gt 0 } | Measure-Object -Property TokensReal -Sum).Sum
Write-Host "Skills: $($rows.Count) | Total chars: $totalChars | Total tokens (real): $totalTokens" -ForegroundColor Cyan

if ($OutCsv) {
    $rows | Sort-Object Chars -Descending | Export-Csv $OutCsv -NoTypeInformation
    Write-Host "Output: $OutCsv"
}
