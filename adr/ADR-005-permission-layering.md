# ADR-005: Permission layering deny → destructive → mode

- **Status**: Accepted · **Ciclo**: C7 (2026-08-02) · **Tipo**: architecture/seguridad
- **Context**: Directiva de usuario (modo auto): "auto debería ser autónomo — sin push ni delete automático, lo demás sin problema". `rm`/`Remove-Item` debían pasar de deny a ASK en auto, preservando deny en manual/semi.
- **Decision**: Orden de chequeo deny → destructive → mode. Comandos destructivos separados del deny global (mode-governed). En auto: commit/merge/rebase/gh-pr-merge allow; push + deletes (rm, Remove-Item, branch -D, stash drop, reset --hard) ask. Deny manual/semi preservado.
- **Alternatives**:
  - Mismo conjunto de denies para todos los modos — rechazado: no permite autonomía real en auto.
  - Ask para todo en auto — rechazado: no es autonomía.
- **Consequences**: 54 tests de permission-gate (7 nuevos auto-mode); rm es ask en auto y deny en semi sin duplicar lógica. +4 tests E2E nuevos.
- **Refs**: `mejora-log.md` §Ciclo 7; `scripts/lib/permission-gate-lib.ps1`, `scripts/tests/permission-gate.Tests.ps1`.
