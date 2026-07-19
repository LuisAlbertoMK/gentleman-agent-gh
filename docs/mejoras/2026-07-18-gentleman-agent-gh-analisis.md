# Análisis Completo: gentleman-agent-gh

**Fecha**: 2026-07-18  
**Proyecto**: gentleman-agent-gh  
**Versión del análisis**: 1.0  
**Objetivo**: Identificar gaps, correcciones y mejoras existentes con foco en reducción de tokens, calidad de código y excelentes resultados.

## Resumen Ejecutivo

El proyecto es una configuración de agente opencode con 68 skills, 13 agentes, y un ecosistema de datos sofisticado pero fragmentado. Se identificaron **78 hallazgos** categorizados por 8 dimensiones obligatorias, con **11 CRITICAL/HIGH** que requieren atención inmediata.

### Puntuación por Dimensión (post-análisis)

| Dimensión | Puntuación | Hallazgos | Impacto |
|-----------|------------|-----------|---------|
| Security | 5/10 | 18 | CRITICAL |
| Performance | 6/10 | 10 | HIGH |
| UX | 6/10 | 11 | HIGH |
| Infra | 5/10 | 13 | HIGH |
| Data | 4/10 | 10 | HIGH |
| Architecture | 6/10 | 8 | MEDIUM |
| DX | 7/10 | 10 | MEDIUM |
| Business | 7/10 | 8 | MEDIUM |

## Hallazgos por Dimensión

### 1. Security (5/10) — 18 hallazgos

**CRITICAL (3)**:
1. **Permisos de agentes bash/write sin restricción** — Ejecución arbitraria de código
2. **ExecutionPolicy Bypass en todas partes** — Derrota la política de seguridad de PowerShell
3. **bash-safe.ps1 pasa comandos sin sanitizar** — Vector de inyección

**HIGH (5)**:
1. `.gitleaks.toml` permite directorios backup — Ventana de filtración de secretos
2. `secrets-scan` tiene cobertura limitada de patrones de tokens
3. `review-rules.jsonc` clasifica `.env*` como riesgo medio, no alto
4. GitHub Actions workflow falta bloque `permissions` — Exposición de token elevada
5. `setup-machine.ps1` descarga binario engram sin verificación de checksum

**MEDIUM (6)**: Path traversal en run.ps1, registro dev-server en $env:TEMP world-readable, post-commit hook auto-syncs sin validación, package.json versión pinned sin semver, action-gh-release usa tag mutable, quality-gate no ejecuta PSSA incremental.

**LOW (4)**: Tests excluidos de gitleaks, sin CodeQL/SAST en CI, pre-commit hooks versión antigua, .gitignore falta patrones sensibles.

### 2. Performance (6/10) — 10 hallazgos

**HIGH (4)**:
1. **Skill registry bloat** — 32KB para 3 entradas, sin caching
2. **System prompt baseline ~8,400 tokens** — Sobrecarga de contexto
3. **Duplicación entre global/project AGENTS.md** — 8 líneas idénticas
4. **69 skills = 169KB total** — Listing overhead ~100KB

**MEDIUM (4)**:
1. bash-safe.ps1 cold start ~410ms
2. 5 MCP servers iniciados sin health gating
3. Sin caching en skill-resolver-fast.ps1
4. CI quality-gate ejecuta matriz completa

**LOW (2)**: 68 scripts PS1 fragmentados, BITACORA.md/CYCLE.md crecen sin límite.

### 3. UX (6/10) — 11 hallazgos

**HIGH (4)**:
1. **Onboarding gap** — Sin "¿qué hago primero?" claro
2. **Skill discovery opaca** — 68 skills sin agrupación legible
3. **gentleman-implementer prompt de 241+ líneas** — Viola sus propios principios
4. **Documentación bilingüe inconsistente** — Confusión de contexto

**MEDIUM (4)**: Sistema de permisos sin documentar, shortcuts duplicados, definiciones de zonas contextuales duplicadas, agentes deep/codex sin claridad de rol.

**LOW (3)**: Frontmatter inconsistente, sin guía de recuperación de errores, versionado manual.

### 4. Infra (5/10) — 13 hallazgos

**HIGH (6)**:
1. **Sin soporte Docker** — Mayor gap de infraestructura
2. **Sin caching de dependencias CI** — 40-60% más lento
3. **Release notes dependen de CHANGELOG inexistente**
4. **Pre-commit silenciosamente saltado en CI**
5. **Backup solo cubre config global** — DR incompleto
6. **Paridad cross-platform** — 70 PS1 vs 2 SH

**MEDIUM (5)**: Junction scaling frágil, setup-machine.sh error bash, sin triggers de backup automático, sin lockfile npm, sin alerting de errores.

**LOW (2)**: Dependabot pip sección muerta, smoke cache usa $env:TEMP.

### 5. Data (4/10) — 10 hallazgos

