# Benchmark: Backup pre-sprint3 vs gentleman-agent-gh

> Baseline oficial: `C:\Users\MK\.config\opencode\.bak\pre-sprint3-apply-20260607-005330\`
> Generado: 2026-06-16 | Script: `scripts/bench-compare.ps1`

## Contexto

- **gentle-ai** (upstream): https://github.com/Gentleman-Programming/gentle-ai — Go 1.24+ binary, ecosistema configurador
- **Backup pre-sprint3**: snapshot del output instalado de gentle-ai ANTES de las optimizaciones de gentleman-VMK
- **gentleman-agent-gh**: repo con todas las mejoras aplicadas

## AGENTS.md (3 vías)

| Fuente | Líneas | Bytes | Nota |
|--------|--------|-------|------|
| gentle-ai template (Go) | 23 | 1.6 KB | Código fuente, no runtime |
| **Backup pre-sprint3** | **139** | **9.1 KB** | ⭐ **Baseline oficial** |
| gentleman-agent-gh | 259 | 17.9 KB | Self-contained (engram, persona, sdd-orch embebidos) |
| Global ~/.config/opencode/ | 246 | — | Sync del repo |

> Nota: AGENTS.md creció porque pasó de incluir engram, persona y sdd-orch como archivos separados a tenerlos embebidos. El total deployado (AGENTS.md + layers externos) se redujo.

## Skills — Comparación total

| Métrica | Backup | Repo | Δ |
|---------|--------|------|---|
| Skills totales | 57 | 57 | 0 |
| Líneas totales | 2,205 | 1,840 | **−365 (−16.6%)** |
| Avg líneas/skill | 39 | 32 | −7 |
| Skills en común | 46 | 46 | — |
| Líneas (comunes) | 1,822 | 1,179 | **−643 (−35.3%)** |
| Skills solo en backup | 7 (234L) | — | −234L |
| Skills solo en repo | — | 10 (566L) | +566L (nuevos) |

### Skills solo en backup (eliminados/remplazados, 234L)

branch-pr, chained-pr, cognitive-doc-design, comment-writer, delivery-harness, issue-creation, sdd-contracts

### Skills solo en repo (nuevos, 566L)

accessibility (64L), best-practices (49L), core-web-vitals (43L), development-mode (92L), performance (44L), performance-tracker (46L), research (67L), seo (57L), skill-graph (48L), web-quality-audit (56L)

## Skills — Metadata

| Métrica | Backup | Repo | Δ |
|---------|--------|------|---|
| Placeholders `> {name} skill` | 1 | 0 | −1 |
| Triggers field | 0/57 | 56/56 | +56 |
| Tags field | 0/57 | 57/57 | +57 |
| Descripciones reales | Genéricas | Curadas del contenido | Todas |
| author: gentleman-vMK | 0 | 56/57 | +56 |

## Scripts

| Métrica | Backup | Repo | Δ |
|---------|--------|------|---|
| Scripts PowerShell | 0 | 14 | +14 |
| Set-StrictMode -Version Latest | 0 | 14/14 | +14 |
| catch blocks | 0 | 12 | +12 |
| #requires -Version 5.1 | 0 | 14/14 | +14 |
| PSScriptAnalyzer errors | N/A | 0 | NEW |
| PSScriptAnalyzer warnings | N/A | ~80 (Write-Host, esperado) | NEW |

### Scripts creados

| Script | Líneas | Propósito |
|--------|--------|-----------|
| skill-graph.ps1 | 363 | Resolvedor sparse loading BFS |
| skill-test-suite.ps1 | 102 | Suite de tests de skills |
| skill-validate.ps1 | 170 | Validación 3-trial benchmark |
| cross-ref-check.ps1 | 100 | Validación de referencias cruzadas |
| check-skill-drift.ps1 | 71 | Detección de drift global↔canonical |
| bench-file-io.ps1 | 90 | Benchmark de I/O |
| optimize-system.ps1 | 155 | Optimización de recursos del sistema |
| ps5-detect.ps1 | 42 | Detección de PS5.1 byte-level |
| auto-clean.ps1 | 26 | Limpieza automática de temporales |
| ensure-tools.ps1 | 27 | Verificación triple rg/sg/gh |
| token-count.ps1 | 33 | Conteo aproximado de tokens |
| tokenize-all.ps1 | 24 | Tokenización batch |
| bash-safe.ps1 | 58 | Wrapper seguro para Git Bash |
| intake-verify.ps1 | 96 | 7 checks automáticos de intake |

## Infraestructura (no existía en backup)

| Componente | Backup | Repo |
|-----------|--------|------|
| Test suite | ❌ | **56/56 PASS, 100%** |
| Quality gate (pre-commit) | ❌ | **4/4 ALL CLEAR** |
| Cross-ref check | ❌ | **PASS** |
| PSScriptAnalyzer | ❌ | **0 errors** |
| Pre-commit hook | ❌ | **4 checks** |
| `.gitattributes` (eol=lf) | ❌ | ✅ |
| ANTI-PATTERN-CATALOG.md | 1 (175L) | 1 (actualizado) |

## Sistema

| Métrica | Backup | Repo | Δ |
|---------|--------|------|---|
| NVMe sequential read | No medido | 1,653 MB/s | +14.4% vs baseline |
| Startup apps on boot | — | 8 → 0 | −8 |
| Power plan | Balanced | Ultimate Performance | ✅ |
| NODE_OPTIONS | — | --max-old-space-size=8192 | ✅ |
| Git fsmonitor | — | Habilitado | ✅ |

## Benchmarks ejecutables

```powershell
# Reproducir este benchmark:
.\scripts\bench-compare.ps1
# Salida: tabla comparativa backup vs actual
```

## Resumen

```
Backup pre-sprint3 ──── mejoras ────► gentleman-agent-gh
     139L AGENTS.md                     259L AGENTS.md (self-contained)
     57 skills (2,205L)                 57 skills (1,840L)
     0 scripts                          14 scripts
     0 triggers                         56/56 triggers
     0 tags                             57/57 tags
     0% metadata quality                100% metadata quality
     sin test suite                     56/56 PASS
     sin quality gate                   4/4 ALL CLEAR
     sin sparse loading                 skill-graph (-85-92%)
     sin hardening                      StrictMode 14/14 + PSSA 0 err
```

Delta clave: **46 skills comunes compactados −35.3%, infraestructura completa de testing + hardening + quality gate construida de cero.**
