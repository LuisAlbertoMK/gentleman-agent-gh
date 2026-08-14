# Plan: Auto-Mejora Autónoma v3 — {FECHA}

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Proyecto**: {NOMBRE_PROYECTO} · **Stack detectado**: {STACK} ({LENGUAJE}, {FRAMEWORK})
**Base**: `main` HEAD `{COMMIT_BASE}`
**Branch propuesta**: `experimento/mejora-autonoma-{FECHA}`
**Presupuesto**: 3 ciclos max · 15 min/ciclo · {PRESUPUESTO_COSTO}
**Escalado**: correctness > security > performance > size
**Escala ICE**: Impacto 1-10, Confianza 1-10, Esfuerzo 1-10 inverso (10 = mínimo esfuerzo). Prioridad = I×C×E.

### Herramientas del stack (detectadas, no asumidas)
| Función | Comando/herramienta |
|---|---|
| Test runner | {TEST_CMD} |
| Linter/analizador estático | {LINT_CMD} |
| Build/compile | {BUILD_CMD} |
| Benchmark (medición repetible) | {BENCH_CMD} |
| Escaneo de vulnerabilidades | {VULN_SCAN_CMD} |

### Baseline estadístico (§0.7) — 5-10 runs con mediana/IQR
Un solo valor no es baseline. Ejecutar {BENCH_CMD} × 10 en branch efímero, calcular mediana + Q1/Q3/IQR reales (no Average/Min/Max), guardar en `benchmark-baseline.json`. El plan solo procede con baseline estadístico real.

### Entorno aislado (§0.9)
Todo ciclo corre en **{CI_RUNNER}** efímero (workflow: `{CI_WORKFLOW_PATH}`), branch `experimento/mejora-autonoma-{FECHA}`. Nunca contra infraestructura compartida. Verificar que comandos/paths sean portables al runner (nada de rutas absolutas específicas de un OS si el runner es otro).

### Estado de tests baseline (§3.5)
- **Baseline actual (main)**: {N_PASS} pass / {N_FAIL} fail
- **Root cause de fails preexistentes**: {ROOT_CAUSE} (documentado en `mejora-log.md`, fuera de scope salvo que su blast radius sea Alto y se abra checkpoint separado)
- **DoD target**: 0 NEW failures. Fails preexistentes se verifican como no-regresión vía `git diff` de archivos de test.

---

## 0. Evidencia de Gaps
*(usar el skill `analisis-gaps` o equivalente para producir esta sección — cada gap con fuente de evidencia real, no opinión)*

### G1: {DESCRIPCION_GAP_1}
- **Fuente**: {ARCHIVO}:{LINEA}
- **Evidencia**: {COMANDO_O_HERRAMIENTA_USADA}
- **Blast Radius**: {Bajo|Medio|Alto}
- **ICE**: {I}×{C}×{E} = {TOTAL}

### G2 / G3: (repetir estructura para cada gap seleccionado — 3 si hay suficientes, menos si no hay más con evidencia real)

---

## N. Ciclo N — G{X}: {NOMBRE_GAP}

### Scope Lock
```
IN:  {archivos a tocar}
OUT: todo lo demás (ADR mini si se desvía)
```

### 3 Enfoques (generados ANTES de implementar — si ya existe un fix aplicado fuera de proceso, se re-evalúa aquí, no se da por bueno)
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** | | | |
| **B** | | | |
| **C** | | | |

### Ganador esperado
{ENFOQUE} — por jerarquía de métricas ({CATEGORIA}). *(Sujeto a confirmación tras benchmark real — "esperado" no es "decidido".)*

### DoD (se marca solo tras ejecución real, nunca antes)
- [ ] Tests nuevos/existentes: pass, comando: {TEST_CMD}
- [ ] Sin regresión respecto a baseline
- [ ] Benchmark: {BENCH_CMD} ×10, mediana/IQR vs baseline (§0.7)
- [ ] 0 vulnerabilidades críticas/altas nuevas: {VULN_SCAN_CMD}
- [ ] ADR-{N}: mini-doc de la decisión
- [ ] Commit: `{tipo}: {mensaje}` (refactor/fix/feat separados, nunca mezclados)
- [ ] **Si Blast Radius = Alto**: checkpoint humano PENDIENTE — no se autoaprueba, no se marca hasta confirmación explícita de una persona

---

## Verificación Final & PR

### DoD Global (§3.8, binario, checks solo tras ejecución real)
| Check | Status |
|---|---|
| Tests: 0 NEW failures | Pendiente de ejecución |
| Benchmark no regresivo (mediana/IQR, baseline vs final) | Pendiente de ejecución |
| 0 new critical/high vulns | Pendiente de ejecución |
| ADRs escritos | Pendiente |
| Commits dentro de scope | Pendiente de verificación por ciclo |
| Rollback map con hashes reales | Pendiente — ver abajo |
| Checkpoint humano en todo gap Alto | Pendiente — obligatorio antes de merge |

### Deliverables
```
docs/mejoras/plan-auto-mejora-v3-{FECHA}.md   ← ESTE ARCHIVO
docs/mejoras/benchmarks.md                     ← crear o actualizar (verificar si ya existe)
docs/mejoras/rollback-map.md                   ← nuevo
mejora-log.md                                  ← append ciclos
adr/                                           ← un ADR por ciclo
ANTI-PATTERN-CATALOG.md                        ← append si aplica
```

### PR
- **Base**: `main` · **Compare**: `experimento/mejora-autonoma-{FECHA}`
- **NO merge a main** — espera aprobación humana explícita, obligatoria si algún gap fue Alto

---

## Rollback Map
*(placeholder hasta que existan los commits reales)*
```
Commit <pendiente>  {tipo}: {descripción ciclo 1}  → REVERTIBLE via git revert
Commit <pendiente>  {tipo}: {descripción ciclo 2}  → REVERTIBLE
Commit <pendiente>  {tipo}: {descripción ciclo 3}  → REVERTIBLE
```

---

## Aprobación requerida
**Aprobado para ejecutar**: [ ] Sí — lanzar branch + ciclos + PR
**Aprobado para merge de gaps Alto a main** (independiente de lo anterior): [ ] Sí

*Protocolo: docs/protocolos/protocolo_mejora_autonoma_v3.md*
*Fecha: {FECHA}*
