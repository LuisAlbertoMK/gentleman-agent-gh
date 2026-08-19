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

---

## V3 — CI Quality Hardening (2026-08-18)

**Branch**: `experimento/mejora-autonoma-2026-08-18` · Base: main HEAD `31134225`

### Baseline (pinned en Ciclo 1, commit `e3bec66b`)

| Métrica | Valor |
|---------|-------|
| Benchmark (sync-vmk -DryRun) | 1.414s (BenchmarkSeconds, baseline refrescado) |
| Skills | 91 |
| Pester en gate | solo tests staged (sin runner dedicado) |
| Coverage | sin gate (0%, API rota en Pester 6) |
| Adversarial review | sin severidad estructurada |

### Final (medido post-Ciclo 3)

| Métrica | Baseline | Final | Delta |
|---------|----------|-------|-------|
| Benchmark mediana (×5) | 1.414s | **0.135s** | −90% (no regresivo) |
| Pester runner | ausente | `run-ci-tests.ps1` (pin 5.5.0, NUnit) | **nuevo** |
| Coverage gate | sin gate (0%) | **26.63%** (769/0 fail, floor 20%) | **nuevo** |
| Mutation smoke | ausente | `mutation-smoke.Tests.ps1` 4/4 | **nuevo** |
| Adversarial severity | block/warn sin estructura | **critical/warning/suggestion** (R1) | **nuevo** |
| Gate por commit | 22/22 | **22/22 ALL CLEAR ×3** | = |
| Tests nuevos | — | ci-pester 4/4 + mutation 4/4 + coverage-contract 5/5 + adversarial 4/4 | **+17** |

### Interpretación

- **Ciclo 1**: runner dedicado + fix `#requires` L1 (gate [2/13] solo lee 3 líneas) + fix destructivo babyagi (220/220).
- **Ciclo 2**: coverage gateaable y reproducible (Pester 5.5.0 pinneado); mutation smoke con input no-null (con `$null` la mutación `-eq`→`-ne` no es observable); smoke en proceso hijo (nested Invoke-Pester colisiona).
- **Ciclo 3**: findings con taxonomía R1 + dedup; fixture staged una vez en BeforeAll (paralelismo Pester).
- **Rendimiento**: NO regresivo — mediana final muy por debajo del baseline pinned.
- **Condición de parada**: plan §4 cumplido (3/3 ciclos + entregables + rollback map con hashes reales). Pendiente solo PR a main (sin mergear sin orden explícita).

---

## C2 — Skill Bloat Compression (2026-08-19)

**Branch**: `experimento/mejora-autonoma-2026-08-19` · Base: main HEAD

### Baseline (pre-C2)

| Métrica | Valor |
|---------|-------|
| SE (Skill Efficiency) | 6.0 |
| o5 (skills >5KB) | 22 |
| o3 (skills >3KB) | 57 |
| Avg skill size | 3.9KB |
| Total skills | 91 |
| 22 skills total bytes | 135,202 |

### Final (post-C2 compression)

| Métrica | Baseline | Final | Delta |
|---------|----------|-------|-------|
| SE | 6.0 | **7.0** | +1.0 |
| o5 | 22 | **0** | −22 (target ≤2 ✓) |
| o3 | 57 | **39** | −18 (target 46 ✓) |
| Avg skill size | 3.9KB | **3.0KB** | −0.9KB (target <3.5KB ✓) |
| 22 skills total bytes | 135,202 | **52,547** | −61% |
| Total skills | 91 | 91 | = |

### Method
Karpathy-loop compression + reference.md externalization:
- 22 skills compressed: verbose sections (Examples, Testing Patterns, Edge Cases, Anti-Patterns) moved to `docs/skills/{skill}/reference.md`
- SKILL.md retains: frontmatter, core workflow, constraints, rules, cross-refs
- Single reference link: `> See [reference.md](docs/skills/{skill}/reference.md) for extended details, examples, and detailed patterns.`
- Constraints: NO frontmatter changes, NO broken cross-refs, NO essential workflow removal, SKILL.md ≥200 lines

### Verification
- `score-auto -Json`: SE=7.0, o5=0, o3=39, avg=3.0KB
- `cross-ref-check`: 9/9 OK
- `Pester cross-ref.Tests.ps1`: 4/4 passed

---

## C3 — Config Context Budget Trim (2026-08-19)

**Branch**: `experimento/mejora-autonoma-2026-08-19` · Base: main HEAD

### Baseline (pre-C3)

| Métrica | Valor |
|---------|-------|
| Config size | 58,626B |
| % of 65,536B limit | 89.7% |
| Agent count | 55 |
| SE (Skill Effectiveness) | 7.0 |
| PA (Project Artifacts) | 8.0 |

### Final (post-C3 trim)

| Métrica | Baseline | Final | Delta |
|---------|----------|-------|-------|
| Config size | 58,626B | **41,704B** | −16,922B (−28.9%) |
| % of 65,536B limit | 89.7% | **63.6%** | −26.1pp (target <85% ✓) |
| Agent count | 55 | **49** | −6 (semi removed) |
| SE | 7.0 | **7.0** | = |
| PA | 8.0 | **8.0** | = |

### Method

- Removed 6 unused `-semi` agents (ADR-033: semi mode never used)
- Removed disabled MCP servers (`headroom`, `chrome-devtools-mcp`)
- Removed top-level `tools` disables (redundant per-agent overrides)
- All 42 functional agents preserved, routing/permissions/MCP intact

### Verification

- `score-auto -Json`: SE=7.0, PA=8.0, overall=8.8
- `cross-ref-check`: 9/9 OK
- `Pester cross-ref.Tests.ps1`: 9/9 passed
- JSON validity: confirmed via parse + key agent presence check