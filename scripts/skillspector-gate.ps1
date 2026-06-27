#requires -Version 5.1
<#
.SYNOPSIS
    SkillSpector security gate for agent skills. Scans .agents/skills/
  for vulnerabilities using NVIDIA SkillSpector (static analysis only).
.DESCRIPTION
  Optional gate in the !ship pipeline. If SkillSpector is not installed,
  prints a one-time notice and passes (non-blocking).
  Installation: see https://github.com/NVIDIA/SkillSpector
  Requires Python >=3.12,<3.14. On Python 3.14+ use Docker:
    docker run --rm -v "$PWD:/scan" skillspector scan /scan/.agents/skills --no-llm

.PARAMETER SkillsPath
  Path to skills directory (default: .agents/skills).
.PARAMETER FailOnRisk
  Exit code 1 if risk score exceeds this threshold (0-100, default: 50).
  Use in CI: skillspector-gate.ps1 -FailOnRisk 30
#>
param(
    [string]$SkillsPath = ".agents/skills",
    [int]$FailOnRisk = 50
)

$ErrorActionPreference = "Stop"
$scriptName = "skillspector-gate"

# Resolve full path
$resolvedPath = Resolve-Path $SkillsPath -ErrorAction SilentlyContinue
if (-not $resolvedPath) {
    Write-Warning "${scriptName}: Path '$SkillsPath' not found — skipping"
    exit 0
}

# Check if skillspector CLI is available
$sp = Get-Command "skillspector" -ErrorAction SilentlyContinue
if (-not $sp) {
    Write-Host "⚪ SkillSpector not installed — skipping"
    Write-Host "   Install: pip install git+https://github.com/NVIDIA/SkillSpector.git"
    Write-Host "   Requires Python >=3.12,<3.14 (current: $(python --version 2>&1))"
    exit 0
}

Write-Host "🔍 Scanning skills with SkillSpector (static only)..."
$jsonOutput = & skillspector scan $resolvedPath --no-llm --format json 2>&1 | Out-String

if ($LASTEXITCODE -ne 0) {
    Write-Warning "${scriptName}: SkillSpector exited with code $LASTEXITCODE"
    Write-Host $jsonOutput
    exit 0  # non-blocking
}

# Parse risk score
try {
    $report = $jsonOutput | ConvertFrom-Json
    $riskScore = $report.risk_score
    $severity = $report.severity
    $findingsCount = ($report.findings | Measure-Object).Count

    Write-Host "   Risk score: $riskScore/100 ($severity)"
    Write-Host "   Findings: $findingsCount"

    if ($findingsCount -gt 0 -and $report.findings) {
        foreach ($f in $report.findings) {
            $f | Select-Object category, severity, description, file, line | Format-Table -AutoSize
        }
    }

    if ($riskScore -ge $FailOnRisk) {
        Write-Warning "⚠️ SkillSpector risk score $riskScore exceeds threshold $FailOnRisk"
        if ($FailOnRisk -le 0) { exit 1 }
    }

    if ($riskScore -ge 30) {
        Write-Host "   → Revisar hallazgos antes de commit. Para ignorar: skillspector-gate.ps1 -FailOnRisk $($riskScore + 1)"
    } else {
        Write-Host "   ✅ Skills clean (risk < 30)"
    }
}
catch {
    Write-Warning "${scriptName}: Could not parse SkillSpector output — skipping gate"
    Write-Host $jsonOutput
}

exit 0
