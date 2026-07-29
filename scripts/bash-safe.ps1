#requires -Version 5.1
Set-StrictMode -Version Latest
<#
.SYNOPSIS
    Bash-syntax safe executor for PowerShell 5.1 environments.
.DESCRIPTION
    PowerShell 5.1 does NOT support &&, ||, or @{var} hash literals.
    Git Bash at "C:\Program Files\Git\bin\bash.exe" is the working interpreter.
    This script provides Invoke-Bash that delegates to Git Bash.
.EXAMPLE
    . "$PSScriptRoot\bash-safe.ps1"
    Invoke-Bash "git status --short && git log --oneline -5"
.NOTES
    Self-test: run Test-BashSafe after dot-sourcing.
#>

# Locate real bash interpreter — check 4 common locations + PATH fallback
$script:GitBash = $null
$bashCandidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe"
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    "$env:ChocolateyInstall\lib\git\tools\bin\bash.exe"
)
foreach ($c in $bashCandidates) { if (Test-Path $c) { $script:GitBash = $c; break } }
if (-not $script:GitBash) { $script:GitBash = (Get-Command bash -ErrorAction SilentlyContinue).Source }
if (-not $script:GitBash -or -not (Test-Path $script:GitBash)) { throw "No bash interpreter found. Install Git for Windows or WSL." }

# Server command patterns + default ports
$script:ServerPatterns = @(
    '^\s*ng\s+serve', '^\s*npm\s+run\s+(dev|start|serve)', '^\s*yarn\s+(dev|start|serve)',
    '^\s*pnpm\s+run\s+(dev|start|serve)', '^\s*dotnet\s+run', '^\s*python\s+-m\s+http\.server',
    '^\s*python\s+.*server\.py', '^\s*node\s+.*server\.(js|ts)', '^\s*npx\s+.*serve',
    '^\s*jekyll\s+serve', '^\s*hugo\s+server', '^\s*vite(\s|$)', '^\s*webpack-dev-server',
    '^\s*ts-node\s+.*server'
)
$script:ServerDefaultPorts = @(
    @{ pattern = '^\s*ng\s+serve'; port = 4200 }, @{ pattern = '^\s*vite'; port = 5173 },
    @{ pattern = '^\s*webpack-dev-server'; port = 8080 }, @{ pattern = '^\s*jekyll\s+serve'; port = 4000 },
    @{ pattern = '^\s*hugo\s+server'; port = 1313 }, @{ pattern = '^\s*python\s+-m\s+http\.server'; port = 8000 },
    @{ pattern = '^\s*dotnet\s+run'; port = 5000 }, @{ pattern = '^\s*(npm|yarn|pnpm)\s+run\s+dev'; port = 3000 }
)

# Detect if command matches known server patterns
function Test-IsServerCommand {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)
    foreach ($pattern in $script:ServerPatterns) { if ($Command -match $pattern) { return $true } }
    return $false
}

# Extract port from server command, or return default
function Get-ServerPort {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)
    if ($Command -match '--port[= ](\d+)') { return [int]$Matches[1] }
    if ($Command -match '(?:^|\s)-p\s+(\d+)') { return [int]$Matches[1] }
    if ($Command -match ':(\d{4,5})(?:\s|$)') { return [int]$Matches[1] }
    if ((Test-IsServerCommand $Command) -and ($Command -match '(\d{4,5})$')) { return [int]$Matches[1] }
    foreach ($entry in $script:ServerDefaultPorts) { if ($Command -match $entry.pattern) { return $entry.port } }
    return $null
}

# Check if TCP port is in use on localhost (uses TcpClient, no module dependency)
function Test-PortInUse {
    [CmdletBinding()]
    param([Parameter(Mandatory)][int]$Port)
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $ar = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $ok = $ar.AsyncWaitHandle.WaitOne(1000, $false)
        if ($ok) { $client.EndConnect($ar); $client.Close(); return $true }
        $client.Close(); return $false
    } catch { return $false }
}