**HIGH (3)**:
1. **Divergencia de schema de patrones** — Riesgo de rotura silenciosa
2. **Triple sistema de scoring sin reconciliación** — Números diferentes del mismo sistema
3. **Pipeline stages vacíos** — Infraestructura diseñada pero no implementada

**MEDIUM (4)**: Fragmentación de cache, staleness de skill registry, sin capa de validación, sin lineage de datos.

**LOW (3)**: Duplicación catálogo anti-patrones, métricas sin consumo, dreaming sin datos de entrada.

### 6. Architecture (6/10) — 8 hallazgos

**MEDIUM (5)**:
1. **Acoplamiento skills ↔ _shared** — Sin inyección de dependencias
2. **Patrones duplicados** — Zonas contextuales en 4 archivos
3. **Tech debt** — Skill registry bloat, triple score, pipeline vacío
4. **Modularidad** — 68 skills sin capas claras
5. **Separación de concerns** — Mezcla de config, scripts, docs

**LOW (3)**: Sin diagrama de arquitectura, sin dependency injection, sin plugin system.

### 7. DX (7/10) — 10 hallazgos

**HIGH (3)**:
1. **AGENTS.md referencia contenido movido**
2. **Sin diagramas de arquitectura**
3. **Documentación MCP incompleta**

**MEDIUM (4)**: Sin índice de navegación, contenido duplicado README/QUICKSTART, sin detección de obsolescencia, sin ejemplos de workflow.

**LOW (3)**: Triggers scattered, documentación inconsistente, sin versionado.

### 8. Business (7/10) — 8 hallazgos

**MEDIUM (5)**:
1. **Sin métricas de éxito claras** — Más allá del sistema de scoring
2. **Sin mecanismo de feedback de usuario**
3. **Sin A/B testing de efectividad de prompts**
4. **ROI no cuantificado** — Ahorro de tokens, tiempo de desarrollo
5. **Roadmap no documentado**

**LOW (3)**: Sin competitive analysis, sin user personas, sin adoption metrics.

## Consensos entre Especialistas

1. **Token reduction es prioridad #1** — Performance, UX, y Data coinciden
2. **Skill registry necesita reescritura** — 32KB para 3 entradas es inaceptable
3. **Duplicación de contenido** — AGENTS.md, shortcuts, zonas contextuales
4. **Pipeline de datos incompleto** — Diseñado pero no implementado
5. **Documentación bilingüe** — Confusión entre español/inglés

## Divergencias

1. **Docker vs PS7-first** — Infra sugiere Docker, Performance sugiere PS7-first
2. **Scoring system** — Data dice unificar, Performance dice simplificar
3. **Skill listing** — UX quiere más detalle, Performance quiere menos tokens

## Matriz de Riesgo

| Hallazgo | Riesgo | Impacto | Esfuerzo | Prioridad |
|----------|--------|---------|----------|-----------|
| Permisos agentes sin restricción | CRITICAL | Alto | Medio | P0 |
| Skill registry bloat | HIGH | Alto | Bajo | P0 |
| System prompt 8.4K tokens | HIGH | Alto | Medio | P1 |
| Sin Docker support | HIGH | Medio | Alto | P2 |
| Pipeline stages vacíos | HIGH | Medio | Alto | P2 |
| Documentación bilingüe | MEDIUM | Medio | Bajo | P2 |

## Plan de Implementación Recomendado

### Fase 1: Crítico (1-2 días)
1. Restringir permisos agentes en opencode.json
2. Reescribir skill-registry.json (versión compacta)
3. Eliminar duplicación AGENTS.md global/project
4. Agregar permissions block a quality-gate.yml

### Fase 2: Alto Impacto (3-5 días)
1. Comprimir gentleman-implementer prompt
2. Implementar caching en skill-resolver-fast.ps1
3. Unificar sistema de scoring
4. Agregar CHANGELOG.md y validar release workflow

### Fase 3: Mejora Continua (1-2 semanas)
1. Crear Dockerfile y .devcontainer
2. Implementar pipeline de datos completo
3. Crear documentación de arquitectura
4. Establecer métricas de éxito y feedback loop

## Verificación con Breaker

Para cada implementación en Fase 1 y 2, se ejecutará el protocolo adversarial-breaker para verificar:
1. Que la corrección no introduce nuevos vulnerabilities
2. Que la reducción de tokens no compromete funcionalidad
3. Que los cambios son backward-compatible
4. Que no hay regresiones en calidad de código

## Archivos Afectados

- `opencode.json` — Permisos de agentes
- `scripts/skill-registry.json` — Reescritura
- `AGENTS.md` — Eliminación duplicación
- `.github/workflows/quality-gate.yml` — Permissions block
- `scripts/skill-resolver-fast.ps1` — Caching
- `scripts/score-auto.ps1` — Unificación scoring
- `docs/CHANGELOG.md` — Nuevo archivo
- `.github/workflows/release.yml` — Validación release notes

## Próximos Pasos

1. Ejecutar fase 1 con verificación breaker
2. Medir ahorro de tokens post-implementación
3. Actualizar scoring post-correcciones
4. Documentar decisiones en Engram
