## Decision Taken
Ciclo #1 v3 (Enfoque B2) cerrado: cycle log, ADR-008 (H2, Proposed) y append a mejora-log escritos; H2 verificado como HIGH latente; benchmark FAIL atribuido a Gap D.

## Files Changed
- docs/mejoras/2026-08-07-v3-cycle1-B2.md (nuevo, 7,209 B) — cycle log
- docs/adr/008-auto-sub-permission-merge-safety.md (nuevo, 3,346 B) — ADR Proposed
- mejora-log.md (append, +Cycle #1 v3 B2) — 94,282 B total
- docs/agentes/documenter-v3-cycle1-B2/: 00-resumen-ejecutivo.md, 01-analisis-detallado/{evidencia-h2,evidencia-units-a-b,benchmark-c}.md, 02-plan-implementacion.md, 03-evidencia/pester-run.txt, 04-metricas.md, 05-completion-report.md (reportes de la unidad)

## Key Findings
1. [CRITICAL→HIGH] H2: guard de colisión hardcodeado (generate-opencode-config.js:163) omite `task`; extraPermKeys:{task:{*:allow}} elude guard y Object.assign shallow (L169) sobrescribe task:{*:deny} → escalada de delegación. LATENTE (overrides vivos = adds puros). Fix ADR-008 (Object.keys(template)) — Evidencia: read L161-170 + permission-templates.json:44,175 + agent-overrides.json:17-67.
2. [HIGH] Gap D: benchmark FAIL +97.4% (520.9 ms subagente vs 263.8 ms §0 orquestador) — mismatch de contexto de medición, no atribuible a Unit A (test-only). Números NO persistidos en repo (sub-hallazgo).
3. [MEDIUM] Gap de test: colisión solo cubierta con `bash` (la clave que el guard ya cubría); falta test `task` → el fix de Cycle #2 debe incluirlo (7/7).
4. [MEDIUM] Test file de Unit A (generate-config.Tests.ps1) sin commitear — 0 commits en ciclo 1 (consistente con Enfoque B2); commit C1-test: pendiente.
5. [LOW] docs/adr/ no existía; convención repo = adr/ADR-NNN-* (próximo libre 021); brief mandata docs/adr/008-* — número colisiona con adr/ADR-008-whitespace-normalization.md.

## Nuance
(1) El fix propuesto es drop-in safe SOLO porque los templates son objetos planos (verificado) y ambos overrides vivos de `task` son adds puros sobre templates sin `task`; si en el futuro se añade un metadato dentro de un template, Object.keys lo incluiría — verificar en el PR. (2) La clasificación H2 difiere entre Unit B (crítico) y DoD (HIGH): la diferencia es latencia — el SSoT actual no explota el vector; documentado, no resuelto. (3) Los números de benchmark (263.8/520.9 ms) provienen de las sesiones del orquestador y no existen en ningún artefacto repo — este es el primer lugar donde quedan persistidos; re-medir en Cycle #2 bajo metodología corregida. (4) mejora-log.md se reescribió completo (ReadAllText+WriteAllText) para append — bytes originales preservados (94,282 B total vs 915 líneas previas); se perdió cualquier BOM previo si existía (no verificable post-escritura). (5) El brief ubicaba el guard en `generate-opencode-config.js:163` — la ruta real es `scripts/lib/generate-opencode-config.js:163`; el número de línea coincide exactamente.