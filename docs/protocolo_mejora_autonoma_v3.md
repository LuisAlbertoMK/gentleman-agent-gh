# Protocolo de Mejora Autónoma Iterativa v3

## 0. Setup
- Branch: `experimento/mejora-autonoma-<fecha>` desde main/master. Nunca commit directo a main/master.
- **Fuente de verdad de gaps** (nuevo v3): cada gap debe originarse en herramienta/evidencia concreta:
  - Calidad estática: SonarQube / ESLint / equivalente
  - Bugs reales: Sentry / logs de producción / issues abiertos
  - Hotspots: `git churn` + complejidad (archivos que más cambian y más complejos)
  - Deuda técnica documentada (TODOs, ADRs previos, backlog)
- **Trazabilidad a negocio** (nuevo v3): cada gap priorizado debe enlazar a un ticket/issue o justificación de negocio explícita. No se optimiza código sin razón de negocio o riesgo asociado.
- Métricas de benchmark explícitas (elegir aplicables): latencia p50/p95/p99, cobertura de tests (%), complejidad ciclomática, LOC/tamaño de bundle, uso de memoria, vulnerabilidades por severidad.
- **Jerarquía de métricas** (nuevo v3), para resolver conflictos entre ellas: correctness > seguridad > performance > tamaño/legibilidad. Si un cambio mejora una métrica de menor rango a costa de una de mayor rango, se rechaza.
- Baseline: valores actuales de cada métrica + **mínimo de repeticiones para significancia estadística** (nuevo v3: 5–10 runs, comparar mediana/IQR, no un solo número).
- Presupuesto: máx N ciclos totales y/o máx tiempo por ciclo.
- Umbral de rendimiento decreciente: mejora marginal < X% vs. ciclo anterior → detener.
- **Entorno de ejecución aislado** (nuevo v3): todo el ciclo (build, tests, breaker) corre en contenedor/CI efímero. Nunca contra infraestructura compartida (DB, APIs externas reales).

## 1. Priorización de gaps
`!analisis` produce lista de gaps, cada uno con fuente de evidencia (§0) y enlace a negocio. Priorizar con ICE (Impacto × Confianza × Esfuerzo) o matriz riesgo/valor.

**Clasificación de blast radius** (nuevo v3): cada gap se etiqueta Bajo / Medio / Alto según qué toca:
- Bajo: estilo, lint, código local sin cambio de contrato
- Medio: lógica interna, refactors con contrato estable
- Alto: contratos de API, schema de DB, dependencias core, auth/seguridad

Gaps de blast radius Alto requieren checkpoint humano **obligatorio** antes de implementar (no esperan al checkpoint periódico de §4).

## 2. Roles de subagentes (karpathy-loop)
| Rol | Responsabilidad |
|---|---|
| Analyzer | `!analisis`, produce gaps con evidencia + prioriza (ICE + blast radius) |
| Implementer | Codifica el enfoque elegido, respeta scope declarado, un commit atómico por tipo de cambio |
| Breaker/QA | Batería de ruptura en entorno aislado |
| Benchmarker | Mide métricas con significancia estadística, aplica jerarquía de métricas |
| Documenter | Log de ciclo + ADR mini + mapeo commit↔ciclo |

## 3. Ciclo (repetir hasta condición de parada, mínimo 10 enfoques evaluados en total)
1. **Analyzer**: `!analisis` con evidencia + priorización ICE + blast radius.
2. **Scope lock** (nuevo v3): declarar explícitamente qué archivos/módulos se van a tocar antes de implementar. Cualquier archivo fuera de scope requiere justificación en el ADR.
3. Generar ≥3 enfoques distintos. Documentar descartados y por qué (ADR mini).
4. **Implementer**: codificar el enfoque elegido dentro del scope declarado.
   - Regla Fowler: refactor y cambio de comportamiento nunca en el mismo commit. Tags `refactor:`, `fix:`, `feat:`.
   - Cambios de dependencias → escaneo de vulnerabilidades (npm audit / Snyk / Trivy) antes de aceptar.
