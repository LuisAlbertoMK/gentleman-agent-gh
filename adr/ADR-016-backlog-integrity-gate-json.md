# ADR-016: Backlog-integrity en el gate + contrato -Json en early-exits

- **Status**: Accepted · **Date**: 2026-08-04 · **Type**: enforcement
- **Context**: `check-backlog-integrity.ps1` verificaba el backlog de CYCLE.md contra la realidad del repo pero solo lo consumían score-auto y smoke tests — ningún commit/push podía bloquearse por backlog mentiroso (drift CYCLE.md:21 pasó desapercibido). Además los early-exit paths emitían texto crudo con `-Json` (contrato roto).
- **Decision**: (1) Wire al pre-commit gate como check [18/18] incondicional y fail-closed (si el script falta → gate falla), mirror en CI quality-gate.yml job lint. (2) Helper `Write-ErrorJson` para los 3 early-exits: con `-Json` emiten `{errors:[...], allPassed:false, score:0, totalItems:0}` + exit 1; sin `-Json` conservan Write-Host.
- **Alternatives**: (A) solo gate local sin CI — rechazado: PRs y merges quedarían sin cobertura; (B) warn-only — rechazado: el drift debe bloquear (R10); (C) try/except por call-site en el script — rechazado: 5 wrappers, riesgo de ocultar errores SQL reales.
- **Consequences**: Todo commit/push con backlog inconsistentes con la realidad del repo se bloquea (gate local + CI). El gate pasa de 17 a 18 checks. Cualquier caller con `-Json` puede parsear stdout en TODAS las rutas (éxito, fallo, error).
- **Refs**: `mejora-log.md` Ciclo 3 (v2); `docs/mejoras/2026-08-04-gentleman-agent-gh-analisis.md` R10; ADR-015 (fail-closed); ADR-007 (size budget gate pattern).
