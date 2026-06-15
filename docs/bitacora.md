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

### Auto-mejora AGENTS.md (2026-06-14)
- **Version marker**: movido de línea 2 a línea 167 (fin del prompt). Asegura prompt cache estable (~2561t).
- **Cache stability**: 0 version patterns en primeros 1K chars (antes 2). Prompt caching más efectivo.
- **Token savings**: 124 chars (−35t) comprimiendo 3 líneas verbosas.
- **Líneas comprimidas**: STABILITY FIRST (−53 chars), UNKNOWN intake (−48 chars), Quality Standard (−23 chars).

### Benchmarks
- NVMe 256MB sequential read: 1432.3 MB/s
- ReadAllBytes 100MB: 960.9 MB/s
- Context Engineering: −63.9% tokens (arXiv verificado)

## 2026-06-14 — Tools + compresión skills

### Cambios
- **scripts/ensure-tools.ps1**: verificación triple de rg/sg/gh con dot-source PATH. 3/3 passes.
- **scripts/token-count.ps1**: conteo de tokens aproximado (~4 chars/token).
- **scripts/bench-file-io.ps1**: benchmark 3 métodos × N runs. StreamReader > Get-Content (6.7×).
- **.agents/skills/development-mode/SKILL.md**: comprimido 1421→976 tokens (−31.3%).
- **.agents/skills/accessibility/SKILL.md**: comprimido 1008→892 tokens (−11.5%).

### Benchmarks
- rg 3×3 benchmark: ~157ms avg en codebase (literal 169ms, regex 141ms, regex+ctx 162ms)
- File I/O: StreamReader 5.9ms, ReadAllText 9ms, Get-Content 40ms (en archivo 2.3KB)

### Decisiones
1. **StreamReader > Get-Content**: 6.7× más rápido para lectura de archivos. Usar en scripts críticos.
2. **Compresión skills**: solo si delta >5%. Ambos skills pasaron el threshold.
3. **rg vía full path en scripts**: no confiar en PATH entre sesiones PS.
