# Plan: Auto-Mejora Autónoma v3 — 2026-08-20

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Proyecto**: gentleman-agent-gh · **Stack detectado**: PowerShell 7 (Pester 6), Node (config expansion)
**Base**: `main` HEAD `33425647`
**Branch propuesta**: `experimento/mejora-autonoma-2026-08-20`
**Presupuesto**: 3 ciclos max · 15 min/ciclo
**Escalado**: correctness > security > performance > size
**Escala ICE**: Impacto 1-10, Confianza 1-10, Esfuerzo 1-10 inverso. Prioridad = I×C×E.

### Herramientas del stack (detectadas, no asumidas)
| Función | Comando/herramienta |
|---|---|
| Test runner | `pwsh -NoProfile -Command "Invoke-Pester -Path tests,scripts/tests -CI"` |
| Linter/analizador estático | PSScriptAnalyzer (via quality-gate) |
| Build/compile | N/A (repo de config/scripts) |
| Benchmark (medición repetible) | N/A para este ciclo (no hay código hot-path) |
| Escaneo de vulnerabilidades | git diff review + secrets scan pre-commit |

### Estado de tests baseline (§3.5)
- **Baseline actual (main)**: por medir al inicio del ciclo (comando arriba)
- **DoD target**: 0 NEW failures. Fails preexistentes se documentan como no-regresión.

---

## 0. Evidencia de Gaps

### G1: `monitor-subagent.ps1` sin integración C4d — drift doc↔código
- **Fuente**: `scripts/monitor-subagent.ps1` (grep: 0 matches para `SubagentOutputFile|contract_valid`) vs `docs/mejoras/2026-08-15-subagent-result-quality.md` que documenta la integración como hecha
- **Evidencia**: Select-String sobre main HEAD 33425647 — solo matchea `check-subagent-output` (líneas 9,26,114,115,139); el parámetro `-SubagentOutputFile` y los campos `contract_valid`/`contract_detail` en `async-result.json` NO existen
- **Impacto**: la ruta de delegación asíncrona corre SIN validación de contrato 4-field; un subagente que devuelve output vacío/malformado pasa desapercibido en modo async
- **Blast Radius**: Medio
- **ICE**: 8×9×7 = 504

### G2: Índice de `docs/mejoras/` sin gate de frescura — patrón "sink" estructural
- **Fuente**: `docs/mejoras/2026-07-28-orchestrator-self-analysis.md:22` (finding #3 UNANIMOUS: "docs/mejoras es un sink"); evidencia viva 2026-08-20: ctx KB vacía + engram sin hits pese a 57 análisis
- **Evidencia**: no existe script/test que falle cuando un análisis nuevo no está referenciado en `docs/mejoras/README.md`
- **Impacto**: el Pre-Answer Evidence Gate depende de ese índice; si queda stale, el orquestador vuelve a responder sin conocimiento previo
- **Blast Radius**: Bajo
- **ICE**: 7×9×8 = 504

---

## Ciclo 1 — G1: Integración C4d en monitor-subagent.ps1

### Scope Lock
```
IN:  scripts/monitor-subagent.ps1, tests/post-delegation-async.Tests.ps1 (o nuevo test file),
     docs/mejoras/mejora-log.md, adr/
OUT: post-delegation-check.ps1 (ya correcto), check-subagent-output.ps1 (ya correcto),
     prompts/, skills/, AGENTS.md
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** | Replicar el patrón probado de post-delegation-check.ps1: parámetro `-SubagentOutputFile`, invocar cso tras detección de estabilidad, emitir `contract_valid`+`contract_detail` en async-result.json | Consistencia con ruta sync ya probada; reusa validador existente | Duplicación leve de lógica de invocación |
| **B** | Refactor: extraer validador compartido a módulo y consumirlo desde ambos | DRY | Blast radius mayor (toca ruta sync que funciona); viola minimización de riesgo |
| **C** | Solo documentar la limitación en el doc del 15-08 | Cero riesgo code | Deja el gap abierto; contradice hallazgo |

### Ganador esperado
**A** — correctness primero, mínimo blast radius. *(Sujeto a confirmación tras tests.)*

### DoD
- [ ] Tests nuevos: pass (`Invoke-Pester` sobre test file del ciclo)
- [ ] Sin regresión respecto a baseline (suite completa ×2)
- [ ] ADR escrito
- [ ] Commit: `fix(monitor): wire C4d contract validation into async monitor` (solo fix, sin mezclas)

---

## Ciclo 2 — G2: Gate de frescura del índice docs/mejoras/

### Scope Lock
```
IN:  scripts/mejoras-index-check.ps1 (nuevo), tests/mejoras-index-check.Tests.ps1 (nuevo),
     docs/mejoras/README.md (solo si el test detecta staleness real),
     docs/mejoras/mejora-log.md, adr/
OUT: skills/, prompts/, AGENTS.md, configs de runtime
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** | Script standalone + test Pester: cada `docs/mejoras/*.md` (excepto README/template/log) debe estar referenciado en README.md; exit 1 si no | Testable, fail-closed, integra a CI fácil | Mantenimiento del índice sigue siendo manual |
| **B** | Generar el índice automáticamente desde filenames | Cero mantenimiento | Pierde las columnas semánticas (dominio/hallazgos) que hacen útil el índice |
| **C** | Hook de opencode que bloquee commit | Enforcement fuerte | Toca runtime config (riesgo alto, fuera de presupuesto) |

### Ganador esperado
**A** — verificable y fail-closed sin tocar runtime. *(Sujeto a confirmación tras tests.)*

### DoD
- [ ] Tests nuevos: pass
- [ ] Sin regresión respecto a baseline (suite completa ×2)
- [ ] ADR escrito
- [ ] Commit: `feat(gate): add docs/mejoras index freshness check`

---

## Verificación Final & PR

### DoD Global (binario)
| Check | Status |
|---|---|
| Tests: 0 NEW failures (suite ×2 — verificación doble exigida por usuario) | Pendiente |
| Benchmark: N/A (sin hot-path; sustituido por doble corrida de suite) | Pendiente |
| 0 new critical/high vulns (diff review + secrets scan) | Pendiente |
| ADRs escritos (1 por ciclo) | Pendiente |
| Commits dentro de scope | Pendiente |
| Rollback map con hashes reales | Pendiente |
| Checkpoint humano en todo gap Alto | N/A — ambos gaps Medio/Bajo |

### Autorización de merge
El usuario pre-aprobó explícitamente (2026-08-20): *"al finalizar si todo verde y sin problemas merge a main pero siempre y cuando hayas realizado pruebas exhaustivas... verificados al menos dos veces"*. Ningún gap es Alto → merge directo autorizado si DoD global completo.

### Deliverables
```
docs/mejoras/plan-auto-mejora-v3-2026-08-20.md   ← ESTE ARCHIVO
docs/mejoras/mejora-log.md                        ← append ciclos
docs/mejoras/rollback-map.md                      ← append hashes
adr/                                              ← 2 ADRs mini
```

## Rollback Map
*(placeholder hasta commits reales)*
```
Commit <pendiente> fix(monitor): C4d async integration   → git revert <hash>
Commit <pendiente> feat(gate): mejoras index check        → git revert <hash>
```

*Protocolo: docs/protocolos/protocolo_mejora_autonoma_v3.md*
*Fecha: 2026-08-20*
