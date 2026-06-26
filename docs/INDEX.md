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
├── metricas/             ← Evidencia de scoring + baselines (es: metricas)
├── ciclos/               ← Reportes de ciclos de mejora
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
| `project-score.md` | Score actual del proyecto (10.0/10) |
| `external-audit-findings.md` | Hallazgos de auditoría externa D:\mdShare |

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

## 🟣 metricas/ — Evidencia de scoring

| Archivo | Qué contiene |
|---------|-------------|
| `intake-baseline.json` | Baseline inicial del proyecto (métricas del sistema) |
| `pssa-baseline.json` | Baseline de PowerShell Script Analyzer |
| `snapshots/LATEST_benchmark.json` | Benchmark actual: 69 skills, ~125KB, 100% frontmatter |
| `errors/LATEST_error.json` | Último resultado de quality gate (9 pass, 0 fail) |
| `SUMMARY.md` | Resumen ejecutivo de métricas del proyecto |
| (15 reportes adicionales) | Reportes históricos de intake, compactación, optimización |

> **⚠️ No eliminar** — 6 scripts del proyecto dependen de esta carpeta.
> Ver `docs/metricas/SUMMARY.md` para resumen ejecutivo.

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
| `benchmark-vs-backup.md` | Comparativa pre-sprint3 (histórica) |
| `identity.md` | Declaración de identidad del agente (histórica) |
| `soul.md` | Filosofía fundacional del agente (histórica) |

---

## 🔗 Referencias cruzadas entre módulos

| Desde | Hacia | Naturaleza |
|-------|-------|------------|
| `operations/quality-standard.md` | `decisions/bitacora.md` | Cita cambios registrados |
| `operations/scoring-protocol.md` | `metricas/` | Baselines para scoring reproducible |
| `operations/project-score.md` | `metricas/` | Score deriva de métricas |
| `decisions/roadmap.md` | `decisions/bitacora.md`, `metricas/` | Referencias históricas |
| `decisions/portfolio.md` | `operations/quality-standard.md`, `decisions/bitacora.md` | Citas a estándares y bitácora |
| `research/network-io.md` | `research/build-optimization.md` | Cross-ref entre investigaciones |
| `reference/skills-caveman.md` | Skills en `.agents/skills/` | Mapa comprimido de skills |

---

## 📐 Convenciones de naming

- **Módulos**: `operations/`, `decisions/`, `research/`, `metricas/`, `ciclos/`, `reference/`, `archive/`
- **Archivos**: `kebab-case.md` — descriptivo, sin prefijos (`research-`), sin versiones en el nombre
- **Cross-refs**: rutas relativas desde el archivo que referencia, NO desde la raíz del proyecto
