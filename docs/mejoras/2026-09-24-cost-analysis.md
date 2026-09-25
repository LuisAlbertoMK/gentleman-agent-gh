# Análisis de coste corregido — variantes de razonamiento (R11-S4 re-scopeado)

> Fecha: 2026-09-24. Rama: `experimento/mejora-ronda11-deuda`. Fuente: `opencode.db` read-only (orquestador; NO re-medir).
> Corrige la premisa R10/R11 §3 S4 ("cap/routeo laguna-high"). Tier 2 docs-only: sin enforcement, sin cambio de config.

## 1. Coste por modelo/variante (agregado histórico, TOTAL $5.311 / 1241 sessions)

| modelo/variante | sess | coste | ventana | estado |
|---|---|---|---|---|
| glm-5.3-flash/max | 11 | $2.550 | 2026-09-01..09-04 | MUERTO |
| laguna-s-2.1-free/high | 75 | $1.155 | 2026-08-12..08-27 | MUERTO (~4 sem) |
| muse-spark-1.2-contributor-free/xhigh | 18 | $0.794 | 2026-08-27..09-04 | MUERTO |
| muse-spark-1.3-contributor-free/high | 27 | $0.376 | 2026-09-18..09-24 | ACTIVO |
| deepseek-v4.1-flash/high | 1 | $0.225 | 2026-09-24 | ACTIVO |

Últimos 14 días: **$0.794 total** (muse-1.3-free/high $0.376 + deepseek-v4.1/high $0.225 + mimo $0.110 + deepseek-v4-flash $0.056 + muse/default $0.027).

Modelos FREE (coste $0.000): nemotron-3-ultra-free (315 sess), big-pickle (217), muse-spark-1.3-free/default (180), muse-spark-1.2-free/default (141), deepseek-v4-flash-free (79), mimo-v2.5-free (95).

## 2. Hallazgo: las VARIANTES dominan el gasto, no los modelos base

El coste lo generan las variantes de razonamiento (`high`/`xhigh`/`max`) — incluso sobre modelos base "free". Los modelos base en variante `default`/free registran $0.000 con cientos de sesiones. Optimizar = elegir variante, no cambiar de modelo.

## 3. Corrección: premisa "laguna-high outlier activo" = STALE

R10 D1 / R11 §3 S4 trataban `laguna-s-2.1-free/high` ($1.155, 75 sess) como outlier vigente. **Falso al 2026-09-24:** su ventana terminó el 2026-08-27 (~4 semanas atrás). Es gasto histórico, NO un leak activo. Futuras rondas: verificar ventana temporal antes de proponer caps — no re-descubrir este outlier.

## 4. Guía de variante (sin enforcement)

- Preferir variante `default` salvo necesidad real de razonamiento profundo.
- El `small_model` ya está configurado en el SSoT (`scripts/lib/opencode-base.json:3` = `opencode/muse-spark-1.3-contributor-free`) para tareas ligeras — usarlo, no reconfigurarlo.
- NO se cambia ningún modelo ni variante en este slice (solo documentar).

## 5. Por qué NO hay cap duro

1. Las sesiones largas son legítimas (R11 D1c: TOP5 con 8M+ tokens en sesiones reales).
2. El gasto activo es bajo ($0.794/14d) — un cap rompería más de lo que ahorra.
3. Atribución skill/ruta imposible con el schema actual (R11 D1c `low`) — un cap no sabría a qué apuntar.
