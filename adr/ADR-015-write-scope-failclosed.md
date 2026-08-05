# ADR-015: Write-scope fail-closed on invalid patterns

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: security
- **Context**: `validate-write-scope.ps1` catch block silently skipped malformed glob patterns (Write-Debug only). A malformed pattern could let a violating file match no pattern → classified as VIOLATION → but if ALL patterns are malformed, every file matches nothing → all VIOLATION. The real risk: if pattern parsing fails AND no pattern matches, a file could slip through as CLEAN (fails-open).
- **Decision**: Replace silent skip with fail-closed: emit ERROR (respect -Json), `exit 1`. A malformed pattern must never let a violating file through as CLEAN.
- **Alternatives**: (A) Keep skip but warn to stderr — rejected: still fails-open if patterns are malformed. (B) Skip + force VIOLATION on all files — rejected: too aggressive, blocks legitimate empty-pattern cases already handled upstream. (C) Fail-closed (chosen): deterministic, forces caller to fix the pattern.
- **Consequences**: Malformed patterns now hard-fail (caller must fix). All existing valid patterns unaffected. New Pester T4 test locks the regression (exit 1 + ERROR on `[[unclosed`).
- **Refs**: `mejora-log.md` §Ciclo 1 (C1-close); `scripts/validate-write-scope.ps1` catch block (L126); `tests/validate-write-scope.Tests.ps1` T4.
