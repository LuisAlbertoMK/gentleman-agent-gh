# Bitácora

> Registro cronológico de cambios significativos, decisiones y correcciones.

---

## 2026-06-14 — Phase 1: AGENTS.md compactación + Anti-pattern + Qualidad

### Cambios
- **AGENTS.md**: removida tabla de skills (20L), router (14L), sección persistencia (3L), rúbrica (7L). ~540 tokens/sesión ahorrados.
- **ANTI-PATTERN-CATALOG.md**: compactado a formato tabla con Prevention cheat sheet. 112L → ~37L (−67%). 13 entradas preservadas.
- **README.md/SKILLS-INDEX.md/ROADMAP.md**: conteo de skills unificado a 54.
- **SKILLS-INDEX.md**: agregado trigger para sdd-onboard.
- **opencode.json**: engram path portable (no hardcodeado), model pinned a claude-sonnet-4-6.

### Configuración global
- **Plugins**: dcp, skillful, lazy-loader instalados.
- **MCP**: context-mode configurado + hooks (14/14 PASS).
- **Context Engineering**: arXiv:2606.10209 (−63.9% tokens, +91.6% accuracy).
- **Git**: feature.manyfiles, fsmonitor habilitado.
- **NODE_OPTIONS**: --max-old-space-size=8192.
- **WSL**: .wslconfig con memory=4GB.

### Decisiones
1. **Tabla de skills → SKILLS-INDEX.md**: centralizar triggers, reducir AGENTS.md.
2. **Anti-pattern compacto**: tabla + prevention sheet > lista verbosa.
3. **ReadAllBytes > Get-Content**: 33.3x más rápido para archivos grandes.
4. **engram via PATH**: evitar hardcode de rutas de usuario.

### Fixes post-commit (2026-06-14)
- **ROADMAP**: agregado Sprint 8 Phase 1 Compactación
- **review-gentleman-agent-gh.md**: eliminado
- **Model hardcode revert**: gentleman-vMK + global sdd-orch — los modelos van como sugerencia, no fijos
- **Métricas corregidas**: eliminados números inflados (33.3× → 24.4× real, AGENTS.md before→❌ no verificable)
- **Lección**: solo métricas verificables con fuente. Estimar != medir.

### Benchmarks
- NVMe 256MB sequential read: 1432.3 MB/s
- ReadAllBytes 100MB: 960.9 MB/s
- Context Engineering: −63.9% tokens (arXiv verificado)
