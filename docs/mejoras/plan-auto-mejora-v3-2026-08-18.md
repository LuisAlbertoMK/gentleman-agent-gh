# Plan: Auto-Mejora Autónoma v3 — 2026-08-18 (Calidad de código + CI/CD)

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Base**: `main` HEAD `6e1741df` · **Branch**: `experimento/mejora-autonoma-2026-08-18`
**Presupuesto**: 3 ciclos max · 25 tool calls/ciclo · modelos free-tier
**Escalado**: correctness > security > performance > size (§0.6)

## Research 5x5 (2026-08-18) — 5 enfoques externos verificados

| # | Enfoque | Fuente | Insight aplicable |
|---|---------|--------|-------------------|
| R1 | **AI code review orquestado**: 7 reviewers especializados + coordinator, findings XML con severidad (critical/warning/suggestion), dedup, circuit breakers, "break glass" | Cloudflare Blog (2026-04) | Revisión estructurada con severidad explícita + coordinador que filtra falsos positivos |
| R2 | **Coverage merge protection + security scanning en CI**: branch rulesets bloquean merge si coverage cae; SCA + secrets + SAST | GitHub Changelog (2026-06) + Vulert (2026-06) | Gate de coverage a nivel pipeline, no solo local |
| R3 | **Pester en CI/CD robusto**: `Run.Exit=$true`, NUnit XML publish, Pester pinneado, `shell: pwsh`, script central `run-ci-tests.ps1` | Keith Ramsey (2026-06) | CI no debe depender del exit code implícito de Invoke-Pester; resultados publicables |
| R4 | **Mutation testing delta-first**: mutantes + score, gate gradual por equipo, complementa coverage (coverage dice "qué se ejecuta", mutation "qué se detecta") | Mercado Libre Tech (2026-01) | Mide fuerza real del test suite, no solo cobertura |
| R5 | **TDD-Agent / self-verification**: test-first reasoning, iteración dual code+tests con execution feedback; ReVeal: generación-verificación iterativa | arXiv TDD-Agent + MS Research ReVeal (ICLR 2026) | Tests como artefactos en evolución, no validadores estáticos |

## 0. Evidencia de Gaps (repo + research)

### G1: CI Pester no es robusto — sin pin, sin Run.Exit, sin publish
- **Fuente repo**: `.github/workflows/ci.yml` jobs `tests` usa `Invoke-Pester -PassThru` + `$results.FailedCount` (L24-27), SIN pin de versión, SIN `Run.Exit`, SIN NUnit XML publish, SIN coverage.
- **Fuente externa**: R3 (Keith Ramsey 2026) — `Run.Exit = $true` es el patrón robusto; pinning evita drift de Pester.
- **Blast Radius**: **Bajo** (CI only, no cambia contrato)
- **ICE**: 9×9×8 = 648

### G2: Sin gate de coverage ni mutation score en pipeline
- **Fuente repo**: `coverage.xml` existe en root (generado por `scripts/tests/Coverage.ps1`) pero CI no lo publica ni lo gating; no hay mutation testing.
- **Fuente externa**: R2 (GitHub coverage merge protection 2026-06) + R4 (Mercado Libre delta-first mutation).
- **Blast Radius**: **Medio** (nuevo job CI, no rompe contratos)
- **ICE**: 8×8×6 = 384

### G3: Breaker/adversarial review sin severidad estructurada
- **Fuente repo**: `.breaker-cleared/` markers existen, gate check [22/22] adversarial-breaker profile scan existe, pero el output de review no tiene clasificación de severidad machine-readable (critical/warning/suggestion).
- **Fuente externa**: R1 (Cloudflare — findings XML con severidad + coordinator dedup).
- **Blast Radius**: **Bajo** (formato de salida, sin cambio de contrato)
- **ICE**: 8×7×7 = 392

---

## 1. Ciclo 1 — G1: CI Pester robusto (R3)

### Scope Lock
```
IN:  .github/workflows/ci.yml (jobs tests: pin + Run.Exit + publish NUnit)
     scripts/tests/ci-pester.Tests.ps1 (nuevo: verifica config Run.Exit)
OUT: todo lo demás
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (Pin + Exit inline) | `Install-Module Pester -RequiredVersion 5.5.0` + `-Configuration @{Run.Exit=$true}` inline en job | Mínimo diff, robusto | Duplica config en cada job |
| **B** (run-ci-tests.ps1) | Script central `scripts/run-ci-tests.ps1` con New-PesterConfiguration (Run.Exit, NUnit XML, CodeCoverage) + workflow thin | Patrón R3 exacto, reusable local+CI | +1 archivo |
| **C** (Solo pin) | Pin versión sin Run.Exit ni publish | Mínimo absoluto | No arregla exit code implícito |

### Ganador esperado
**B** — patrón R3 completo (thin pipeline + script local reutilizable + NUnit publish).

### DoD
- [ ] `ci-pester.Tests.ps1` 3/3 pass (Run.Exit present, version pin, NUnit enabled)
- [ ] Job tests usa `run-ci-tests.ps1` con `shell: pwsh`
- [ ] Gate local 22/22 ALL CLEAR

---

## 2. Ciclo 2 — G2: Coverage gate + mutation score delta-first (R2+R4)

### Scope Lock
```
IN:  .github/workflows/ci.yml (job coverage: publish coverage.xml + fail si coverage < umbral)
     scripts/tests/Coverage.ps1 (revisar output JaCoCo)
     scripts/tests/mutation-smoke.Tests.ps1 (nuevo: smoke mutation — mutante muerto)
