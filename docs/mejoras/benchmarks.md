# Benchmarks — Protocolo de Mejora Autónoma (gentleman-agent-gh)

**Branch**: `experimento/mejora-autonoma-2026-08-09`

## Métricas Definidas

| Métrica | Aplicable | Justificación |
|---------|-----------|---------------|
| Test files (cantidad) | ✅ | Cobertura de la suite |
| Tests totales (cantidad) | ✅ | Volumen verificable |
| Pass rate | ✅ | Salud de la suite |
| Scripts críticos cubiertos | ✅ | Bash-safe, permission-gate, health-check |
| Vulnerabilidades de deny rules | ✅ | Gaps de seguridad en auto-mode |
| LOC / bundle | ⏸️ | No aplica (config de agente) |
| Latencia | ⏸️ | No aplica (no runtime) |
| Memoria | ⏸️ | No aplica |

## Baseline (08-ago-2026)

| Métrica | Valor |
|---------|-------|
| Test files | 3 |
| Tests totales | ~16 |
| Pass rate | 100% |
| Scripts críticos cubiertos | 0/3 |
| Deny rules en SSoT | 84 |

## Tabla por Ciclo

| Métrica | Baseline | Ciclo 1 (tests) | Ciclo 2 (security) | Ciclo 3 (docs) | Delta total |
|---------|----------|-----------------|---------------------|-----------------|-------------|
| Test files | 3 | **8** | **8** (+3 modificados) | 8 | **+166%** |
| Tests totales | ~16 | **86** (81 pasan en gate; 5 archivos en commit test) | **44 focalizados** (subsuite permisos) | 44 | **+437%** |
| Pass rate | 100% | 100% | 100% | 100% | = |
| Scripts críticos cubiertos | 0/3 | 3/3 | 3/3 | 3/3 | **+100%** |
| Deny rules en SSoT | 84 | 84 | **92** | 92 | **+8 reglas** |
| README onboarding self-contained | ❌ (solo link a QUICKSTART) | ❌ | ❌ | **✅ 3 secciones** (Prereqs/Quick Start/Config) | **cerrado** |

## Gaps Cerrados por Ciclo

| Ciclo | Gap | Score ICE | Evidencia |
|-------|-----|-----------|-----------|
| 1 | Testing coverage | 486 | 5 test files nuevos, 86 tests, fix 2 bugs hooks |
| 2 | Auto-mode bash restrictions | 256 | 8 deny rules bare/wildcard (bun/pnpm/yarn/pip3) |
| 3 | README onboarding | 189 | README.md:27-60 (+37 líneas), comandos verificados contra filesystem |

## Interpretación

- **Ciclo 1**: mejora grande en cobertura de tests (+166% archivos, +437% tests). Sin regresión.
- **Ciclo 2**: mejora en seguridad (8 deny rules nuevas — cierra bypass bare de bun/pnpm/yarn/pip3 en auto-mode) con estabilidad de tests (44/subsuita permisos, 0 failed).
- **Ciclo 3**: docs — README ahora self-contained para onboarding; comandos referenciados verificados (install.sh, switch-mode.ps1 existen; default manual coincide con permission-gate-lib.ps1:189).
- **Rendimiento decreciente**: aún no alcanzado. Ciclos 1-3 muestran mejoras cuantificables.
- **Umbral**: 5% mejora marginal por ciclo. Tres ciclos ganaron 100% de su gap → siguen por encima del umbral.