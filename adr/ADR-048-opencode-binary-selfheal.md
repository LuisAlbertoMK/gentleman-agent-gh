# ADR-048: opencode binary self-heal (npm auto-update race guard)

## Status
Accepted - 2026-09-02

## Context
Incident 2026-09-02 16:25 — `opencode.exe` truncated to invalid PE (`not a valid application for this OS platform`) while multiple opencode instances were running. Root cause: opencode CLI auto-checks for updates on startup (`checkUpgrade -> upgrade()`) and for npm installs replaces `C:\Users\MK\AppData\Roaming\npm\node_modules\opencode-ai\bin\opencode.exe` in-place while other instances hold/exec the binary — Windows PE replacement race. Evidence: npm prefix `C:\Users\MK\AppData\Roaming\npm`, exe at `<prefix>\node_modules\opencode-ai\bin\opencode.exe`, `postinstall.mjs` silently rewrites the binary; re-running `node postinstall.mjs` restores a valid PE (exit 0 + `--version` matches `^\d+\.\d+\.\d+`) even with instances running. `scripts/sync-global.ps1` is not the culprit (zero npm calls) but is the user's sync entry point, so it must gain a self-heal step. Config option `autoupdate` accepts `true|false|"notify"` (default = auto-update on startup).

## Decision
1. **Disable startup auto-upgrade.** Template `scripts/sync-global.ps1` global config `$cfg` now includes `'autoupdate'=$false` (ADR-048 comment). Live patch in Step 7 corrects an existing global `opencode.json[c]` when the key is missing **or** `true -> false`: guard `-or $gcRaw.autoupdate -eq $true` (`PSObject.Properties.Match('autoupdate')` + `Add-Member -Force $false` -> `ConvertTo-Json -Depth 100 | Set-Content UTF8`, try/catch warning-only, never throw). Value `"notify"` is intentionally left alone — it alerts without replacing the binary, so it is safe.

2. **Sync-global Step 7 `opencode binary health`** (after MCP availability, before Report, via `Write-Step`). DryRun = inline `Test-Binary` drift check (no writes; drift = `opencode.exe corrupt or missing — would heal via postinstall` if missing or `--version` invalid). Execute = live-patch (1) then `& (Join-Path $PSScriptRoot "update-opencode.ps1") -HealOnly -Json` -> `report.steps["opencode_binary"]=@{version=<after_version>;healed=<healed>}`; failure throws to mark step fail. JSON includes `postinstall_path` for remediation hints.

3. **New `scripts/update-opencode.ps1`** (user-facing; agents have npm/pwsh deny rules): `#requires -Version 7`, `[CmdletBinding(SupportsShouldProcess=$true)]`, `$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest`, report shape `timestamp/steps/errors/warnings/status` plus `healed/before_version/after_version/postinstall_path`. Params `[switch]$HealOnly`, `[switch]$StopProcesses`, `[string]$Version="latest"`, `[switch]$Json`. Resolves prefix via `npm prefix -g` (fallback `$env:APPDATA\npm`), `$exe`/`$postinstall`. `Test-Binary` = missing -> `$null` else `& $exe --version` valid iff exit 0 and stdout matches `^\d+\.\d+\.\d+`. Detect: `Get-Process opencode` -> if any and not `-StopProcesses` -> warning `N opencode instance(s) running — binary replacement may race; pass -StopProcesses to stop them first`; if `-StopProcesses` -> `Stop-Process -Id ... -Force` (opt-in only; never default-kill — script may be invoked from inside an opencode session). Update: skip if `-HealOnly` else `npm i -g "opencode-ai@$Version"`. Heal: if `Test-Binary` is `$null` -> `node $postinstall` via `Start-Job` + `Wait-Job -Timeout 180` (180 s timeout per attempt), wait 2 s, re-test; retry up to 2 attempts with 5 s gap; record `healed`. Verify: final `Test-Binary`; if `$null` -> status fail exit 1 with hint `node "$postinstall"`. `-Json` mode emits pure JSON on stdout — all `Write-Warning`/`Write-Host` guarded by `if (-not $Json)`, npm output suppressed via `| Out-Null` in Json mode — so `sync-global` Step 7 `ConvertFrom-Json` parses reliably.

## Consequences
- Updates are now manual/controlled via `scripts/update-opencode.ps1` (or `-StopProcesses` when safe); every `sync-global` run auto-heals a corrupt binary and corrects `autoupdate=true` without user intervention. `"notify"` remains usable for users who want alerts without races.
- Safety: never kills opencode processes by default — `-StopProcesses` is explicit opt-in. Heal is bounded: at most 2 attempts, 180 s each, then fails with actionable remediation.
- Observability: `postinstall_path` in JSON on both success and failure; `-Json` purity guarantees `sync-global` can parse the result (verified by hermetic tests).
- PS 5.1 parity = health check + autoupdate patch + best-effort heal only when pwsh is present (update-opencode.ps1 is PS7-only); no process management on the PS5 path. No global `opencode.json` direct writes from agent tooling (write deny respected). Test suite covers healthy path, corrupt-binary heal fail path (PATH-injection fake prefix with invalid exe + empty `postinstall.mjs`), timeout wrapper parse-level, and `Stop-Process` guard.

## Alternatives Considered
- **Migrate to standalone installer** (e.g. pinned binary outside npm) — bigger change, loses npm flow and auto-version pinning; deferred to future if race recurs outside npm.
- **Keep manual fix** (`node postinstall.mjs` on failure) — status quo that burned the user on 2026-09-02; no guard, no observability, no auto-heal.

## References
- `scripts/sync-global.ps1` Step 7 + `$cfg.autoupdate` (Depth 100 live patch)
- `scripts/update-opencode.ps1` (Start-Job/Wait-Job 180 s, 2 attempts, postinstall_path, pure Json)
- `scripts/tests/update-opencode.Tests.ps1`; `scripts/tests/sync-global.Tests.ps1`
- Incident 2026-09-02 16:25; opencode `autoupdate` config (`true|false|"notify"`); `postinstall.mjs` silent-on-success contract (verify via `--version`)
