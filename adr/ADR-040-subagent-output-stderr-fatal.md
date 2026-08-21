# ADR-040: stderr discard + fatal git-diff en check-subagent-output.ps1

**Fecha**: 2026-08-20 · **Ciclo**: 29/C1 (G1) · **Estado**: Aceptado

## Contexto
El detector de silent-failure contaba ruido de stderr de git (`fatal: ambiguous argument...`) como archivos cambiados: el filtro solo excluía `^warning:`. Resultado: diffs vacíos reportaban "N file(s) changed" con basura y exit 0 — el anti-patrón exacto que el script existe para detectar. Los tests T1-T4 no eran herméticos (sin identidad git global, `git commit` fallaba con exit 128 y los fixtures quedaban staged), por lo que T2-T4 pasaban vacuamente y T1 fallaba por la razón equivocada.

## Decisión
1. `2>$null` en ambas invocaciones git (diff + status) — stderr descartado en la fuente; filtros Where-Object quedan como defensa en profundidad.
2. `$LASTEXITCODE -ne 0` tras `git diff` → fatal (exit 1) en modo texto y JSON. Sin esto, el silenciamiento de stderr convertía BaseRef inválidos en OK silencioso (finding HIGH del breaker).
3. Fixtures herméticos: `git config user.email/user.name` local antes de cada commit en tests/check-subagent-output.Tests.ps1; nuevo T5 cubre BaseRef inválido → exit 1.

## Alternativas descartadas
- **Capturar stderr por separado y filtrar solo warnings**: más código, mismo resultado; el check de $LASTEXITCODE cubre el caso fatal.
- **Módulo compartido de validación (refactor DRY)**: blast radius mayor sobre la ruta sync que ya funciona — viola minimización de riesgo del ciclo.

## Consecuencias
- Empty-diff → SILENT FAILURE real (exit 1) verificado.
- BaseRef inválido → GIT ERROR fatal (exit 1), test T5.
- Edge documentado (no fix): repo sin commits reporta empty-output (falso positivo teórico; delegaciones reales siempre corren en repos con historial).
- Breaker: PASS-WITH-NOTES (13 ataques target 1); issues MEDIUM/LOW restantes documentados en mejora-log.
