#requires -Version 7
# .breaker-cleared marker for tests/security-audit-mcp.Tests.ps1 (P0-2 S1)
# Naming: legacy flat format — path separators → underscores (tests/security-audit-mcp.Tests.ps1 → tests_security-audit-mcp.Tests.ps1).
# Precedent: .breaker-cleared/scripts_use-gentleman.ps1 (docs/mejoras/mejora-log.md:164),
#   .breaker-cleared/scripts_babyagi-loop.ps1; accepted as legacy fallback by scripts/check-adversarial.ps1:90-92
#   ($markerLegacy = "$RepoRoot\.breaker-cleared\$normalized").
# Breaker PS-CI-03 FALSE POSITIVE (~5-10% doubt): $script:AuditPath = Join-Path $PSScriptRoot at
#   tests/security-audit-mcp.Tests.ps1:17 — Join-Path idiom, precedent tests/validate-write-scope.Tests.ps1:4,11,
#   plus the widespread call-operator-with-variable-command idiom in this repo. Verdict (a) authorized.
# Verify Tier 2: 4R PASS (Risk 9, Read 8, Rel 8, Res 8), Pester 19/19, PSSA 0 errores.
# Freeze: HEAD-67707025-e69de29b.
