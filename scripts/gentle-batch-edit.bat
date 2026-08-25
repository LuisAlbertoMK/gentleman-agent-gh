@echo off
REM gentle-batch-edit.bat - CMD wrapper that auto-detects Go toolchain
REM   - If Go is available: compiles and runs the Go batch-edit engine
REM   - Falls back to a helpful message if Go is not installed
REM
REM Usage:
REM   gentle-batch-edit spec.jsonl              - apply edits
REM   gentle-batch-edit -n spec.jsonl           - dry-run (count only, no writes)
REM   gentle-batch-edit -c 4 spec.jsonl         - concurrency=4 (default min(GOMAXPROCS,8))

setlocal

REM Locate Go toolchain
where go >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Go toolchain not found in PATH.
    echo   Install Go from: https://go.dev/dl/
    echo   Or use OpenCode's Edit tool for individual file edits.
    exit /b 1
)

REM Resolve the scripts directory where gentle-batch-edit.go lives.
REM When run from scripts/ directly, %~dp0 finds it. When copied to npm dir
REM by setup-machine.ps1, we need GENTLEMAN_AGENT_ROOT (set by the setup).
set "SCRIPT_DIR=%~dp0"
set "GO_FILE=%SCRIPT_DIR%gentle-batch-edit.go"

if not exist "%GO_FILE%" (
    REM Try GENTLEMAN_AGENT_ROOT\scripts\gentle-batch-edit.go (for npm-dir copy)
    if defined GENTLEMAN_AGENT_ROOT (
        set "GO_FILE=%GENTLEMAN_AGENT_ROOT%\scripts\gentle-batch-edit.go"
    )
)

if not exist "%GO_FILE%" (
    echo [ERROR] gentle-batch-edit.go not found.
    echo   Set GENTLEMAN_AGENT_ROOT to the repo path, or run from scripts/.
    exit /b 1
)

REM Derive the directory of the Go source file (for output binary placement)
for %%F in ("%GO_FILE%") do set "SRC_DIR=%%~dpF"

REM Build to a temp binary next to the source (avoids PATH pollution)
set "BINARY=%SRC_DIR%gentle-batch-edit.exe"
go build -o "%BINARY%" "%GO_FILE%" 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to compile gentle-batch-edit.go
    exit /b 1
)

REM Run the binary with passed-through args
"%BINARY%" %*
exit /b %ERRORLEVEL%
