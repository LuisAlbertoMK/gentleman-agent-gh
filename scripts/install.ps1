#Requires -Version 5.1
<#
.SYNOPSIS Gentle-AI -- Windows installer. Channels: stable, beta, nightly.
.EXAMPLE irm https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.ps1 | iex
.EXAMPLE .\install.ps1 -Method binary -Channel beta -Insecure
#>
$ErrorActionPreference = "Stop"; Set-StrictMode -Version Latest
$null = & chcp 65001 2>$null
try{ [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 }catch{ Write-Verbose "install: Console encoding not settable" }

$owner = "Gentleman-Programming"; $repo = "gentle-ai"; $bin = "gentle-ai"

function i{param([string]$m)Write-Host "[info]    $m" -fo Blue}
function s{param([string]$m)Write-Host "[ok]      $m" -fo Green}
function w{param([string]$m)Write-Host "[warn]    $m" -fo Yellow}
function e{param([string]$m)Write-Host "[error]   $m" -fo Red}
function t{param([string]$m)Write-Host "`n==> $m" -fo Cyan}
function die{param([string]$m)e $m;exit 1}

function Get-Platform {
    t "Detecting platform"
    $a = if([Environment]::Is64BitOperatingSystem){if($env:PROCESSOR_ARCHITECTURE -eq "ARM64"){"arm64"}else{"amd64"}}else{die "32-bit Windows is not supported."}
    s "Platform: Windows ($a)"; return $a
}

function Test-Prerequisite {
    t "Checking prerequisites"
    $m = @()
    if(-not(Get-Command "curl" -ErrorAction SilentlyContinue)){$m+="curl"}
    if(-not(Get-Command "git" -ErrorAction SilentlyContinue)){$m+="git"}
    if($m.Count -gt 0){die "Missing required tools: $($m -join ', ')"}
    s "curl and git are available"
}

function Get-InstallMethod {
    param([string]$Forced,[string]$Channel)
    if($Channel -eq "beta"){
        if($Forced -ne "auto" -and $Forced -ne "go"){die "-Channel beta only supports -Method go"}
        i "Using beta channel -- will install from main via go install"; return "go"
    }
    if($Forced -ne "auto"){i "Using forced method: $Forced";return $Forced}
    t "Detecting best install method"; i "Will download pre-built binary from GitHub Releases"
    return "binary"
}

function Add-GoEnvPattern {
    param([string]$Name,[string]$Pattern)
    $c = [Environment]::GetEnvironmentVariable($Name,"Process")
    if(-not $c){Set-Item -Path "Env:$Name" -Value $Pattern;return}
    $p = $c.Split(",",[StringSplitOptions]::RemoveEmptyEntries).Trim()
    if($p -contains $Pattern){return}
    Set-Item -Path "Env:$Name" -Value ("{0},{1}" -f $Pattern,$c)
}

function Install-ViaGo {
    param([string]$Channel = "stable")
    t "Installing via go install"
    $v = if($Channel -eq "beta"){"main"}else{"latest"}
    $g = "github.com/$($owner.ToLower())/$repo/cmd/$bin@$v"
    i "Running: go install $g"
    if($Channel -eq "beta"){
        Add-GoEnvPattern -Name "GONOSUMDB" -Pattern "github.com/gentleman-programming/gentle-ai"
        Add-GoEnvPattern -Name "GOPRIVATE" -Pattern "github.com/gentleman-programming/gentle-ai"
        Add-GoEnvPattern -Name "GONOPROXY" -Pattern "github.com/gentleman-programming/gentle-ai"
    }
    & go install $g
    if($LASTEXITCODE -ne 0){die "Failed to install via go install."}
    $b = & go env GOBIN 2>$null
    if(-not $b){$p = & go env GOPATH 2>$null;$b = Join-Path $p "bin"}
    if($env:PATH -notlike "*$b*"){w "$b is not in your PATH";w "Add it to your PATH environment variable."}
    s "Installed $bin via go install"
}

function Get-LatestVersion {
    i "Fetching latest release from GitHub..."
    try{$r = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers @{"User-Agent"="gentle-ai-installer"}}catch{die "Failed to fetch latest release. Try -Method go"}
    $v = $r.tag_name
    if(-not $v){die "Could not determine latest version from GitHub API"}
    s "Latest version: $v";return $v
}

function Install-ViaBinary {
    param([string]$Arch)
    $Insecure = $false;$InstallDir = ""
    t "Installing pre-built binary"
    $v = Get-LatestVersion;$vn = $v.TrimStart("v")
    $zf = "${bin}_${vn}_windows_${Arch}.zip"
    $du = "https://github.com/$owner/$repo/releases/download/$v/$zf"
    $cu = "https://github.com/$owner/$repo/releases/download/$v/checksums.txt"
    $td = Join-Path $env:TEMP "gentle-ai-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $td -Force|Out-Null
    try{
        i "Downloading $zf..."
        $ap = Join-Path $td $zf
        Invoke-WebRequest -Uri $du -OutFile $ap -UseBasicParsing
        $fs = (Get-Item $ap).Length
        if($fs -lt 1000){die "Downloaded file is too small ($fs bytes)."}
        s "Downloaded $zf ($fs bytes)"
        i "Verifying checksum..."
        try{
            $cp = Join-Path $td "checksums.txt"
            Invoke-WebRequest -Uri $cu -OutFile $cp -UseBasicParsing
            $ln = (Get-Content $cp)|Where-Object{$_ -match $zf}
            if($ln){
                $ex = ($ln -split "\s+")[0]
                $ac = (Get-FileHash -Path $ap -Algorithm SHA256).Hash.ToLower()
                if($ac -ne $ex){die "Checksum mismatch!`n  Expected: $ex`n  Got:      $ac"}
                s "Checksum verified"
            }else{
                if($Insecure){w "Archive '$zf' not found in checksums.txt -- skipped (-Insecure)"}
                else{die "Archive '$zf' not found in checksums.txt. Use -Insecure to skip."}
            }
        }catch{
            if($Insecure){w "Could not download checksums.txt -- skipped (-Insecure)"}
            else{die "Could not download checksums.txt. Use -Insecure to skip."}
        }
        i "Extracting $bin..."
        Expand-Archive -Path $ap -DestinationPath $td -Force
        $bp = Join-Path $td "$bin.exe"
        if(-not(Test-Path $bp)){die "Binary '$bin.exe' not found in archive"}
        $id = $InstallDir
        if(-not $id){$id = Join-Path $env:LOCALAPPDATA "gentle-ai\bin"}
        if(-not(Test-Path $id)){New-Item -ItemType Directory -Path $id -Force|Out-Null}
        $dt = Join-Path $id "$bin.exe"
        i "Installing to $dt..."
        Copy-Item -Path $bp -Destination $dt -Force
        s "Installed $bin to $dt"
        $up = [Environment]::GetEnvironmentVariable("PATH","User")
        $en = if($up){$up -split ';'|Where-Object{$_ -ne ''}}else{@()}
        $pr = $en|Where-Object{$_.TrimEnd('\') -ieq $id.TrimEnd('\')}
        if(-not $pr){
            $np = if($up){"$up;$id"}else{$id}
            [Environment]::SetEnvironmentVariable("PATH",$np,"User")
            s "Added $id to your PATH (takes effect in new shells)"
        }
        $se = $env:PATH -split ';'|Where-Object{$_ -ne ''}
        $si = $se|Where-Object{$_.TrimEnd('\') -ieq $id.TrimEnd('\')}
        if(-not $si){$env:PATH = "$env:PATH;$id"}
    }finally{
        Remove-Item -Path $td -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Test-Installation {
    t "Verifying installation"
    $gp = $null
    if(Get-Command "go" -ErrorAction SilentlyContinue){$gp = & go env GOPATH 2>$null}
    $locs = @((Join-Path $env:LOCALAPPDATA "gentle-ai\bin\$bin.exe"))
    if($gp){$locs += (Join-Path $gp "bin\$bin.exe")}
    foreach($loc in $locs){
        if(-not($loc -and (Test-Path $loc))){continue}
        $env:GENTLE_AI_NO_SELF_UPDATE = "1"
        $vo = & $loc --version 2>&1
        Remove-Item Env:GENTLE_AI_NO_SELF_UPDATE -ErrorAction SilentlyContinue
        s "$bin installed at $loc`: $vo"
        $up = [Environment]::GetEnvironmentVariable("PATH","User")
        $bd = [System.IO.Path]::GetDirectoryName($loc)
        if($up -notlike "*$bd*"){w "Binary location is not in your PATH."}
        return
    }
    w "Could not verify installation. You may need to restart your terminal."
}

function Show-NextStep {
    param([string]$Channel = "stable")
    Write-Host "`nInstallation complete!`n" -fo Green
    Write-Host "Next steps:" -fo White
    if($Channel -eq "beta"){
        Write-Host ('  1. Run ''$env:GENTLE_AI_CHANNEL = "beta"; {0} install'' to keep using the beta channel' -f $bin) -fo Cyan
    }else{
        Write-Host "  1. Run '$bin' to start the TUI installer" -fo Cyan
    }
    Write-Host "  2. Select your AI agent(s) and tools to configure" -fo Cyan
    Write-Host "  3. Follow the interactive prompts" -fo Cyan
    Write-Host "`nFor help: $bin --help" -fo DarkGray
    Write-Host "Docs:     https://github.com/$owner/$repo" -fo DarkGray
    Write-Host ""
}

function Main {
    [CmdletBinding()]param(
        [ValidateSet("auto","go","binary")][string]$Method = "auto",
        [ValidateSet("stable","beta","nightly")][string]$Channel = $(if($env:GENTLE_AI_CHANNEL){$env:GENTLE_AI_CHANNEL}else{"stable"}),
        [string]$InstallDir = "",
        [switch]$Insecure
    )
    $null = $InstallDir, $Insecure
    Write-Host ""
    Write-Host "   ____            _   _              _    ___ " -fo Cyan
    Write-Host "  / ___| ___ _ __ | |_| | ___        / \  |_ _|" -fo Cyan
    Write-Host " | |  _ / _ \ '_ \| __| |/ _ \_____ / _ \  | | " -fo Cyan
    Write-Host " | |_| |  __/ | | | |_| |  __/_____/ ___ \ | | " -fo Cyan
    Write-Host "  \____|\___|_| |_|\__|_|\___|    /_/   \_\___|" -fo Cyan
    Write-Host ""
    Write-Host "  Gentle-AI -- Ecosystem, Frameworks, Workflows" -fo DarkGray
    Write-Host ""
    $arch = Get-Platform
    Test-Prerequisite
    if($Channel -eq "nightly"){$Channel = "beta"}
    $m = Get-InstallMethod -Forced $Method -Channel $Channel
    switch($m){"go"{Install-ViaGo -Channel $Channel}"binary"{Install-ViaBinary -Arch $arch}}
    Test-Installation
    Show-NextStep -Channel $Channel
}
Main @args
