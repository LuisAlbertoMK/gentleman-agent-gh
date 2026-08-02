---
description: Full diagnostics — git state, config drift, skill drift, cross-ref, score
---

You are executing `!health`. Full diagnostic of the project. Read-only: report findings, do not auto-fix.

Steps:

1. **Resolve script root**:
   `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root -or -not (Test-Path "$root\scripts\health-check.ps1")) { $root = Split-Path $PSScriptRoot -Parent }`
2. **GENTLEMAN_AGENT_ROOT validation**:
   `$userVar = [Environment]::GetEnvironmentVariable('GENTLEMAN_AGENT_ROOT','User'); $procVar = $env:GENTLEMAN_AGENT_ROOT`
   - If `$userVar` is empty → WARNING: routing root was never configured (setup-machine not run, or the var was removed). Remediation: run `!setup` (setup-machine) then open a NEW shell/terminal so the variable propagates.
   - If `$userVar` is set but `$procVar` is empty or differs → WARNING: the current process does NOT inherit it (it was launched before the variable was set). Remediation: re-open the shell/terminal/IDE (or re-run setup-machine) — do NOT rely on the current session for routing.
3. **Git state**: `git status` (short) + `git log --oneline -5`.
4. **Config drift**: `& "$root\scripts\check-config-drift.ps1"`.
5. **Skill drift**: `& "$root\scripts\check-skill-drift.ps1"`.
6. **Cross-ref integrity**: `& "$root\scripts\cross-ref-check.ps1"`.
7. **Score**: `& "$root\scripts\score-auto.ps1" -Quiet`.
8. **Optional dashboard**: if an HTML report is wanted, run `& "$root\scripts\health-dashboard.ps1" -OpenInBrowser`.

Report a table `|Check|Status|Details|`. Flag every failure with a one-line remediation and route: drift → `!skills-audit`, score → `!score`, broken refs → fix or escalate. Do NOT modify files in this command.