# SECURITY: Validate that a command string contains no injection vectors.
# bash -c interprets the entire string — backticks and $() execute arbitrary
# code inside the bash invocation. This function rejects commands that contain
# bash command substitution patterns, which are the real injection risk.
# NOTE: quotes (single/double) are normal bash syntax and are NOT rejected.
# The background path escapes " to \" to prevent quote-breaking.
function Test-SafeCommand {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Command)

    # Reject $() subshell expansion — executes arbitrary code inside bash.
    if ($Command -match '\$\(') {
        Write-Warning "[bash-safe] SECURITY: command contains $() subshell — refusing to execute."
        return $false
    }

    # Reject backtick command substitution — same risk as $().
    if ($Command -match '`') {
        Write-Warning "[bash-safe] SECURITY: command contains backtick — refusing to execute."
        return $false
    }

    # Reject process substitution <(...) — spawns subprocesses outside caller control.
    if ($Command -match '<\(') {
        Write-Warning "[bash-safe] SECURITY: command contains process substitution <(... ) — refusing to execute."
        return $false
    }

    # Reject process substitution >(...) — same risk.
    if ($Command -match '>\(') {
        Write-Warning "[bash-safe] SECURITY: command contains process substitution >(... ) — refusing to execute."
        return $false
    }

    # Reject ANSI-C quoting $'...' — can embed arbitrary escape sequences.
    if ($Command -match "\\\$'") {
        Write-Warning "[bash-safe] SECURITY: command contains ANSI-C quoting \$'...' — refusing to execute."
        return $false
    }

    # Reject bash -c passthrough — nested shell invocation bypasses this layer.
    if ($Command -match 'bash\s+-c\s') {
        Write-Warning "[bash-safe] SECURITY: command contains bash -c passthrough — refusing to execute."
        return $false
    }

    # Reject eval — arbitrary code execution. Block as standalone command or via control operators.
    if ($Command -match '(^|;|&&|\|\||\|)\s*eval(\s|$)') {
        Write-Warning "[bash-safe] SECURITY: command contains eval — refusing to execute."
        return $false
    }

    # Reject exec as standalone command (not subcommand like `docker exec` or `kubectl exec`).
    if ($Command -match '(^|;|&&|\|\||\|)\s*exec(\s|$)') {
        Write-Warning "[bash-safe] SECURITY: command contains exec — refusing to execute."
        return $false
    }

    # Reject source — loads arbitrary script into current shell.
    # NOTE: `. ` not blocked — too many false positives (find ., git -C ., ls .).
    if ($Command -match '(^|;|&&|\|\||\|)\s*source(\s|$)') {
        Write-Warning "[bash-safe] SECURITY: command contains source — refusing to execute."
        return $false
    }

    # Reject alias — can override builtins.
    if ($Command -match '(^|;|&&|\|\||\|)\s*alias(\s|$)') {
        Write-Warning "[bash-safe] SECURITY: command contains alias — refusing to execute."
        return $false
    }

    # Reject declare/typeset -f — can dump function source.
    if ($Command -match '(declare|typeset)\s+(-f|-F)') {
        Write-Warning "[bash-safe] SECURITY: command contains declare/typeset -f — refusing to execute."
        return $false
    }

    return $true
}

