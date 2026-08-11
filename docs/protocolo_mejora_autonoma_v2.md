# Protocolo de Mejora Autónoma Iterativa v2

## 0. Setup
- Branch: `experimento/mejora-autonoma-<fecha>` desde main/master. Nunca commit directo a main/master.
- Definir **métricas de benchmark explícitas** antes de empezar (elegir las aplicables):
  - Latencia p50/p95/p99
  - Cobertura de tests (%)
  - Complejidad ciclomática
  - LOC / tamaño de bundle
  - Uso de memoria
  - Vulnerabilidades conocidas (conteo por severidad)
- Capturar **baseline**: valores actuales de cada métrica, suite de tests (pasan/fallan), bugs preexistentes conocidos.
- Definir **presupuesto**: máx N ciclos totales y/o máx tiempo por ciclo. Autonomía sin presupuesto no converge.
- Definir **umbral de rendimiento decreciente**: si la mejora marginal de un ciclo es menor a X% vs. el ciclo anterior, se detiene aunque queden gaps menores.

## 1. Priorización de gaps
`!analisis` produce lista de gaps. Antes de implementar, priorizar con scoring **ICE** (Impacto × Confianza × Esfuerzo) o matriz riesgo/valor. Atacar primero el gap de mayor score. Sin esto se malgastan ciclos en gaps cosméticos.

## 2. Roles de subagentes (karpathy-loop)
| Rol | Responsabilidad |
|---|---|
| Analyzer | Ejecuta `!analisis`, produce y prioriza gaps |
| Implementer | Codifica el enfoque elegido, un commit atómico por tipo de cambio |
| Breaker/QA | Ejecuta batería de ruptura (ver §4) |
| Benchmarker | Mide métricas definidas en §0, compara vs. baseline y vs. ciclo anterior |
| Documenter | Escribe log de ciclo + ADR mini |

Cada rol reporta a un log central compartido.

## 3. Ciclo (repetir hasta condición de parada, mínimo 10 enfoques evaluados en total)
Por ciclo:
1. **Analyzer**: `!analisis` + priorización ICE del gap a atacar.
2. Generar ≥3 enfoques distintos para ese gap. Documentar cuáles se descartan y por qué (mini ADR).
3. **Implementer**: codificar el enfoque elegido.
   - **Regla Fowler**: nunca mezclar refactor (sin cambio de contrato) con cambio de comportamiento en el mismo commit. Commits separados y etiquetados (`refactor:`, `fix:`, `feat:`).
   - Si el cambio toca dependencias → escaneo de vulnerabilidades (npm audit / Snyk / Trivy) antes de aceptar.
4. **Breaker/QA**: batería concreta, no genérica:
   - Fuzzing de inputs
   - Mutation testing (ej. Stryker)
   - Pruebas de carga si aplica performance
   - Fault/chaos injection si aplica infraestructura
5. **E2E completo**: existentes + nuevos requeridos por el cambio. Bugs preexistentes (aunque no causados por este ciclo) se corrigen antes de continuar. Cero excepciones.
6. **Benchmarker**: medir métricas de §0, comparar vs. baseline y vs. ciclo anterior. Registrar mejora/neutral/regresión.
7. **Documenter**: log del ciclo (gap, enfoques evaluados, elegido, motivo, resultado breaker, resultado E2E, benchmark) + ADR mini (decisión, alternativas descartadas, justificación).

## 4. Checkpoint humano
- Cada N ciclos (no solo al final): checkpoint de aprobación humana con resumen de avance. Evita descubrir en el ciclo 40 que el rumbo estuvo mal desde el ciclo 5.
- Full autonomía sin gates, incluso en branch experimental, es riesgo alto.

## 5. Condición de parada
Detener cuando, tras un ciclo completo:
- No quedan gaps con score ICE relevante.
- El cambio sobrevive Breaker/QA desde ≥3 enfoques de ataque distintos.
- 100% E2E (existentes + nuevos) pasan.
- Benchmark iguala o mejora baseline y ciclo previo.
- Mejora marginal del ciclo cae bajo el umbral definido en §0 (rendimiento decreciente).
- Se alcanza el presupuesto de N ciclos/tiempo definido en §0.

## 6. Merge a main/master
Solo si se cumplen las condiciones de §5. PR con:
- Ciclos ejecutados y enfoques evaluados por ciclo
- Benchmarks baseline vs. final (tabla)
- Bugs preexistentes corregidos
- Tests añadidos
- ADRs generados

## 7. Entregables
- `mejora-log.md`: log completo por ciclo (formato §3.7)
- `benchmarks.md`: tabla baseline vs. cada ciclo vs. final
- `adr/`: carpeta con ADRs mini generados durante el proceso
