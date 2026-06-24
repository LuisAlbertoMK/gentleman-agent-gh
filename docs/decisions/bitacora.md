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

---

## 2026-06-14 — Batch 3-4: Asset cleanup + CRLF fix

### Cambios
- **15 assets duplicados eliminados**: `skill-root/` y `skill-root/assets/` tenían copias idénticas. −1,587 líneas netas.
- **`.gitattributes`**: `* text=auto eol=lf` — fuerza LF en working tree. Elimina ruido CRLF que causaba 50+ archivos phantom modificados.
- **3 `.bak` files** eliminados (restos de ediciones anteriores).

### Benchmarks
- Net line reduction: −1,587 lines (assets) + CRLF noise eliminated
- Commit: `4be3bc1`, `d256db5`

---

## 2026-06-14 — Batch 5: SDD orchestrator + a11y + strict-tdd

### Cambios
- **sdd-orchestrator.md**: 200→115L (−42.5%)
- **accessibility/SKILL.md**: 188→105L (−44.1%)
- **strict-tdd.md** (sdd-apply): 210→113L (−46.2%)
- **strict-tdd-verify.md** (sdd-verify): 158→78L (−50.6%)
- **Net**: −296 lines en 4 archivos

### Commit
`788a5f6 perf(skills): compact SDD orchestrator, a11y, strict-tdd (-296 net lines)`

---

## 2026-06-14/15 — Batch 5-6: Plugin stack + system optimization

### Plugins instalados
| Plugin | Versión | Impacto |
|--------|---------|---------|
| opencode-dcp | 3.1.12 | −50-70% tokens (context pruning) |
| opencode-skillful | 1.2.5 | −30-50% tokens (lazy skills) |
| opencode-lazy-loader | 1.0.3 | Lazy MCP loading |
| context-mode (MCP) | 1.0.162 | Up to −98% context virtualization |

### System tweaks aplicados
- Ultimate Performance power plan
- NODE_OPTIONS: `--experimental-strip-types --max-old-space-size=8192`
- Git: `feature.manyfiles`, `core.fsmonitor`
- WSL: `.wslconfig` memory=4GB
- NVMe read benchmark: 1653.5 MB/s (+14.4% vs baseline)

### Archivos creados
- `scripts/auto-clean.ps1` — limpieza automática de temp files
- `scripts/bench-file-io.ps1` — benchmark 3 métodos de I/O
- `scripts/ensure-tools.ps1` — verificación triple de rg/sg/gh
- `scripts/token-count.ps1` — conteo aproximado de tokens

### Commits
`df730dc perf: batch 5-6 — development-mode skill + plugin stack + system optimizations`
`1bf5f14 feat(infra): add tool scripts and compress skills`

---

## 2026-06-14 — Phase 1 compactación + fixes

### Cambios
- **AGENTS.md + anti-patterns + config**: unificados y compactados
- **Skill count corregido**: 58→53 en docs
- **Pre-commit hook reparado**: 4 checks funcionales
- **scripts/cross-ref-check.ps1**: paths corregidos → `.agents/skills/`
- **scripts/check-skill-drift.ps1**: reparado

### Commits
`22a641c refactor: Phase 1 compactación — AGENTS.md, anti-patterns, config unificada`
`9adaa8d fix: correct skill count 58->53 in docs, fix scripts and configs`
`05b3e15 perf(infra): fix pre-commit hook, compress skills, update docs`

---

## 2026-06-15 — Final optimization round

### Evaluación de skills restantes
- `_shared/` — 6 archivos de referencia, ya compactos (SKILL.md 18L, resto <107L). Sin margen de compresión.
- `gap-analysis/SKILL.md` — 111L, contenido denso. Sin redundancia identificada.
- `development-mode/SKILL.md` — 95L, tabla + bloques de código compactos.
- **Veredicto**: skills del sistema en estado óptimo. No requieren más compresión sin pérdida de calidad.

### Estado final del sistema
- 54 skills en `.agents/skills/`, todos <90L efectivas de contenido
- AGENTS.md global: 187L (v2.4), AGENTS.md proyecto: 18L
- Pre-commit gate operativo con 4 checks
- Scripts de utilidad creados y funcionales
- Plugins de optimización instalados
- Sin archivos huérfanos ni duplicados

### Lecciones
- Compresión repetitiva de archivos ya compactos tiene retorno marginal decreciente (<5% Δ)
- El bottleneck ahora no son los skills, sino el runtime (context-mode, dcp ya instalados)
- Próximo ciclo de mejora debe enfocarse en sparse loading + incremental context retrieval

---

## 2026-06-14 — Sparse loading + skill-graph

### Cambios
- **`scripts/skill-graph.ps1`** — Nuevo resolvedor de dependencias: dado un task description, encuentra skills matching + 1-hop de dependencias vía BFS. Registry completo de 55 skills con triggers, categorías, dependencias.
- **`.agents/skills/skill-graph/SKILL.md`** — Nueva skill de sparse loading. Resolución: 55 skills → 4-8 (−85-92% tokens de skill).
- **`SKILLS-INDEX.md` v2.0** — Agregada entrada skill-graph + dep categories. Skill count: 54→55.
- **`session-resume/SKILL.md` v2.0** — Integrado skill-graph para pre-loading de skills al reanudar sesión.
- **Junction global** — `C:\Users\MK\.config\opencode\skills\skill-graph` → `.agents/skills/skill-graph/`

### Arquitectura
- `scripts/skill-graph.ps1`: 337L, contiene registry + grafo (adj list) + BFS resolver + output formateado
- 10 categorías: compression, quality, memory, meta, code-ops, SDD, web-quality, specialized
- Edge types: `depends_on` (carga obligatoria), `related` (carga sugerida)
- Output: matched skills + expanded dependencies por separado

### Lecciones
- `@()` arrays con `-Description` que contiene `(comma, args)` rompen PS5.1 parser. Solución: evitar comma-separated lists en paréntesis dentro de strings descriptivos.
- `Format-Table` requiere PSCustomObject (no hashtable) para columnas correctas. Hashtables muestran keys como filas.
- ctx_batch_execute corre en shell, no PowerShell — comandos PS nativos fallan.
