# Lecciones Aprendidas — Auditoría Consolidada

> **Propósito**: Capturar patrones de regresión, causas raíz sistémicas, y prevención.
> **Basado en**: 3 ciclos de auditoría que encontraron los mismos problemas repetidos.
> **Última revisión**: 2026-07-03

---

## 🔄 Regresiones Detectadas

### R-001: Fixes que no persisten por upstream sync

**Síntoma**: Hallazgos marcados ✅ Done que aparecen rotos en la siguiente auditoría (F1-F3 de la externa del 03/07, que estaban "resueltos" desde el 23/06).
**Causa raíz**: `pull-upstream.ps1` sincroniza archivos desde el upstream `Gentleman-Programming/gentle-ai`. Los archivos personalizados (install.ps1, README, scores) se pisaban con la versión upstream en cada sync.
**Fix aplicado**: Lista de exclusión explícita en `pull-upstream.ps1` para: install.ps1, install.sh, README.md, PROJECT-SCORE.md, project-score.md, .env.example.
**Prevención**: 
- Cross-ref-check.ps1 debe verificar archivos de la exclusion list no hayan cambiado contra upstream
- Auditoría externa debe incluir "probar que sync no rompa nada"

---

### R-002: Documentación que driftea del código

**Síntoma**: AGENTS.md referencia 3 scripts que no existen (auto-metrics.ps1, commit-crafter.ps1, intake.ps1) — detectado en 3 auditorías consecutivas sin resolución.
**Causa raíz**: No hay validación automática de que AGENTS.md mencione solo scripts reales. El cross-ref-check.ps1 no parsea pipelines de AGENTS.md.
**Fix propuesto**: cross-ref-check.ps1 debe extraer nombres de scripts de AGENTS.md y verificar `Test-Path`.
**Prevención**: Gate CI que falle si AGENTS.md referencia paths que no existen.

---

### R-003: Múltiples fuentes de verdad para métricas

**Síntoma**: 4 archivos con números de score diferentes (PROJECT-SCORE.md, project-score.md, README, docs/ciclos/).
**Causa raíz**: No hay un único source of truth para scores. Cada documento se actualiza independientemente.
**Fix aplicado**: Consolidación a 10/10 en todas las fuentes.
**Prevención**: cross-ref-check.ps1 debe comparar scores entre fuentes y alertar si discrepan >0.1.

---

## 🧠 Patrones Sistémicos

### P-SYS-01: Categorías OWASP no calzan en proyectos PS

**Observación**: El PROMPT-auditoria-multiagente.md original está diseñado para web apps (UI/UX, SEO, Accesibilidad, BD queries). Forzarlo sobre un proyecto PowerShell produce ~40% de categorías que no aplican y archivos vacíos.
**Lección**: Adaptar plantillas de auditoría al stack real del proyecto. No usar OWASP directamente en PS/skills projects.
**Acción**: La estructura consolidada en `docs/auditoria/` usa 5 categorías reales (SEG, ARC, PERF, OPS, ORTO) en vez de 9 genéricas.

### P-SYS-02: Los scripts "plan" envejecen sin ejecutarse

**Observación**: `hallazgos-completos.md` (469 líneas, plan detallado P0-P3) se escribió el 25/06. Para el 03/07, ~50% ya estaba resuelto pero el documento no se actualizó — seguía mostrando items como pendientes que ya se habían implementado.
**Lección**: Un plan sin dueño que lo mantenga actualizado se vuelve deuda documental. 8 scripts mencionados en el plan nunca se crearon.
**Acción**: El plan ahora es `03-plan-implementacion.md` dentro de la carpeta `auditoria/`, con IDs vinculados al índice maestro.

### P-SYS-03: Subagentes que no persisten archivos

**Observación**: El reporte `scripts-parte2.md` de la revisión lineal nunca se escribió porque el subagente no persistió el archivo. El problema se detectó pero no se corrigió.
**Lección**: Cuando un subagente falla en persistir, el orquestador debe detectarlo y re-ejecutar o documentar la brecha explícitamente.
**Prevención**: Verificar `Test-Path` post-subagente para cada archivo prometido.

---

## 📋 Checklist de Prevención para Futuras Auditorías

| # | Check | Responsable | Gatillo |
|---|-------|-------------|---------|
| 1 | ¿Los hallazgos ✅ Done resisten un `pull-upstream`? | Cross-ref-check | Post-sync |
| 2 | ¿AGENTS.md referencia solo scripts que existen? | cross-ref-check.ps1 | Pre-commit |
| 3 | ¿Scores coinciden entre todas las fuentes? | cross-ref-check.ps1 | !score o !health |
| 4 | ¿Subagentes que prometieron archivos los crearon? | Orchestrador | Post-subagente |
| 5 | ¿La plantilla de auditoría calza con el stack real? | Orchestrador | Pre-auditoría |
| 6 | ¿Hallazgos resueltos tienen commit/PR documentado? | Dueño del hallazgo | Al marcar ✅ |
| 7 | ¿Regresiones tienen entrada en lecciones-aprendidas? | Orchestrador | Al detectar 🔄 |

---

## Archivo Histórico

| Documento | Archivado | Razón |
|-----------|-----------|-------|
| `docs/PROMPT-auditoria-multiagente.md` | `docs/auditoria/05-archivo/prompt-original.md` | Reemplazado por estructura consolidada |
| `docs/hallazgos-completos.md` | `docs/auditoria/03-plan-implementacion.md` | Versionado como plan P0-P3 |
| `docs/AUDITORIA-EXTERNA-gentleman-agent-gh.md` | `docs/auditoria/05-archivo/auditoria-externa.md` | Contenido absorbido en hallazgos + lecciones |
| `docs/auditoria-adaptada/` | `docs/auditoria/05-archivo/auditoria-adaptada/` | Reemplazado por estructura consolidada |
