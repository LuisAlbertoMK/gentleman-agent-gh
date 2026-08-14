# gaps-log.md — gentleman-agent-gh

**Alcance**: solo diagnóstico. Sin herramientas de análisis Go disponibles en el entorno (go.mod pide 1.25.10, toolchain bloqueado por red — `proxy.golang.org` no está en la allowlist). Evidencia obtenida por inspección manual: git churn, gofmt, grep estructural.

**Pases realizados**: 3 (churn+tamaño · deuda documentada/secretos · formato+doc-comments). Pase 3 no aportó gaps nuevos → detenido ahí.

| # | Gap | Evidencia | Categoría | Blast radius | ICE (I×C×E⁻¹) | Prioridad |
|---|---|---|---|---|---|---|
| 1 | `internal/cli/review_facade.go` (4032 líneas) es el archivo con más churn del repo en 6 meses (7 commits) — alta probabilidad de bugs por combinación tamaño+cambios frecuentes | `git log --name-only --since=6.months` + `wc -l` | correctness | Medio (lógica interna, no toca contrato público directamente) | 4×4×2=32 | Alta |
| 2 | `internal/cli/run.go` (2447 líneas, 100 funciones) — segundo en churn (6 commits), mismo patrón de concentración de complejidad | idem | correctness / legibilidad | Medio | 4×4×2=32 | Alta |
| 3 | 61% de funciones exportadas (897/1462) sin doc-comment — afecta mantenibilidad y onboarding, no funcionalidad | script de conteo sobre `^func [A-Z]` + línea previa | legibilidad-tamaño | Bajo | 2×5×4=40 (esfuerzo bajo, impacto acumulado) | Media |
| 4 | Toolchain de análisis Go (vet, build, linters) no ejecutable en este entorno — bloquea verificación automática de correctness/seguridad reales | `go build` → 403 en `proxy.golang.org` | — (limitación de evidencia, no gap del código) | N/A | N/A | Reportar, no priorizar |

## Sin hallazgos (verificado, no omitido)
- Formato (`gofmt -l .`): 0 archivos fuera de formato.
- TODO/FIXME/HACK/XXX en código no-test: 0 reales (1 falso positivo, es un regex literal).
- Secretos hardcodeados (patrón `api_key=`, `password=`, `secret=`): 0 coincidencias fuera de tests/env.

## Resumen
- Blast radius: **2 Medio** (#1, #2) · **1 Bajo** (#3) · **0 Alto**.
- Ningún gap requiere checkpoint humano obligatorio por blast radius Alto.
- Limitación real: sin `go vet`/build no puedo confirmar correctness en profundidad (nil derefs, race conditions, etc.) — el diagnóstico de #1 y #2 es por proxy (tamaño+churn), no por análisis estático directo.