OUT: todo lo demás
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (Coverage gate) | Job CI calcula coverage vía `-CodeCoverage` de Pester, publica artifact, falla < 40% | Gate real, R2 | Coverage parcial en PowerShell |
| **B** (Mutation smoke) | Script mutation-test.ps1: muta operador (`-eq`→`-ne`) en función target, corre tests, exige mutant killed | R4 delta-first, mide fuerza | Acotado a 1-2 funciones |
| **C** (A+B) | Coverage gate + mutation smoke juntos | Máxima cobertura del gap | 2 archivos nuevos |

### Ganador esperado
**C** — cubre R2 (gate) y R4 (fuerza) sin sobre-ingeniería.

### DoD
- [ ] Job coverage en ci.yml con publish + umbral
- [ ] `mutation-smoke.Tests.ps1` 2/2 pass (mutant killed en función target)
- [ ] Gate local 22/22 ALL CLEAR

---

## 3. Ciclo 3 — G3: Review con severidad estructurada (R1)

### Scope Lock
```
IN:  scripts/adversarial-review.ps1 (nuevo: wrapper que emite findings JSON con severity)
     scripts/tests/adversarial-review.Tests.ps1 (nuevo)
OUT: todo lo demás
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (JSON severity) | Wrapper que corre breaker + PSScriptAnalyzer y emite findings `{severity, rule, file, line}` | Machine-readable, R1 | Requiere parseo de fuentes |
| **B** (Markdown severity) | Output markdown con secciones Critical/Warning/Suggestion | Simple, legible | No consumible por CI fácilmente |
| **C** (A + coordinador) | JSON + dedup por rule/file | R1 completo (coordinator) | +complejidad |

### Ganador esperado
**A** — machine-readable sin sobre-ingeniería (dedup se puede agregar después).

### DoD
- [ ] `adversarial-review.Tests.ps1` 3/3 pass (severity present, JSON parseable, exit code)
- [ ] Script corre en CI o local sin errores
- [ ] Gate local 22/22 ALL CLEAR

---

## 4. Verificación Final & Entregables

| Check | Método |
|-------|--------|
| Benchmark no regresivo | `Measure-Command { sync-vmk.ps1 -DryRun }` ×5 baseline vs final (mediana) |
| Pester 0 NEW failures | Baseline 669 pass/7 fail conocidos (fuera de scope, documentados) |
| Gate 22/22 | pre-commit-gate en cada commit |
| ADR mini | `adr/ADR-030-ci-quality-hardening-2026-08-18.md` |
| mejora-log.md | append Ciclos 1-3 |
| benchmarks.md | tabla baseline vs final |
| rollback-map.md | commit ↔ ciclo |

### Deliverables
```
docs/mejoras/plan-auto-mejora-v3-2026-08-18.md   ← ESTE ARCHIVO
.github/workflows/ci.yml                          ← Ciclo 1+2
scripts/run-ci-tests.ps1                          ← Ciclo 1
scripts/adversarial-review.ps1                    ← Ciclo 3
scripts/tests/ci-pester.Tests.ps1                 ← Ciclo 1
scripts/tests/mutation-smoke.Tests.ps1            ← Ciclo 2
scripts/tests/adversarial-review.Tests.ps1        ← Ciclo 3
adr/ADR-030-ci-quality-hardening-2026-08-18.md    ← ADR mini
docs/mejoras/mejora-log.md                        ← append
docs/mejoras/benchmarks.md                        ← actualizar
docs/mejoras/rollback-map.md                      ← actualizar
```

## 5. Rollback Map (se completa con hashes reales post-commit)

| Commit (pendiente) | Ciclo | Revert |
|---|---|---|
| `feat(ci): robust Pester run + NUnit publish` | 1 | `git revert <hash>` |
| `feat(ci): coverage gate + mutation smoke` | 2 | `git revert <hash>` |
| `feat(review): adversarial findings with severity` | 3 | `git revert <hash>` |

---
*Protocolo: docs/protocolos/protocolo_mejora_autonoma_v3.md · Fecha: 2026-08-18*
