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

| Métrica | Baseline | Ciclo 1 (tests) | Ciclo 2 (security) | Delta total |
|---------|----------|-----------------|---------------------|-------------|
| Test files | 3 | **8** | **8** (+3 modificados) | **+166%** |
| Tests totales | ~16 | **86** (81 pasan en gate; 5 archivos en commit test) | **44 focalizados** (subsuite permisos) | **+437%** |
| Pass rate | 100% | 100% | 100% | = |
| Scripts críticos cubiertos | 0/3 | 3/3 | 3/3 | **+100%** |
| Deny rules en SSoT | 84 | 84 | **92** | **+8 reglas** |

## Interpretación

- **Ciclo 1**: mejora grande en cobertura de tests (+166% archivos, +437% tests). Sin regresión.
- **Ciclo 2**: mejora en seguridad (8 deny rules nuevas — cierra bypass bare de bun/pnpm/yarn/pip3 en auto-mode) con estabilidad de tests (44/subsuita permisos, 0 failed).
- **Rendimiento decreciente**: aún no alcanzado. Ciclos 1-2 muestran mejoras cuantificables.
- **Umbral**: 5% mejora marginal por ciclo. Ciclo 2 ganó 100% del gap de package-manager → sigue por encima del umbral.