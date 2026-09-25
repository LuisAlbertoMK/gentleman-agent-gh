#requires -Version 7
# JD P1 2026-08-27 security dual APPROVED - SSRF allowlist (Test-OllamaBaseUrlAllowlist, timeout 5/8, sanitized error) - sane-check CLEAN
implementer 2026-09-25 one-line param fix ([string]$OllamaApiKey without = "" default; unbound [string] is '', if-guard unchanged) to close the E2 allowlist blind spot; dual-review security BLOCKER remediated in the same commit staging this marker (fix/tests-job-pre-existing) — reviewed with findings remediated, never cleared nor approved fileHash:16e76cd1