5. **Breaker/QA** (en entorno aislado): fuzzing de inputs, mutation testing, pruebas de carga si aplica, fault/chaos injection si aplica infraestructura.
6. **E2E completo**: existentes + nuevos. Bugs preexistentes se corrigen sin excepción.
7. **Benchmarker**: medir con mínimo de repeticiones definido en §0, comparar vs. baseline y ciclo anterior, resolver conflictos con jerarquía de métricas.
8. **Documenter**: log de ciclo + ADR mini + mapeo commit↔ciclo (para rollback quirúrgico, ver §4.1).
9. **Definition of Done del ciclo** (nuevo v3) — todo debe cumplirse o el ciclo no se cierra:
   - [ ] Tests E2E en verde
   - [ ] Benchmark no regresivo (según jerarquía de métricas)
   - [ ] 0 vulnerabilidades críticas/altas nuevas
   - [ ] ADR escrito
   - [ ] Commits taggeados y dentro de scope declarado

## 4. Checkpoint humano y rollback
- Checkpoint periódico cada N ciclos + checkpoint obligatorio en todo gap de blast radius Alto (§1).
- **Rollback plan** (nuevo v3): gracias al mapeo commit↔ciclo (§3.8) y a la separación refactor/fix, cualquier ciclo puede revertirse de forma aislada vía `git revert` sin afectar ciclos posteriores no relacionados.

## 5. Condición de parada
- No quedan gaps con score ICE relevante y evidencia real.
- Sobrevive Breaker/QA desde ≥3 enfoques de ataque distintos.
- 100% E2E pasan.
- Benchmark iguala o mejora baseline y ciclo previo (respetando jerarquía de métricas).
- Mejora marginal bajo el umbral definido.
- Presupuesto de ciclos/tiempo alcanzado.

## 6. Merge a main/master
Solo si se cumplen condiciones de §5 y ningún gap Alto pendiente sin checkpoint humano. PR con:
- Ciclos ejecutados y enfoques evaluados
- Benchmarks baseline vs. final (con repeticiones/IQR)
- Bugs preexistentes corregidos
- Tests añadidos
- ADRs generados
- Mapeo commit↔ciclo

## 7. Entregables
- `mejora-log.md`: log completo por ciclo
- `benchmarks.md`: tabla baseline vs. cada ciclo vs. final (con significancia estadística)
- `adr/`: ADRs mini
- `rollback-map.md`: mapeo commit↔ciclo↔gap

---

## Mejoras v3 vs. v2

| # | Gap detectado | v2 | v3 |
|---|---|---|---|
| 1 | Fuente de gaps indefinida | `!analisis` sin origen especificado, subjetivo | Gaps anclados a evidencia: SonarQube/ESLint, Sentry/logs, git churn, deuda documentada |
| 2 | Sin rollback plan | Solo "branch experimental", sin revertir ciclos individuales | Mapeo commit↔ciclo + separación refactor/fix → rollback quirúrgico por ciclo |
| 3 | Sin control de blast radius | Checkpoint humano solo "cada N ciclos" | Clasificación Bajo/Medio/Alto por gap; Alto = checkpoint humano obligatorio, no esperar al periódico |
| 4 | Benchmark sin significancia estadística | Comparación de una sola corrida | Mínimo 5–10 runs, mediana/IQR, no valor único |
| 5 | Sin Definition of Done | Checklist implícito, disperso en el texto | DoD explícito y binario al cierre de cada ciclo |
| 6 | Sin resolución de conflicto entre métricas | Métricas comparadas sin jerarquía | Jerarquía explícita: correctness > seguridad > performance > tamaño |
| 7 | Sin control de scope creep | Nada impide tocar módulos no relacionados | Scope lock declarado antes de implementar; desvíos requieren justificación en ADR |
| 8 | Sin entorno aislado para pruebas destructivas | Breaker/E2E sin especificar dónde corren | Entorno efímero (contenedor/CI) obligatorio, nunca contra infra compartida |
| 9 | Sin trazabilidad a negocio | Priorización solo técnica (ICE) | Cada gap debe enlazar a ticket/issue o justificación de negocio |
