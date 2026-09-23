@echo off
REM DEPRECATED: use scripts\gentle-mk.bat instead (canonical) — this shim only forwards for backwards compat.
if not exist "%~dp0gentle-mk.bat" (
  echo FAIL-CLOSED: scripts\gentle-mk.bat not found - cannot forward gentleman-vmk 1>&2
  exit /b 1
)
call "%~dp0gentle-mk.bat" %*
