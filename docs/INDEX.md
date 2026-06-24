# Docs Index

> Estructura modular del proyecto gentleman-agent-gh.
> Última actualización: 2026-06-23

---

## 📋 Estructura

```
docs/
├── INDEX.md              ← Este archivo — referencia central
├── operations/           ← Uso diario — qué agente, estándares, scoring
├── decisions/            ← Decisiones arquitectónicas e históricas
├── research/             ← Investigaciones técnicas (9 áreas)
├── metrics/              ← Evidencia de scoring + baselines
├── reference/            ← Referencias generales
└── archive/              ← Planes cumplidos + binarios
```

---

## 🟢 operations/ — Operativos (uso diario)

| Archivo | Qué contiene |
|---------|-------------|
| `agent-capabilities.md` | Roles de agente: gentleman-vMK, gentleman-deep, gentleman-codex |
| `quality-standard.md` | 13 dimensiones de calidad del proyecto |
| `scoring-protocol.md` | Protocolo reproducible de scoring |
| `subagent-prompts.md` | Prompts de prueba para subagentes |
| `project-score.md` | Score actual del proyecto (9.9/10) |

---

## 🔵 decisions/ — Decisiones e historial

| Archivo | Qué contiene |
|---------|-------------|
| `bitacora.md` | Log cronológico completo del proyecto |
| `portfolio.md` | Fusiona: portabilidad, ruteo de modelos, correcciones factuales |
| `roadmap.md` | Roadmap completado (v7) |

---

## 🟡 research/ — Investigaciones técnicas

| Archivo | Área | Tamaño |
|---------|------|--------|
| `build-optimization.md` | Optimización del sistema de build | ~28KB |
| `bundlesize.md` | Reducción de bundle size | ~24KB |
| `gc-tuning.md` | Tuning de garbage collector (Bun/V8) | ~16KB |
| `network-io.md` | Optimización de I/O de red | ~22KB |
| `database-storage.md` | Optimización de almacenamiento y DB | ~40KB |
| `memory-leaks.md` | Investigación de memory leaks | ~43KB |
| `ram-optimization.md` | Optimización de RAM | ~25KB |
| `token-context.md` | Optimización de tokens y contexto | ~32KB |
| `tui-performance.md` | Rendimiento de terminal TUI | ~28KB |

> **Total research**: ~258KB — 9 archivos de 16-43KB c/u

---

## 🟣 metrics/ — Evidencia de scoring

| Archivo | Qué contiene |
|---------|-------------|
| `intake-baseline.json` | Baseline inicial del proyecto (métricas del sistema) |
| `pssa-baseline.json` | Baseline de PowerShell Script Analyzer |
| `snapshots/LATEST_benchmark.json` | Benchmark actual: 68 skills, 125KB, 100% frontmatter |
| `errors/LATEST_error.json` | Último resultado de quality gate (9 pass, 0 fail) |
| `changelog-20260613-intake-system.md` | Cambios del intake inicial |
| `compaction-batch2-20260614.md` | Segunda ronda de compactación |
| `final-optimization-round-20260615.md` | Ronda final de optimización |
| `fix-docs-scripts-20260614.md` | Fixes de docs y scripts |
| `intake-report-*.md` (5) | Reportes detallados del intake inicial |
| `perf-optimization-20260614.md` | Optimización de rendimiento |
| `perf-report-20260613.md` | Reporte de rendimiento inicial |
| `phase1-compactacion-20260614.md` | Fase 1 de compactación |
| `plugin-optimization-20260615.md` | Optimización de plugins |
| `quality-gate-20260614.md` | Reporte de quality gate |
| `sparse-loading-20260614.md` | Implementación de sparse loading |
| `tools-compression-20260614.md` | Compresión de herramientas |

> **⚠️ No eliminar** — 6 scripts del proyecto dependen de esta carpeta.
> Ver `docs/metrics/SUMMARY.md` para resumen ejecutivo.

---

## 🟠 reference/ — Referencias

| Archivo | Qué contiene |
|---------|-------------|
| `mcp-viability.md` | Viabilidad de MCP servers |
| `skills-caveman.md` | Las 68 skills en formato caveman comprimido |
| `upstream-concepts.md` | Conceptos de Go traducidos a PowerShell |

---

## ⚫ archive/ — Histórico

| Archivo | Qué contiene |
|---------|-------------|
| `optimization-plan.md` | Plan global de optimización (cumplido) |
| `cycle-improvement-plan.md` | Plan de mejora de ciclo (cumplido) |
| `benchmark-vs-backup.md` | Comparativa pre-sprint3 (histórica) |
| `asrd.md` | Binario — imagen o archivo no legible |
| `identity.md` | Binario — imagen o archivo no legible |
| `soul.md` | Binario — imagen o archivo no legible |

---

## 🔗 Referencias cruzadas entre módulos

| Desde | Hacia | Naturaleza |
|-------|-------|------------|
| `operations/quality-standard.md` | `decisions/bitacora.md` | Cita cambios registrados |
| `operations/scoring-protocol.md` | `metrics/` | Baselines para scoring reproducible |
| `operations/project-score.md` | `metrics/` | Score deriva de métricas |
| `decisions/roadmap.md` | `decisions/bitacora.md`, `metrics/` | Referencias históricas |
| `decisions/portfolio.md` | `operations/quality-standard.md`, `decisions/bitacora.md` | Citas a estándares y bitácora |
| `research/network-io.md` | `research/build-optimization.md` | Cross-ref entre investigaciones |
| `reference/skills-caveman.md` | Skills en `.agents/skills/` | Mapa comprimido de skills |

---

## 📐 Convenciones de naming

- **Módulos**: `operations/`, `decisions/`, `research/`, `metrics/`, `reference/`, `archive/` — todos en inglés, minúscula, singular
- **Archivos**: `kebab-case.md` — descriptivo, sin prefijos (`research-`), sin versiones en el nombre
- **Cross-refs**: rutas relativas desde el archivo que referencia, NO desde la raíz del proyecto
