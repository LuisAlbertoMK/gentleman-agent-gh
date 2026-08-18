# Protocolo de Mejora Autónoma Iterativa v3
## 0. Setup
- Branch `experimento/mejora-autonoma-<fecha>` desde main. Nunca commit directo a main.
- **Fuente de verdad de gaps**: cada gap debe originarse en herramienta/evidencia concreta (SonarQube/ESLint, Sentry/logs, git churn + complejidad, deuda documentada).
- **Trazabilidad a negocio**: cada gap priorizado enlaza a ticket/issue o justificación de negocio explícita.
- **Jerarquía de métricas**: correctness > seguridad > performance > tamaño/legibilidad. Cambio que mejora métrica menor a costa de mayor rango → se rechaza.
- Baseline: valores actuales + mínimo 5-10 runs (comparar mediana/IQR, no un solo número).
- Presupuesto: máx N ciclos y/o tiempo por ciclo. Umbral: mejora marginal < X% vs ciclo previo → detener.
- **Entorno aislado**: todo ciclo (build, tests, breaker) corre en contenedor/CI efímero; nunca contra infraestructura compartida.

## 1. Priorización de gaps
- `!analisis` produce gaps con fuente de evidencia (§0) y enlace a negocio. Priorizar ICE (Impacto × Confianza × Esfuerzo) o matriz riesgo/valor.
- **Blast radius**: Bajo (estilo/lint/local sin cambio de contrato) · Medio (lógica interna, refactor con contrato estable) · Alto (contratos API, schema DB, deps core, auth/seguridad).
- Gaps de blast radius Alto requieren **checkpoint humano obligatorio** antes de implementar (no esperan al checkpoint periódico).

## 2. Roles (karpathy-loop)
Analyzer (`!analisis` + ICE + blast radius) · Implementer (scope declarado, commit atómico por tipo) · Breaker/QA (batería de ruptura en entorno aislado) · Benchmarker (métricas con significancia, jerarquía) · Documenter (log de ciclo + ADR mini + mapeo commit↔ciclo).

## 3. Ciclo (repetir hasta parada; mínimo 10 enfoques evaluados)
1. Analyzer: gaps con evidencia + ICE + blast radius.
2. **Scope lock**: declarar archivos/módulos a tocar antes de implementar; fuera de scope → justificar en ADR.
3. Generar ≥3 enfoques distintos; documentar descartados (ADR mini).
4. Implementer: enfoque elegido dentro del scope. Regla Fowler: refactor y comportamiento nunca en el mismo commit (`refactor:`/`fix:`/`feat:`). Cambios de deps → escaneo de vulnerabilidades previo.
5. Breaker/QA (aislado): fuzzing, mutation testing, carga si aplica, fault/chaos si aplica.
6. E2E completo: existentes + nuevos. Bugs preexistentes se corrigen sin excepción.
7. Benchmarker: mínimo de repeticiones §0, vs baseline y ciclo previo, jerarquía de métricas.
8. Documenter: log + ADR mini + mapeo commit↔ciclo (rollback quirúrgico §4).
9. **Definition of Done** (todo o el ciclo no cierra): tests E2E verdes · benchmark no regresivo · 0 vulnerabilidades críticas/altas nuevas · ADR escrito · commits taggeados dentro de scope.

## 4. Checkpoint humano y rollback
- Periódico cada N ciclos + obligatorio en todo gap Alto (§1).
- **Rollback**: mapeo commit↔ciclo + separación refactor/fix → cualquier ciclo se revierte aislado vía `git revert` sin afectar posteriores.

## 5. Condición de parada
Sin gaps ICE relevantes con evidencia · Breaker/QA sobrevive ≥3 enfoques · 100% E2E · benchmark ≥ baseline (jerarquía) · mejora marginal bajo umbral · presupuesto alcanzado.

## 6. Merge a main
Solo si se cumplen §5 y ningún gap Alto sin checkpoint. PR con: ciclos y enfoques evaluados, benchmarks baseline vs final (IQR), bugs preexistentes corregidos, tests añadidos, ADRs, mapeo commit↔ciclo.

## 7. Entregables
`mejora-log.md` (log por ciclo) · `benchmarks.md` (tabla baseline vs ciclo vs final) · `adr/` (ADR mini) · `rollback-map.md` (commit↔ciclo↔gap).
---
## Mejoras v3 vs. v2

| # | Gap | v2 | v3 |
|---|---|---|---|
| 1 | Fuente de gaps | subjetiva | anclada a evidencia (SonarQube/Sentry/churn/deuda) |
| 2 | Rollback | sin revertir ciclos | mapeo commit↔ciclo + separación refactor/fix |
| 3 | Blast radius | checkpoint solo "cada N" | Bajo/Medio/Alto; Alto = humano obligatorio |
| 4 | Benchmark | una corrida | 5-10 runs, mediana/IQR |
| 5 | DoD | implícito | checklist explícito y binario |
| 6 | Conflicto de métricas | sin jerarquía | correctness > seguridad > performance > tamaño |
| 7 | Scope creep | sin control | scope lock previo; desvíos → ADR |
| 8 | Entorno aislado | sin especificar | contenedor/CI efímero obligatorio |
| 9 | Trazabilidad | solo ICE | enlace a ticket/justificación de negocio |