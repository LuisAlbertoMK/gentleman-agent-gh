#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter()][ValidateSet('ROJA','AMARILLA')]$Zone = 'ROJA',
    [Parameter()][int]$Rounds = 0,
    [Parameter()][switch]$FastPath,
    [Parameter()][switch]$RepeatFinding,
    [Parameter()][string]$RepoRoot = (Get-Location).Path,
    [Parameter()][switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$selfConsistency = 'SELF-CONSISTENCY: profiles A/B = majority-of-2 (diverge → tie-break by higher severity)'
$constitutionalLine = 'CONSTITUTIONAL → register via immune-system (.agents/skills/immune-system)'
$askUserLine = 'ASK-USER (Reflexion cap)'
$escalateLine = 'ESCALATE dual-judge'

$isCapped = $Rounds -gt 2

# Resolve fast exe path: honor env override ONLY when PESTER_TEST=1, otherwise always repo bin/fast.exe
$fastExeOverride = $env:JD_FAST_EXE
if ($env:PESTER_TEST -eq '1' -and $fastExeOverride -and $fastExeOverride.Trim() -ne '') {
    $fastExe = $fastExeOverride.Trim()
} else {
    $fastExe = Join-Path $RepoRoot 'bin/fast.exe'
}

function Test-ExeSanity {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item -is [System.IO.FileInfo] -and $item.Length -gt 0) { return $true }
        if ($item -is [System.IO.DirectoryInfo]) { return $false }
        return $item.Length -gt 0
    } catch { return $false }
}

function Invoke-FastGate {
    param([string]$ExePath)
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        if ($ExePath -like '*.ps1') {
            $psi.FileName = 'pwsh'
            $psi.Arguments = "-NoProfile -File `"$ExePath`" --gate --json"
        } elseif ($ExePath -like '*.cmd' -or $ExePath -like '*.bat') {
            $psi.FileName = 'cmd'
            $psi.Arguments = "/c `"$ExePath`" --gate --json"
        } else {
            $psi.FileName = $ExePath
            $psi.Arguments = '--gate --json'
        }
        $proc = [System.Diagnostics.Process]::new()
        $proc.StartInfo = $psi
        [void]$proc.Start()
        $exited = $proc.WaitForExit(5000)
        if (-not $exited) {
            try { $proc.Kill() } catch { Write-Debug "what failed: $($_.Exception.Message)" }
            [Console]::Error.WriteLine('WARN: fast.exe timeout after 5000ms')
            return $null
        }
        $stdout = $proc.StandardOutput.ReadToEnd()
        # Read stderr to avoid deadlock (already exited)
        [void]$proc.StandardError.ReadToEnd()
        if (-not $stdout -or $stdout.Trim() -eq '') { return $null }
        try {
            $parsed = $stdout | ConvertFrom-Json -ErrorAction Stop
            return $parsed
        } catch {
            return $null
        }
    } catch {
        return $null
    }
}

function Get-FastPathResult {
    param([string]$ExePath)
    $sanity = Test-ExeSanity -Path $ExePath
    if (-not $sanity) {
        return [ordered]@{ ran = $true; passed = $false; elapsedMs = $null; decision = 'ESCALATE'; sanityFailed = $true }
    }
    $result = Invoke-FastGate -ExePath $ExePath
    if ($null -eq $result) {
        return [ordered]@{ ran = $true; passed = $null; elapsedMs = $null; decision = 'ESCALATE'; sanityFailed = $false }
    }
    $passed = $null
    $elapsedMs = $null
    if ($result -and $result.PSObject.Properties['passed']) { $passed = [bool]$result.passed }
    if ($result -and $result.PSObject.Properties['elapsedMs']) { $elapsedMs = [int]$result.elapsedMs }
    elseif ($result -and $result.PSObject.Properties['elapsed']) { $elapsedMs = [int]$result.elapsed }
    $decision = 'ESCALATE'
    if ($passed -eq $true -and $null -ne $elapsedMs -and $elapsedMs -le 162) {
        $decision = 'VERIFY-OK'
    }
    return [ordered]@{ ran = $true; passed = $passed; elapsedMs = $elapsedMs; decision = $decision; sanityFailed = $false }
}

# Capped path — highest priority
if ($isCapped) {
    if ($Json) {
        $fastRanJson = $FastPath.IsPresent
        $obj = [ordered]@{
            verifier     = 'jd-verifier'
            zone         = $Zone
            fastPath     = [ordered]@{
                ran       = [bool]$fastRanJson
                passed    = $null
                elapsedMs = $null
                decision  = 'NOT_RUN'
            }
            rounds       = [ordered]@{
                value  = $Rounds
                capped = $true
            }
            constitutional = [bool]$RepeatFinding.IsPresent
            timestamp    = (Get-Date -Format 'o')
        }
        $obj | ConvertTo-Json -Depth 4 -Compress | Write-Output
        exit 2
    } else {
        Write-Output $selfConsistency
        Write-Output $askUserLine
        exit 2
    }
}

# Non-capped path
if ($Json) {
    $fastRan = $false
    $fastPassed = $null
    $fastElapsed = $null
    $fastDecision = 'NOT_RUN'
    if ($FastPath.IsPresent) {
        $fp = Get-FastPathResult -ExePath $fastExe
        $fastRan = [bool]$fp.ran
        # JSON-mode missing exe → passed=$false per spec (sanityFailed case already $false)
        if ($fp.sanityFailed) {
            $fastPassed = $false
            $fastElapsed = $null
            $fastDecision = 'ESCALATE'
        } else {
            $fastPassed = $fp.passed
            $fastElapsed = $fp.elapsedMs
            $fastDecision = $fp.decision
        }
    }
    $obj = [ordered]@{
        verifier     = 'jd-verifier'
        zone         = $Zone
        fastPath     = [ordered]@{
            ran       = [bool]$fastRan
            passed    = $fastPassed
            elapsedMs = $fastElapsed
            decision  = $fastDecision
        }
        rounds       = [ordered]@{
            value  = $Rounds
            capped = $false
        }
        constitutional = [bool]$RepeatFinding.IsPresent
        timestamp    = (Get-Date -Format 'o')
    }
    $obj | ConvertTo-Json -Depth 4 -Compress | Write-Output
    if ($fastDecision -eq 'ESCALATE') { exit 1 }
    exit 0
}

# Textual mode (no -Json)
Write-Output $selfConsistency

if ($RepeatFinding.IsPresent) {
    Write-Output $constitutionalLine
}

if ($FastPath.IsPresent) {
    $fp = Get-FastPathResult -ExePath $fastExe
    if ($fp.sanityFailed) {
        [Console]::Error.WriteLine("WARN: bin/fast.exe not found at $fastExe")
        Write-Output $escalateLine
        exit 1
    }
    if ($fp.decision -eq 'VERIFY-OK') {
        Write-Output "VERIFY-OK mechanical ($($fp.elapsedMs)ms)"
        exit 0
    } else {
        Write-Output $escalateLine
        exit 1
    }
}

exit 0
