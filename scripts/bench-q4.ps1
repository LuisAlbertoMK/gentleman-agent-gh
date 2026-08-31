#requires -Version 5.1
[CmdletBinding()]
<#
.SYNOPSIS
    Stub bench Q4_K_M vs FP16 — small_model (title-gen) swap candidate.
.DESCRIPTION
    Mide recursos para el bench local (Ryzen 3700U / Vega 13.94GB):
      1. ollama list — modelos Q4_K_M / FP16 disponibles
      2. Get-Process WorkingSet — consumo de ollama/node (proxy RAM/VRAM, sin nvidia-smi)
      3. Measure-Command — latencia de title generation por modelo (dry-run en stub)
    Es un stub: levanta el dataset de medicion + dry-run del paso 3.
.PARAMETER ModelQ4
    Modelo Q4_K_M en Ollama (default: qwen2.5:3b).
.PARAMETER ModelFP16
    Modelo de referencia (default: opencode/big-pickle, FP16/api).
#>
param(
  [string]$ModelQ4 = 'qwen2.5:3b',
  [string]$ModelFP16 = 'opencode/big-pickle',
  [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Quiet) { $VerbosePreference = 'SilentlyContinue' }

# --- 1. Ollama model list (solo lectura) ---
$ollamaUrl = 'http://127.0.0.1:11434'
$models = @()
try {
  $resp = Invoke-RestMethod -Uri "$ollamaUrl/api/tags" -TimeoutSec 5
  $models = @($resp.models)
  $q = foreach ($m in $models) {
    if ($m.name -match 'qwen|q4|fp16|llama') {
      [PSCustomObject]@{ Name = $m.name; SizeMB = [math]::Round($m.size / 1MB) }
    }
  }
  $q | Format-Table -AutoSize
} catch {
  Write-Warning "Ollama no responde en $ollamaUrl — $($_.Exception.Message)"
}

# --- 2. WorkingSet de procesos relevantes (proxy de VRAM en iGPU compartida) ---
$procs = 'ollama', 'node', 'opencode'
$found = @(Get-Process -Name $procs -ErrorAction SilentlyContinue |
  Select-Object Name, Id, @{n = 'WorkingSetMB'; e = { [math]::Round($_.WorkingSet64 / 1MB) }} |
  Sort-Object WorkingSetMB -Descending)
if ($found.Count -eq 0) {
  Write-Host "Sin procesos ollama/node/opencode activos."
} else {
  $found | Format-Table -AutoSize
}

# --- 3. Latencia title-gen (dry-run en stub) ---
function Get-TitleLatency {
  param([string]$Model)
  # Prompt corto ~3.5 chars/token, estilo titulo del repo
  $prompt = 'Titulo corto para: bench Q4 title gen'
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  # TODO bench real: Invoke-RestMethod /api/generate (qwen) o opencode title-gen (big-pickle)
  Start-Sleep -Milliseconds 10
  $sw.Stop()
  [PSCustomObject]@{ Model = $Model; Ms = $sw.ElapsedMilliseconds; PromptChars = $prompt.Length }
}
Get-TitleLatency -Model $ModelQ4
Get-TitleLatency -Model $ModelFP16

Write-Host "STUB OK — bench real pendiente: ollama pull $ModelQ4; latencia N>=3; keep.tokens 6000."