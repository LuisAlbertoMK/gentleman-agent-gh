@echo off
REM gentleman-vmk.bat - CMD wrapper that auto-detects PowerShell version
REM   - Prefers pwsh.exe (PowerShell 7+) when available for full feature set
REM   - Falls back to powershell.exe (Windows PowerShell 5.1) otherwise
REM   - Both invoke: opencode --agent gentleman-vMK %*
REM
REM Usage:
REM   gentleman-vmk            - launch agent interactively
REM   gentleman-vmk "do X"     - ask agent to do something

setlocal

REM Try pwsh (PowerShell 7+) first — full feature set
where pwsh.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    pwsh.exe -NoLogo -NoProfile -Command "opencode --agent gentleman-vMK %*"
    exit /b %ERRORLEVEL%
)

REM Fall back to powershell.exe (Windows PowerShell 5.1) — native on Windows
where powershell.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    powershell.exe -NoLogo -NoProfile -Command "opencode --agent gentleman-vMK %*"
    exit /b %ERRORLEVEL%
)

REM Last resort: try running opencode directly (no PowerShell wrapper)
where opencode >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [info] PowerShell not found — running opencode directly
    opencode --agent gentleman-vMK %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] Could not find pwsh.exe, powershell.exe, or opencode.
echo   Install PowerShell 7: winget install Microsoft.PowerShell
echo   Or use the .cmd shortcut installed by setup-machine.ps1
exit /b 1