# Main entry point — invoke command via Git Bash
# SECURITY MODEL:
#   - The $Command parameter is passed to `bash -c` as a SINGLE argument.
#   - Sync paths (lines below) are safe: PowerShell passes $Command as a
#     single argv element to the bash process — no re-interpretation.
#   - The background path builds a ProcessStartInfo.Arguments string, which
#     IS vulnerable to quote-breaking if $Command contains double-quotes.
#     We escape " → \" to prevent this.
#   - Callers MUST NOT interpolate user input into $Command. Always use
#     string literals or pre-validated strings.
function Invoke-Bash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$Command,
        [switch]$CaptureOutput,
        [switch]$Background
    )
    $ErrorActionPreference = 'Continue'

    # Input validation — reject commands that look like injection attempts
    if (-not (Test-SafeCommand $Command)) {
        if ($CaptureOutput) { return [PSCustomObject]@{ Output = @(); ExitCode = 126 } }
        throw "Invoke-Bash: command rejected by security validation. See warnings above."
    }

    # Server command detection — warn if launched without -Background
    $isServer = Test-IsServerCommand $Command
    if ($isServer -and -not $Background) {
        Write-Warning "[bash-safe] '$($Command -replace '^(.{55}).*', '$1…')' parece un SERVIDOR (nunca termina)."
        Write-Warning "[bash-safe]   Usá -Background: Invoke-Bash '$($Command -replace "'","''")' -Background"
        Write-Warning "[bash-safe]   O dev-server.ps1: .\scripts\dev-server.ps1 -Action Start -Name <name> -Command $($script:GitBash) -Arguments '-c ""$($Command -replace '"','""')""'"
    }
    if ($isServer) {
        $port = Get-ServerPort $Command
        if ($port) {
            $inUse = Test-PortInUse $port
            if ($inUse -eq $true) {
                Write-Warning "[bash-safe] Puerto $port ya está EN USO — otro servidor está corriendo ahí."
                Write-Warning "[bash-safe]   Descubrí quién: Get-Process -Id ((Get-NetTCPConnection -LocalPort $port).OwningProcess)"
                Write-Warning "[bash-safe]   O usá un puerto distinto: --port <otro>"
            } elseif ($inUse -eq $null) { Write-Warning "[bash-safe] No se pudo verificar si el puerto $port está ocupado." }
        }
    }

    if ($Background) {
        # SECURITY: Escape backslashes first, then double-quotes, then dollar
        # signs and backticks. Order matters: if we escaped quotes first, a
        # trailing \ before " would produce \" which bash interprets as an
        # escaped quote, not backslash+quote. Dollar signs and backticks are
        # special to Windows cmd.exe when passed through ProcessStartInfo.
        $escapedCommand = $Command -replace '\\', '\\\\' -replace '"', '\"' -replace '\$', '`$'
        $psi = [System.Diagnostics.ProcessStartInfo]@{
            FileName = $script:GitBash; Arguments = "-c `"$escapedCommand`""
            UseShellExecute = $false; CreateNoWindow = $true
        }
        try {
            $p = [System.Diagnostics.Process]::Start($psi)
            $msg = "[background] PID $($p.Id): $Command"
            if ($CaptureOutput) { return [PSCustomObject]@{ Output = @($msg); ExitCode = 0 } }
            Write-Host "[bash-safe] Background PID $($p.Id): $Command" -ForegroundColor Green
            return
        } catch {
            Write-Error "[bash-safe] Error starting background process: $_"
            if ($CaptureOutput) { return [PSCustomObject]@{ Output = @(); ExitCode = 1 } }
            return
        }
    }

    # Synchronous behavior — safe: PowerShell passes $Command as a single
    # argument to bash, no shell re-interpretation happens on the PS side.
    if ($CaptureOutput) {
        $output = & $script:GitBash -c $Command 2>&1
        return [PSCustomObject]@{ Output = $output; ExitCode = $LASTEXITCODE }
    } else {
        & $script:GitBash -c $Command
        if ($LASTEXITCODE -ne 0) { Write-Warning "Invoke-Bash exit=$LASTEXITCODE : $Command" }
    }
}

# Self-test runners
function Test-BashSafe {
    $tests = @(
        @{ Name = "[1] && operator"; Cmd = "echo a && echo b"; Pattern = 'a\s*b' }
        @{ Name = "[2] || operator"; Cmd = "false || echo fallback"; Pattern = 'fallback' }
        @{ Name = "[3] @{u} hash literal"; Cmd = "git log @{u}.. --oneline 2>&1; echo END"; Pattern = 'END'; ExitOk = $true }
        @{ Name = "[4] 2>&1 redirect"; Cmd = "echo err 1>&2; echo out"; Pattern = 'err.*out' }
        @{ Name = "[5] pipeline + grep"; Cmd = "echo -e 'foo\nbar\nbaz' | grep ba"; Pattern = 'bar' }
        @{ Name = "[6] git --version"; Cmd = "git --version"; Pattern = 'git version' }
    )
    foreach ($t in $tests) {
        Write-Host "$($t.Name)..." -NoNewline
        $r = Invoke-Bash $t.Cmd -CaptureOutput
        $ok = if ($t.Pattern) { ($r.Output -join '') -match $t.Pattern } else { $true }
        if ($t.ExitOk) { $ok = $r.ExitCode -eq 0 -and $ok }
        Write-Host $(if ($ok) { " OK" } else { " FAIL" }) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
    }
}

function Test-SecurityValidation {
    $safe = @(
        @{ Name = "[SEC1] plain command"; Cmd = "echo hello" }
        @{ Name = "[SEC2] && chaining"; Cmd = "echo a && echo b" }
        @{ Name = "[SEC3] pipeline"; Cmd = "cat file | grep pattern" }
        @{ Name = "[SEC4] semicolons"; Cmd = "echo a; echo b" }
        @{ Name = "[SEC5] env vars (PS side)"; Cmd = "echo $HOME" }
        @{ Name = "[SEC6] single quotes (bash syntax)"; Cmd = "echo 'hello world'" }
        @{ Name = "[SEC7] double quotes (bash syntax)"; Cmd = 'echo "hello world"' }
        @{ Name = "[SEC8] escaped dollar"; Cmd = 'echo \$HOME' }
        @{ Name = "[SEC15] docker exec (subcommand, safe)"; Cmd = 'docker exec -it bash' }
        @{ Name = "[SEC16] kubectl exec (subcommand, safe)"; Cmd = 'kubectl exec pod -- ls' }
        @{ Name = "[SEC17] find . (dot arg, safe)"; Cmd = 'find . -name "*.txt"' }
        @{ Name = "[SEC18] git config alias (word, safe)"; Cmd = 'git config alias.st status' }
        @{ Name = "[SEC19] eval as text (safe)"; Cmd = 'echo "setup: eval v1.0"' }
        @{ Name = "[SEC20] source as text (safe)"; Cmd = 'echo "source file loaded"' }
        @{ Name = "[SEC21] ls . (dot arg, safe)"; Cmd = 'ls .' }
        @{ Name = "[SEC22] source inside git (text, safe)"; Cmd = 'git -C . log --oneline' }
    )
    $unsafe = @(
        @{ Name = "[SEC9] backtick injection"; Cmd = "echo `$(whoami)" }
        @{ Name = "[SEC10] subshell injection"; Cmd = 'echo $(whoami)' }
        @{ Name = "[SEC11] process substitution <("; Cmd = 'diff <(echo a) <(echo b)' }
        @{ Name = "[SEC12] process substitution >("; Cmd = 'echo x > >()' }
        @{ Name = "[SEC13] ANSI-C quoting"; Cmd = "echo \$'\\x48'" }
        @{ Name = "[SEC14] bash -c passthrough"; Cmd = 'bash -c "echo pwned"' }
        @{ Name = "[SEC23] eval standalone"; Cmd = 'eval ls' }
        @{ Name = "[SEC24] eval after pipe"; Cmd = 'echo x | eval ls' }
        @{ Name = "[SEC25] exec standalone"; Cmd = 'exec ls -la' }
        @{ Name = "[SEC26] source standalone"; Cmd = 'source /etc/profile' }
        @{ Name = "[SEC27] alias definition"; Cmd = 'alias ll="ls -la"' }
        @{ Name = "[SEC28] declare -f dump"; Cmd = 'declare -f myfunc' }
        @{ Name = "[SEC29] typeset -f dump"; Cmd = 'typeset -f myfunc' }
        @{ Name = "[SEC30] eval after semicolon"; Cmd = 'echo a; eval whoami' }
        @{ Name = "[SEC31] source after AND"; Cmd = 'echo a && source secrets.sh' }
        @{ Name = "[SEC32] exec after OR"; Cmd = 'false || exec /bin/sh' }
    )
    foreach ($t in $safe) {
        Write-Host "$($t.Name)..." -NoNewline
        $ok = Test-SafeCommand $t.Cmd
        Write-Host $(if ($ok) { " OK (safe allowed)" } else { " FAIL (safe rejected)" }) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
    }
    foreach ($t in $unsafe) {
        Write-Host "$($t.Name)..." -NoNewline
        $ok = -not (Test-SafeCommand $t.Cmd)
        Write-Host $(if ($ok) { " OK (unsafe blocked)" } else { " FAIL (unsafe passed)" }) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
    }
}

