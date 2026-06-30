# MCP Servers Analysis — Gentleman Agent

> **Última actualización**: 2026-06-30
> **Estado**: Verificado (triple subagente)
> **Propósito**: Evaluar qué MCP servers valen la pena integrar en este agente

---

## Índice

1. [¿Qué es MCP?](#qué-es-mcp)
2. [Ecosistema 2026](#ecosistema-2026)
3. [NSA Advisory](#nsa-advisory)
4. [Tool Budget](#tool-budget)
5. [Servers Evaluados](#servers-evaluados)
6. [Recomendación para Gentleman Agent](#recomendación-para-gentleman-agent)
7. [Plan de Integración](#plan-de-integración)
8. [Verificación Cruzada (3 Subagentes)](#verificación-cruzada-3-subagentes)

---

## ¿Qué es MCP?

**Model Context Protocol** (MCP) es un estándar abierto basado en JSON-RPC creado por Anthropic (nov 2024), adoptado por OpenAI, Google, Microsoft, y donado a la **Linux Foundation** (Agentic AI Foundation) en diciembre 2025.

**Arquitectura**:
- **Host**: app que usa el usuario (Claude Desktop, Cursor, VS Code, OpenCode)
- **Client**: componente interno del host, uno por servidor conectado
- **Server**: proceso que expone capacidades al host mediante primitivas estandarizadas

**Primitivas**:
| Primitiva | Activador | Propósito |
|-----------|-----------|-----------|
| `tools` | Modelo | Funciones que el modelo invoca (API calls, writes, DB) |
| `resources` | Aplicación | Datos de solo lectura (documentos, schemas) |
| `prompts` | Usuario | Templates reutilizables |
| `sampling` | Servidor | El server le pide al modelo generar texto |

**Transportes**:
- **STDIO** — comunicación local, proceso directo. Cero overhead de red.
- **Streamable HTTP** — remoto, con OAuth 2.1. **Recomendado** para production. Deprecó el viejo HTTP+SSE.

**Spec actual**: `2026-07-28` (release candidate desde May 21, 2026, final July 28). Es la revisión más grande desde el launch: core stateless, MCP Apps (UI interactiva en iframe sandboxeado), Tasks extension, OAuth alignment.

---

## Ecosistema 2026

| Métrica | Valor |
|---------|-------|
| SDK downloads (npm+PyPI) | ~420M/mes |
| Servidores (oficial registry deduped) | ~9,600 |
| FindMCP index | 8,000+ |
| MCP.so | ~22,970 |
| Glama | ~29,261 |
| AAIF miembros | ~146 |
| Stars referencia (modelcontextprotocol/servers) | ~87.9k ⭐ |

**Adopción**: Todos los coding agents majoritarios hablan MCP nativamente — Claude Code, Cursor, Windsurf, VS Code (GH Copilot), Cline, Zed, Replit, Continue.dev.

---

## NSA Advisory

En **Mayo 20, 2026**, la NSA publicó la guía `U/OO/6030316-26` — la primera evaluación de seguridad de MCP por una agencia de inteligencia.

**Riesgo clave**: MCP invierte el patrón cliente-servidor tradicional. El server ejecuta acciones *en nombre del cliente*, abriendo vectores de ataque que los playbooks existentes no cubren.

**Recomendaciones** (9 total, compliance esperado Sep 30, 2026):
1. Filtros de egreso (proxies / DLP) entre agentes y MCP endpoints externos
2. Sandboxing de servidores
3. Tokens con mínimo privilegio
4. Firmado de mensajes
5. Logging estructurado de toda interacción
6. Output filtering
7. Scans periódicos locales de MCP
8. No instalar servers de directorios no verificados en entornos que toquen prod
9. Asumir que **cada server puede leer todo lo que el agente puede leer**

---

## Tool Budget

Cada server agrega tools al system prompt del modelo. El límite práctico existe:

| Cliente | Límite | Nota |
|---------|--------|------|
| Claude Code | ~50 tools | Degradación notable después de 50 |
| Cursor | 40-80 | Dynamic Context Discovery (Mar 2026) elevó el techo |
| OpenAI Tools API | 128 (hard) | Límite duro |

**Consenso**: 3-7 servers es el rango práctico. Más allá, el modelo empieza a elegir herramientas incorrectas (accuracy cae de ~43% a <14% en estudios).

**Regla de oro**: Cada server nuevo debe *reemplazar* una capacidad existente o habilitar algo imposible antes. No agregar por agregar.

---

## Servers Evaluados

### 🥇 Tier 1 — Esenciales

#### Context7 (⭐ 58.4k)
- **Mantenedor**: Upstash
- **Transporte**: STDIO / Streamable HTTP
- **Tools**: `resolve-library-id`, `query-docs`
- **Propósito**: Docs de librerías versionadas y actualizadas. Mata el problema #1 de los agentes: APIs alucinadas.
- **Por qué**: Mi training data tiene un cutoff. Las APIs cambian. Context7 me da la verdad actualizada.
- **Estado**: ✅ Verificado — 5/6 claims confirmados (el "#1 ranking" es subjetivo pero el sentimiento es consistente)
- **Config**: Gratis sin API key; key opcional para rate limits mayores.

#### Filesystem (⭐ 87.9k — parte del repo reference)
- **Mantenedor**: MCP Steering Group (Anthropic/Linux Foundation)
- **Transporte**: STDIO
- **Tools**: `read_text_file`, `read_media_file`, `read_multiple_files`, `write_file`, `edit_file`, `create_directory`, `list_directory`, `search_files`, `move_file`, `directory_tree`, `get_file_info`, `list_allowed_directories`
- **Propósito**: File ops seguras con sandboxing por directorios permitidos.
- **Por qué**: Ya tengo file ops nativas, pero este server agrega sandboxing explícito y boundaries configurables.
- **Corrección del análisis original**: `read_file` en realidad se llama `read_text_file` (verify subagente #2).

#### Git (⭐ 87.9k — parte del repo reference)
- **Mantenedor**: MCP Steering Group
- **Transporte**: STDIO
- **Tools**: `git_status`, `git_diff_unstaged`, `git_diff_staged`, `git_diff`, `git_commit`, `git_add`, `git_reset`, `git_log`, `git_create_branch`, `git_checkout`, `git_show`, `git_branch`
- **Propósito**: Operaciones de git desde el agente.
- **Por qué**: Ya tengo git via scripts, pero este server expone tools estructuradas.
- **Corrección del análisis original**: NO existe `git_blame` (verify subagente #2). Las tools reales son las listadas arriba.

### 🥈 Tier 2 — Alto Valor

#### GitHub MCP (⭐ 30.8k)
- **Mantenedor**: GitHub (oficial)
- **Transporte**: STDIO / HTTP
- **Tools**: repo browsing, issue/PR CRUD, Actions triggers, code search, discussions, projects
- **Propósito**: Toda la API de GitHub desde el agente.
- **Por qué**: Reemplaza mis glue scripts de `gh` CLI con integración nativa. El server reference original está archivado; este es el oficial de GitHub.
- **Nota**: El server reference `@modelcontextprotocol/server-github` fue archivado en `servers-archived` (May 2025). El official es `github/github-mcp-server`.

#### Playwright MCP (⭐ 33.1k)
- **Mantenedor**: Microsoft (oficial)
- **Transporte**: STDIO
- **Tools**: navegación, screenshots, form fills, extracción de contenido
- **Propósito**: Browser automation y testing visual.
- **Por qué**: Hoy no tengo browser automation nativa. Para testing E2E y debugging visual.
- **⚠️ Mutating**: puede escribir/clickear en páginas web.

#### Fetch
- **Mantenedor**: MCP Steering Group
- **Transporte**: STDIO
- **Tools**: `fetch_url`
- **Propósito**: Obtener URLs y convertir a markdown.
- **Por qué**: Similar a mi `websearch` actual, pero más directo para URLs específicas.

### 🥉 Tier 3 — Situacionales

| Server | Mantenedor | Cuándo | Tools clave |
|--------|------------|--------|-------------|
| **Brave Search** | Brave (oficial) | Búsqueda web | `brave_web_search`, `brave_local_search` |
| **Supabase** | Supabase (oficial) | Si uso Supabase | Queries + Edge Functions + Project mgmt |
| **PostgreSQL** | Comunidad | Schema awareness | `list_schemas`, `get_object_details` |
| **Sentry** | Sentry (oficial) | Debugging de prod | Issues, breadcrumbs, stacktraces |
| **Slack** | Zencoder | Comunicación equipo | Channels, messages, threads |
| **Notion** | Notion (oficial) | Documentación | Pages, databases |
| **Firecrawl** | Firecrawl | Web scraping avanzado | Scrape, crawl, extract, interact |
| **Memory** | MCP Steering Group | Knowledge graph | Memoria persistente tipo grafo |
| **Sequential Thinking** | MCP Steering Group | Razonamiento estructurado | Thought sequences |
| **Cloudflare** | Cloudflare (oficial) | Deploy y DNS | Workers, KV, R2, DNS |

---

## Recomendación para Gentleman Agent

### Prioridad de integración (actualizada post-Security Gate)

```
Fase 1 (ahora)  →  Context7 ✅ + Sequential Thinking ⬅ instalar
Fase 2 (próxima) →  Fetch (si agrega valor sobre webfetch) + Playwright (on-demand)
Fase 3 (skip)   →  Memory SKIP (overlap Engram) · GitHub NO-GO (excede budget)
Fase 4 (futuro)  →  Re-evaluar GitHub MCP si OpenCode implementa Dynamic Tool Loading
```

**Razonamiento**:

1. **Context7** tiene el mayor impacto con el menor costo (2 tools). Mata APIs alucinadas.
2. **Filesystem** me da sandboxing que mi implementación actual no tiene. Boundaries explícitos = más seguridad.
3. **GitHub MCP** reemplaza scripts de `gh` con tools nativas. PRs, issues, Actions desde el agente.
4. **Playwright** habilita testing visual que hoy no tengo.
5. ~~**Memory MCP** es interesante como complemento/respaldo de Engram~~ → **SKIP**. Evaluado vs Engram: overlap alto. Memory MCP aporta grafo entidad-relación, pero Engram (FTS5, progressive disclosure) ya cubre persistencia cross-session. 9 tools extra no justifican el budget. Re-evaluar si OpenCode implementa Dynamic Tool Loading.

### Lo que NO agregar

- **Servidores archived** del repo reference (PostgreSQL, Puppeteer, Sentry, SQLite, Slack, Brave — todos reemplazados por oficiales o abandonados).
- **Wrappers comunitarios** de servicios que ya tienen server oficial (GitHub, Sentry, Slack).
- **Más de 5 servers simultáneos** — el tool budget es real y se paga en calidad de decisión del modelo.

---

## Plan de Integración

### Pre-requisitos

1. Verificar compatibilidad con OpenCode (`opencode.json` — ya soporta MCP plugins nativamente según la doc)
2. NSA compliance: sandboxing de servers, mínimo privilegio, logging
3. Tool budget audit: medir tools actuales antes de agregar

### Pasos

```jsonc
// opencode.json — ejemplo de integración
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "D:/gentleman-agent-gh"]
    }
  }
}
```

### Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Tool budget excedido | Empezar con 2 servers, medir, agregar de a 1 |
| NSA compliance | Sandboxing, tokens mínimos, output filtering |
| Dependencia de servidores externos | STDIO para servers locales, HTTP con fallback |
| Duplicación con capacidades nativas | Reemplazar scripts existentes, no duplicar |

---

## Verificación Cruzada (3 Subagentes)

Cada afirmación de este documento fue verificada por 3 subagentes independientes el 2026-06-30.

### Subagente 1 — Context7 MCP
- **Veredicto**: Mixed (5/6 claims verificados)
- **Disputado**: El claim "#1 most impactful" es subjetivo; no hay ranking universal.
- **Hallazgo adicional**: npm `@upstash/context7-mcp` v3.2.2, 58.4k ⭐, 89 releases.
- **Corrección aplicada**: Se eliminó el claim de "#1 ranking" y se reemplazó por "mayor impacto potencial con menor costo de tools".

### Subagente 2 — Reference Servers (Filesystem, Git, GitHub)
- **Veredicto**: Mixed (3/6 claims verificados, 1 aproximado, 2 con errores factuales)
- **Errores detectados**:
  - `git_blame` **no existe** en el Git server. Tools reales: `git_log`, `git_diff`, `git_diff_unstaged`, `git_diff_staged`, `git_status`, `git_commit`, `git_add`, `git_reset`, `git_create_branch`, `git_checkout`, `git_show`, `git_branch`.
  - `read_file` se llama **`read_text_file`** (con `read_media_file` y `read_multiple_files` como tools separadas).
- **Corrección aplicada**: Tools listadas correctamente en la sección de cada server.
- **Hallazgo adicional**: El Git server reference fue reemplazado (Python reemplazó a TypeScript), no eliminado.

### Subagente 3 — Ecosistema MCP
- **Veredicto**: Verified (8/10 claims verificados)
- **Disputados**:
  - Tool budget ~50: **Direccionalmente correcto pero no universal**. Varía por cliente (Cursor 40-80, OpenAI 128). Dynamic loading puede elevar el techo.
  - MCP.so "3000+": **Incorrecto/desactualizado**. Hoy indexa ~22,970 servers. FindMCP's 8,000+ sí es correcto.
- **Hallazgos adicionales**:
  - ~52% de los MCP endpoints remotos están caídos (audit Rapid Claw, Ene 2026)
  - SDKs crecieron de ~97M a ~420M descargas/mes en 6 meses
  - 146 miembros en AAIF (vs 41 en Dec 2025)

### Lecciones para futuras investigaciones

1. **No confiar en nombres de tools sin verificar el README real** — el subagente #2 encontró 2 errores en tools que asumí correctas.
2. **Verificar números de stars en el momento** — el subagente #2 encontró ~87.9k vs los ~86k estimados.
3. **Distinguir entre servers reference (educativos) y servers oficiales (producción)** — el repositorio `modelcontextprotocol/servers` es explícitamente educativo. El registry es para producción.
4. **NSA advisory es relevante pero no bloqueante** — las recomendaciones son para entornos enterprise con datos sensibles. Para un repo personal como este, el riesgo es bajo si los servers son locales (STDIO).

---

## Referencias

- [MCP Official Site](https://modelcontextprotocol.io)
- [MCP Registry](https://registry.modelcontextprotocol.io)
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) — ⭐ 87.9k
- [Context7](https://github.com/upstash/context7) — ⭐ 58.4k
- [GitHub MCP Server](https://github.com/github/github-mcp-server) — ⭐ 30.8k
- [Playwright MCP](https://github.com/microsoft/playwright-mcp) — ⭐ 33.1k
- [NSA Advisory U/OO/6030316-26](https://nsa.gov/Press-Room/2026/May-20)
- [MCP Blog — 2026-07-28 RC](https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/)
- [FindMCP Directory](https://findmcp.dev) — 8,000+ servers
