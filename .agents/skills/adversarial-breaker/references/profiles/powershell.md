# PowerShell Attack Profile

## When to Load
`.ps1`, `.psm1`, `.psd1` files with logic (not pure manifests).

## Language-Specific Vectors

### Command Injection
- `Invoke-Expression` / `iex` — unsanitized string input?
- `Invoke-Command` — remote execution params injectable?
- `Start-Process` — args not validated?
- `&` call operator — command string from user input?
- `[System.Diagnostics.Process]::Start()` — unvalidated args?

### Path Manipulation
- `Join-Path` — user component can escape via `..\`?
- `Resolve-Path` — follows symlinks to sensitive areas?
- `Get-ChildItem` — path filter from user input?
- `Set-Location` — user-controlled path?
- Relative paths vs `$PSScriptRoot` — module-relative safety?

### Code Execution
- `Invoke-Command` — script block from string?
- `Add-Type` — inline C# from user input?
- `[ScriptBlock]::Create()` — dynamic code?
- `Get-Command` / `& $variable` — indirect execution?
- Module autoloading — can user force-load a malicious module?

### SSRF / Network
- `Invoke-WebRequest` / `Invoke-RestMethod` — URL from config or user input? SSRF to internal endpoints (169.254.169.254, localhost)?
- `WebClient.DownloadString()` — unsanitized URL?
- `$PSDefaultParameterValues` — redirect `Invoke-WebRequest` to attacker proxy?

### Code Execution (Dynamic)
- `$ExecutionContext.InvokeCommand.InvokeScript()` — dynamic script block from string?
- `New-Object -ComObject` — COM objects allow privilege escalation?
- `[System.Reflection.Assembly]::Load()` — arbitrary .NET assembly load?
- `[ScriptBlock]::Create()` — bypasses AMSI?

### PowerShell Remoting
- `Enter-PSSession` / `New-PSSession` — remote execution targets injectable?
- `Invoke-Command -ComputerName` — credential delegation risk?
- `$using:` scope in remote contexts — injection surface?

### Data Leakage
- `Write-Host` / `Write-Output` — secrets in console?
- `Export-Clixml` / `Out-File` — unencrypted sensitive data?
- Verbose/Debug streams — information disclosure?
- `Get-Process` — user enumerating system info?

### Security Boundary
- `#Requires -RunAsAdministrator` — missing elevation guard?
- Execution Policy bypass (`-Scope Process`, `Bypass`)?
- `Unblock-File` — downloaded file trust?
- SecureString usage — plaintext password handling?
- Credential caching — stored beyond needed scope?

### Concurrency
- `ForEach-Object -Parallel` — shared variable races ($using: scope)?
- `RunspacePool` / `Start-Job` — shared resource sync?
- Lock files / mutex contention?
- `Start-Sleep` in loops — busy-wait anti-pattern?

## PowerShell-Specific Anti-Patterns
- Using `Select-String` where `-match` is faster and safer
- Unconstrained `[ValidateScript({ ... })]` with side effects
- `Get-Content` on user-provided paths without `-LiteralPath`
- `ConvertTo-Json` depth issues (default 2)
- Pipeline variable leak (`$_` in nested pipelines)
- AMSI bypass techniques — check for `amsiInit`, `[Ref].Assembly`, reflection-based obfuscation
- `$env:` variable manipulation for PATH hijacking or credential discovery
