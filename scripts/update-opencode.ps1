#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Update and self-heal the opencode npm binary — guarded against startup auto-upgrade races.
.DESCRIPTION
    Resolves the opencode.exe location via `npm prefix -g`, tests the binary via --version,
    optionally updates via npm, then heals a corrupt PE by re-running postinstall.mjs.

    NOTE: This script is user-facing — agents have npm/pwsh deny rules; intended to run
    in a user terminal or via scripts/sync-global.ps1 (Step 7). Do not invoke from an
    agent session that would be killed by -StopProcesses.
.PARAMETER HealOnly   Skip npm update; only test + heal if corrupt.
.PARAMETER StopProcesses  Opt-in: stop running opencode processes before replacement.
.PARAMETER Version    npm dist-tag or version (default: latest).
.PARAMETER Json       Output machine-readable report as JSON.
#>
param([switch]$HealOnly,[switch]$StopProcesses,[string]$Version="latest",[switch]$Json)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest
$report=@{timestamp=(Get-Date -Format "o");steps=@{};errors=@();warnings=@();status="ok";healed=$false;before_version=$null;after_version=$null}
function Invoke-Npm { param([Parameter(ValueFromRemainingArguments=$true)]$a) & npm @a }
function Invoke-Node { param([Parameter(ValueFromRemainingArguments=$true)]$a) & node @a }
# Resolve npm global prefix
$prefix=$null; try{ $raw=Invoke-Npm prefix -g 2>$null | Select-Object -Last 1; if($raw){ $prefix=$raw.Trim() } if(-not $prefix -or -not (Test-Path $prefix)){ throw "empty prefix" } }catch{ $prefix=Join-Path $env:APPDATA "npm" }
$exe=Join-Path $prefix "node_modules\opencode-ai\bin\opencode.exe"
$postinstall=Join-Path $prefix "node_modules\opencode-ai\postinstall.mjs"
$report["postinstall_path"]=$postinstall
function Test-Binary {
    if(-not (Test-Path -LiteralPath $exe)){ return $null }
    try{ $out=& $exe --version 2>&1 | Out-String; $code=$LASTEXITCODE; $t=$out.Trim()
        if($code -eq 0 -and $t -match '^\d+\.\d+\.\d+'){ return $Matches[0] }
        if($code -eq 0 -and $t -match '(\d+\.\d+\.\d+)'){ return $Matches[1] }
        return $null
    }catch{ return $null }
}
# Step: Detect running instances
try{
    $procs=Get-Process opencode -EA SilentlyContinue
    $ids=@(); if($procs){ $ids=@($procs | Select-Object -ExpandProperty Id) }
    if($ids.Count -gt 0){
        if($StopProcesses){
            $stopped=0; foreach($id in $ids){ try{ Stop-Process -Id $id -Force -EA SilentlyContinue; $stopped++ }catch{ Write-Verbose "pid $id already stopped" } }
            $report.steps["detect"]=@{running=$ids.Count;stopped=$stopped;ids=$ids}
            $report.warnings+="Stopped $stopped opencode instance(s) via -StopProcesses"
        } else {
            $report.steps["detect"]=@{running=$ids.Count;ids=$ids}
            $msg="$($ids.Count) opencode instance(s) running — binary replacement may race; pass -StopProcesses to stop them first"
            $report.warnings+=$msg; if(-not $Json){ Write-Warning "  $msg" }
        }
    } else { $report.steps["detect"]=@{running=0} }
}catch{ $report.warnings+="detect step failed: $_"; $report.steps["detect"]="warn: $_" }
# Record before version
$before=Test-Binary; $report.before_version=$before
# Step: Update (skip if HealOnly)
if($HealOnly){
    $report.steps["update"]="skipped"
} else {
    try{
        if(-not $Json){ Write-Host "==> npm i -g opencode-ai@$Version" -Fore Cyan }
        if($PSCmdlet.ShouldProcess("opencode-ai@$Version","npm i -g")){
            if($Json){ & npm i -g "opencode-ai@$Version" 2>&1 | Out-Null } else { & npm i -g "opencode-ai@$Version" }
            if($LASTEXITCODE -ne 0){ throw "npm exit $LASTEXITCODE" }
        }
        $report.steps["update"]=@{version=$Version;status="ok"}
    }catch{ $report.errors+="update failed: $_"; $report.steps["update"]="fail: $_"; $report.status="fail" }
}
# Step: Heal
$healed=$false; $after=$before
if($null -eq (Test-Binary)){
    $attempt=0; $maxAttempts=2
    while($attempt -lt $maxAttempts){
        $attempt++
        try{
            if(-not $Json){ Write-Host "  [heal] attempt $attempt/$maxAttempts — node $postinstall" -Fore Yellow }
            $job=Start-Job -ScriptBlock { & node $using:postinstall 2>&1 | Out-Null }
            if(Wait-Job $job -Timeout 180){ Remove-Job $job -Force } else { Stop-Job $job; Remove-Job $job -Force; throw "postinstall timeout after 180s" }
            Start-Sleep -Seconds 2
            $probe=Test-Binary
            if($null -ne $probe){ $healed=$true; $after=$probe; break }
        }catch{ if(-not $Json){ Write-Warning "  heal attempt $attempt failed: $_" } }
        if($attempt -lt $maxAttempts){ Start-Sleep -Seconds 5 }
    }
    $after=Test-Binary
    $report.healed=$healed; $report.after_version=$after
    $report.steps["heal"]=@{healed=$healed;version=$after;attempts=$attempt}
    if($null -eq $after){ $report.warnings+="heal did not restore binary after $maxAttempts attempts" }
} else {
    $report.healed=$false; $report.after_version=$after; $report.steps["heal"]=@{healed=$false;version=$after;skipped="binary healthy"}
}
# Ensure after_version reflects final probe if not set
if($null -eq $report.after_version){ $report.after_version=Test-Binary }
# Step: Verify
$final=Test-Binary
if($null -eq $final){
    $report.status="fail"
    $hint="manual remediation: node `"$postinstall`""
    $report.errors+=$hint; $report.errors+="opencode binary still corrupt after heal"
    $report.steps["verify"]="fail"
    if($Json){ $report | ConvertTo-Json -Depth 5 | Write-Output; exit 1 }
    Write-Host "[fail] opencode binary still corrupt — $hint" -Fore Red; exit 1
} else {
    $report.after_version=$final; $report.status=if($report.status -eq "fail"){"fail"}else{"ok"}
    $report.steps["verify"]=@{version=$final;status="ok"}
}
if($Json){ $report | ConvertTo-Json -Depth 5 | Write-Output; exit $(if($report.status -eq "ok"){0}else{1}) }
Write-Host "`n=== update-opencode | Status: $($report.status) | $($report.after_version) healed=$($report.healed) ===" -Fore $(if($report.status -eq "ok"){"Green"}else{"Red"})
exit $(if($report.status -eq "ok"){0}else{1})
