# Protocolo de Mejora Autónoma Iterativa (N-ciclos)

> ⚠️ **DEPRECATED** — superseded by [protocolo_mejora_autonoma_v3.md](./protocolo_mejora_autonoma_v3.md). Kept for historical reference only. Do not follow this version.


## 0. Setup
- Crear branch `experimento/mejora-autonoma-<fecha>` desde main/master. Nunca commitear directo a main/master.
- Registrar baseline: benchmarks actuales, suite de tests actual (pasan/fallan), bugs preexistentes conocidos.

## 1. Ciclo (repetir N veces, mínimo 10 enfoques distintos en total)
Por cada ciclo:
1. `!analisis` — mapear gaps: optimizaciones, reducción de código, arquitectura, seguridad, deuda técnica, bugs (propios o preexistentes).
2. Generar ≥3 enfoques distintos para el gap priorizado.
3. Implementar el enfoque elegido en un commit atómico dentro del branch experimental.
4. `!breaker` — intentar romper el cambio (edge cases, carga, inputs inválidos, regresión).
5. Ejecutar suite E2E completa (existente + nuevos tests requeridos por el cambio). Si algo falla — incluyendo bugs preexistentes no causados por este cambio — corregir antes de continuar. Cero excepciones.
6. Benchmark vs. baseline y vs. ciclo anterior. Registrar resultado (mejora/neutral/regresión).
7. Log de aprendizaje: qué funcionó, qué no, por qué, restricción nueva a aplicar en próximos ciclos.

## 2. Subagentes / karpathy-loop
Usar karpathy-loop con subagentes especializados (o generales si no aplica especialización) para paralelizar análisis, implementación y verificación por ciclo. Cada subagente reporta al log central.

## 3. Condición de parada
Detener solo cuando, tras un ciclo completo:
- No quedan gaps nuevos detectables por `!analisis`.
- El cambio propuesto sobrevive `!breaker` desde ≥3 enfoques de ataque distintos.
- 100% de tests E2E (existentes + nuevos) pasan.
- Benchmark iguala o mejora el ciclo previo.

Si alguna condición falla, continuar con más ciclos.

## 4. Merge a main/master
Solo si TODAS las condiciones de parada se cumplen y el benchmark acumulado es igual o mejor que baseline. Merge vía PR con resumen de: ciclos ejecutados, enfoques probados, benchmarks (antes/después), bugs preexistentes corregidos, tests añadidos.

## 5. Entregable final
- Log completo de ciclos (`mejora-log.md`): fecha, gap, enfoques evaluados, elegido, resultado breaker, resultado E2E, benchmark, aprendizaje.
- Tabla resumen benchmark baseline vs. final.
