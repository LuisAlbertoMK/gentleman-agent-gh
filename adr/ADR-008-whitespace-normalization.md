# ADR-008: Normalizar input antes de clasificar comandos (anti-evasión)

- **Status**: Accepted · **Ciclo**: C9 (2026-08-03) · **Tipo**: bugfix/seguridad
- **Context**: Breaker C9 expuso que los patrones de permiso anclados `^` son trivialmente evadibles: `git  clean  -fdx` (doble espacio), `git<TAB>clean`, leading spaces → **allow en auto**.
- **Decision**: Normalización `$cmd = $cmd -replace '\s+',' '; $cmd.Trim()` al inicio de `Get-CommandClass` en el lib de permisos + 9 tests de regresión de evasión (Describe "Whitespace normalization").
- **Alternatives**: Ampliar patrones para cada variante de whitespace — rechazado: combinatorio, imposible de cubrir exhaustivamente.
- **Consequences**: 4 vectores de evasión → 0. La normalización es el punto único de saneamiento antes de toda clasificación.
- **Refs**: `mejora-log.md` §Ciclo 9; `scripts/lib/permission-gate-lib.ps1`, `scripts/tests/permission-gate.Tests.ps1`.
