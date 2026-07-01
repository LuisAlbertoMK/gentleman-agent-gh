#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    SkillSpector security gate for agent skills. Scans .agents/skills/
  for vulnerabilities using NVIDIA SkillSpector (static analysis only).
.DESCRIPTION
  Optional gate in the !ship pipeline. Tries skillspector CLI first,
  falls back to Docker image, then gracefully skips if unavailable.
  Self-modification findings (RA1) in dreaming/immune-system skills
  are intentional and do not block the gate.

.PARAMETER SkillsPath
  Path to skills directory (default: .agents/skills).
.PARAMETER FailOnRisk
  Exit code 1 if risk score exceeds this threshold (0-100, default: 100).
  Default 100 accepts self-modification findings (by design).
  Set lower for strict CI: skillspector-gate.ps1 -FailOnRisk 50
.PARAMETER DockerImage
  Docker image name when using Docker fallback (default: skillspector).
#>
param(
    [string]$SkillsPath = ".agents/skills",
    [int]$FailOnRisk = 100,
    [string]$DockerImage = "skillspector"
)

$ErrorActionPreference = "Stop"
$scriptName = "skillspector-gate"

# Resolve full path
$resolvedPath = Resolve-Path $SkillsPath -ErrorAction SilentlyContinue
if (-not $resolvedPath) {
    Write-Warning "${scriptName}: Path '$SkillsPath' not found — skipping"
    exit 0
}

function Write-Report {
    param($report)
    if (-not $report) { Write-Host "   ⚪ No report to parse"; return }

    $riskScore = $report.risk_assessment.score
    $severity = $report.risk_assessment.severity
    $findingsCount = ($report.issues | Measure-Object).Count

    Write-Host "   Risk score: $riskScore/100 ($severity)"
    Write-Host "   Findings: $findingsCount"

    if ($findingsCount -gt 0 -and $report.issues) {
        foreach ($f in $report.issues) {
            $row = [PSCustomObject]@{
                ID       = $f.id
                Category = $f.category
                Severity = $f.severity
                File     = $f.location.file
                Line     = $f.location.start_line
                Confidence = "{0:P0}" -f $f.confidence
            }
            $row | Format-Table -AutoSize | Out-Host
        }
    }

    # Filter out RA1 (self-modification) — these are by design in system skills
    $realFindings = $report.issues | Where-Object { $_.id -ne "RA1" }
    $realCount = ($realFindings | Measure-Object).Count

    if ($realCount -eq 0) {
        Write-Host "   ✅ Only RA1 findings (self-modification by design) — clean"
        return
    }

    if ($riskScore -ge $FailOnRisk) {
        Write-Warning "⚠️ Risk score $riskScore exceeds threshold $FailOnRisk ($realCount non-RA1 findings)"
    }

    if ($riskScore -ge 30) {
        Write-Host "   → Revisar hallazgos antes de commit. RA1 ignorados por diseño."
    } else {
        Write-Host "   ✅ Skills clean (non-RA1 risk < threshold)"
    }
}

function Run-Scan {
    param([string]$Runner, [string]$JsonOutput)
    if ([string]::IsNullOrWhiteSpace($JsonOutput)) {
        Write-Warning "${scriptName}: Empty output from $Runner — skipping"
        return
    }
    # Strip warning lines before JSON (SkillSpector prints warnings to stdout)
    $jsonStart = $JsonOutput.IndexOf('{')
    if ($jsonStart -ge 0) {
        $JsonOutput = $JsonOutput.Substring($jsonStart)
    }
    try {
        $report = $JsonOutput | ConvertFrom-Json
        Write-Report $report
    } catch {
        Write-Warning "${scriptName}: Could not parse $Runner output — skipping gate"
        Write-Host "Raw output (first 500 chars):"
        Write-Host ($JsonOutput.Substring(0, [Math]::Min(500, $JsonOutput.Length)))
    }
}

# --- Try CLI ---
$sp = Get-Command "skillspector" -ErrorAction SilentlyContinue
if ($sp) {
    Write-Host "🔍 [CLI] Scanning skills with SkillSpector (static only)..."
    $jsonOutput = & skillspector scan $resolvedPath --no-llm --format json 2>&1 | Out-String
    Run-Scan -Runner "CLI" -JsonOutput $jsonOutput
    exit 0
}

# --- Try Docker ---
$dockerOk = $false
try {
    $null = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) { $dockerOk = $true }
} catch { }

if ($dockerOk) {
    Write-Host "🔍 [Docker] Scanning skills with SkillSpector (static only)..."
    $hostPath = (Split-Path $resolvedPath.Path -Parent) -replace '\\', '/'
    $scanTarget = "/scan/$(Split-Path $resolvedPath.Path -Leaf)"
    $jsonOutput = docker run --rm -v "${hostPath}:/scan" $DockerImage scan $scanTarget --no-llm --format json 2>&1 | Out-String
    Run-Scan -Runner "Docker" -JsonOutput $jsonOutput
    exit 0
}

# --- Neither available ---
Write-Host "⚪ SkillSpector not installed — skipping"
Write-Host "   CLI: pip install git+https://github.com/NVIDIA/SkillSpector.git"
Write-Host "   Docker: docker build -t skillspector . (from repo clone)"
exit 0
