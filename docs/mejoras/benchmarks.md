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

| Métrica | Baseline | Ciclo 1 (tests) | Ciclo 2 (security) | Ciclo 3 (docs) | Ciclo 4 (doc standard) | Ciclo 5 (root) | Delta total |
|---------|----------|-----------------|---------------------|-----------------|------------------------|----------------|-------------|
| Test files | 3 | **8** | **8** (+3 modificados) | 8 | **9** (+script-documentation) | 9 | **+200%** |
| Tests totales | ~16 | **86** (81 pasan en gate; 5 archivos en commit test) | **44 focalizados** (subsuite permisos) | 44 | **96** (+10 enforcement) | 96 | **+500%** |
| Pass rate | 100% | 100% | 100% | 100% | 100% | 100% | = |
| Scripts críticos cubiertos | 0/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | **+100%** |
| Deny rules en SSoT | 84 | 84 | **92** | 92 | 92 | 92 | **+8 reglas** |
| README onboarding self-contained | ❌ (solo link a QUICKSTART) | ❌ | ❌ | **✅ 3 secciones** | ✅ | ✅ | **cerrado** |
| Scripts con help completo garantizado | 2/91 | 2/91 | 2/91 | 2/91 | **3 registrados + enforcement** | 3 | **+1 + gate** |
| Basura trackeada en root | `$null` + sospechosos | presente | presente | presente | presente | **0** | **limpio** |

## Gaps Cerrados por Ciclo

| Ciclo | Gap | Score ICE | Evidencia |
|-------|-----|-----------|-----------|
| 1 | Testing coverage | 486 | 5 test files nuevos, 86 tests, fix 2 bugs hooks |
| 2 | Auto-mode bash restrictions | 256 | 8 deny rules bare/wildcard (bun/pnpm/yarn/pip3) |
| 3 | README onboarding | 189 | README.md:27-60 (+37 líneas), comandos verificados contra filesystem |
| 4 | Script documentation consistency | 280 | Standard + enforcement Pester 10/10 + 2 scripts con params documentados |
| 5 | Root-level cleanup | 108 | `$null` 0B eliminado del índice, 4 logs fuera del disco, .gitignore defensivo |

## Interpretación

- **Ciclo 1**: mejora grande en cobertura de tests (+166% archivos, +437% tests). Sin regresión.
- **Ciclo 2**: mejora en seguridad (8 deny rules nuevas — cierra bypass bare de bun/pnpm/yarn/pip3 en auto-mode) con estabilidad de tests (44/subsuita permisos, 0 failed).
- **Ciclo 3**: docs — README ahora self-contained para onboarding; comandos referenciados verificados (install.sh, switch-mode.ps1 existen; default manual coincide con permission-gate-lib.ps1:189).
- **Ciclo 4**: enforcement de documentación de scripts — el registry garantiza que 3 scripts NUNCA pierdan help completo sin bloquear el gate.
- **Ciclo 5**: cleanup de root — análisis reveló clutter menor al reportado (logs ya ignorados); fix anti-recurrencia del archivo zombie `$null`.
- **Rendimiento decreciente**: NO alcanzado — los 5 ciclos ganaron 100% de su gap respectivo.
- **Condición de parada**: presupuesto agotado (5/5 ciclos, ~135/225 min). Protocolo completo.