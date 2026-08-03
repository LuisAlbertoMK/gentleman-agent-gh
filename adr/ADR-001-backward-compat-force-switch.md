# ADR-001: Backward-compat de switches destructivos

- **Status**: Accepted · **Ciclo**: C1 (2026-08-02) · **Tipo**: compat/API
- **Context**: `clean-repo.ps1` y `engram-compact.ps1` usaban `-Yes` (sin `-Force`) y `Remove-Item -ErrorAction SilentlyContinue` en operaciones destructivas sin try/catch → 7 tests failing.
- **Decision**: `[Alias('Yes')][switch]$Force` en ambos scripts. Remove-Item destructivos envueltos en try/catch con `-ErrorAction Stop`, sin SilentlyContinue (fuera de cleanup/finally se reporta warning).
- **Alternatives**:
  - Renombrar `-Yes`→`-Force` en todo el repo — rechazado: rompe pre-commit gate, setup-machine, shortcuts.
  - `SupportsShouldProcess` — rechazado: el test exige literal `param(...$Force...)`.
- **Consequences**: 100% backward-compat con callers legacy `-Yes`; tests pasan literal `$Force`. Docs SYNOPSIS + ejemplos actualizados.
- **Refs**: `mejora-log.md` §Ciclo 1; `scripts/clean-repo.ps1`, `scripts/engram-compact.ps1`.