function Test-ServerDetection {
    $tests = @(
        @{ Name = "[S1] ng serve"; Cmd = "ng serve"; Expected = $true }
        @{ Name = "[S2] npm run dev"; Cmd = "npm run dev"; Expected = $true }
        @{ Name = "[S3] npm run build (NO)"; Cmd = "npm run build"; Expected = $false }
        @{ Name = "[S4] dotnet run"; Cmd = "dotnet run"; Expected = $true }
        @{ Name = "[S5] git status (NO)"; Cmd = "git status"; Expected = $false }
        @{ Name = "[S6] python -m http.server"; Cmd = "python -m http.server 8080"; Expected = $true }
        @{ Name = "[S7] vite"; Cmd = "vite"; Expected = $true }
        @{ Name = "[S8] echo hello (NO)"; Cmd = "echo hello"; Expected = $false }
    )
    foreach ($t in $tests) {
        Write-Host "$($t.Name)..." -NoNewline
        $r = Test-IsServerCommand $t.Cmd
        $ok = $r -eq $t.Expected
        Write-Host $(if ($ok) { " OK" } else { " FAIL" }) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
    }
}

function Test-PortDetection {
    $tests = @(
        @{ Name = "[P1] ng serve → 4200"; Cmd = "ng serve"; Expected = 4200 }
        @{ Name = "[P2] ng serve --port 4300"; Cmd = "ng serve --port 4300"; Expected = 4300 }
        @{ Name = "[P3] npm run dev → 3000"; Cmd = "npm run dev"; Expected = 3000 }
        @{ Name = "[P4] python 8080"; Cmd = "python -m http.server 8080"; Expected = 8080 }
        @{ Name = "[P5] vite --port 5173"; Cmd = "vite --port 5173"; Expected = 5173 }
        @{ Name = "[P6] git status → null"; Cmd = "git status"; Expected = $null }
        @{ Name = "[P7] dotnet run → 5000"; Cmd = "dotnet run"; Expected = 5000 }
        @{ Name = "[P8] jekyll 4000"; Cmd = "jekyll serve --port 4000"; Expected = 4000 }
    )
    foreach ($t in $tests) {
        Write-Host "$($t.Name)..." -NoNewline
        $p = Get-ServerPort $t.Cmd
        $ok = $p -eq $t.Expected
        Write-Host $(if ($ok) { " OK" } else { " FAIL ($p)" }) -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
    }
}

# Auto-discover GENTLEMAN_AGENT_ROOT on dot-source (via junction)
$__dir = Split-Path $MyInvocation.MyCommand.Path -Parent
$__item = Get-Item $__dir
if ($__item.LinkType -eq "Junction" -and $__item.Target) {
    $env:GENTLEMAN_AGENT_ROOT = (Split-Path $__item.Target -Parent).Replace('\', '/')
}

# Self-test if run directly
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand.Path -eq $PSCommandPath) {
    Write-Host "Using: $script:GitBash" -ForegroundColor Cyan
    Test-SecurityValidation; Write-Host ""
    Test-BashSafe; Write-Host ""
    Test-ServerDetection; Write-Host ""
    Test-PortDetection
}
