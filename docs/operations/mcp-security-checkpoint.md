# MCP Security Checkpoint — Gentleman Agent

> **Propósito**: Security gate para integración de MCP servers. Análisis de riesgo post-NSA advisory, controles obligatorios, y proceso de go/no-go antes de agregar cualquier MCP server.
> **Creado**: 2026-06-30
> **Aplica a**: `gentleman-agent-gh` (repo local, personal)
> **Verificación**: Triple subagente (ver sección 7)

---

## Índice

1. [Estado Actual](#1-estado-actual)
2. [Threat Model](#2-threat-model)
3. [NSA Advisory Mapping](#3-nsa-advisory-mapping)
4. [Risk Assessment por MCP](#4-risk-assessment-por-mcp)
5. [Security Controls Obligatorios](#5-security-controls-obligatorios)
6. [MCP Security Gate Process](#6-mcp-security-gate-process)
7. [Verificación Cruzada](#7-verificación-cruzada)

---

## 1. Estado Actual

### Inventario de MCPs en `opencode.json`

| MCP | Tipo | Transporte | Tools | Auth | Estado |
|-----|------|-----------|-------|------|--------|
| **context7** | remote | HTTP (Streamable) | `resolve-library-id`, `query-docs` | API key (opcional) | ✅ Activo |
| **engram** | local | STDIO | `mem_*` tools | Ninguna | ✅ Activo |

### Historial de cambios

| Fecha | Cambio | Fuente |
|-------|--------|--------|
| 2026-06-14 | Se agregaron context7, engram; context-mode evaluado y removido | phase1-compactacion metrics |
| 2026-06-21 | Se evaluaron 5 MCPs adicionales (no implementados) | `docs/reference/mcp-viability.md` |
| 2026-06-30 | Security checkpoint (este documento) | Análisis post-NSA advisory |
| 2026-06-30 | context7 migrado de remote HTTP a local STDIO | Security checkpoint P0 |
| 2026-06-30 | Sequential Thinking instalado (GO del Security Gate) | 23/50 tools activas |

### Inventario de pendientes (de `mcp-viability.md`)

Estos MCPs fueron recomendados pero **no implementados**. Están en evaluación:

| MCP | Prioridad (viability) | Token overhead | Auth requerida |
|-----|----------------------|----------------|----------------|
| Memory | Phase 1 | ~500 | Ninguna |
| Sequential Thinking | Phase 1 | ~200 | Ninguna |
| Fetch | Phase 1 | ~200 | Ninguna |
| Playwright | Phase 2 | ~1,500 | Ninguna |
| GitHub | Phase 2 | ~2,000 | GitHub PAT |

---

## 2. Threat Model

### Contexto

Este es un **repo personal** en una sola máquina Windows. No hay datos de producción, no hay multi-tenancy, no hay PII/PHI. El riesgo base es **bajo**.

### Activos a proteger

| Activo | Sensibilidad | Impacto si comprometido |
|--------|-------------|------------------------|
| GitHub token (`GITHUB_TOKEN`) | Alta | Push a repos, lectura de código privado |
| Código fuente del repo | Media | Pérdida de IP personal |
| Config de entorno (`.env` variables) | Alta | Exposición de API keys |
| Sesión de OpenCode | Media | Ejecución de comandos como el usuario |
| Sistema de archivos local | Alta | Lectura/escritura de archivos personales |

### Vectores de ataque MCP-específicos

Basado en el patrón inverted client-server del NSA advisory:

```
[Host] ←→ [MCP Client] ←→ [MCP Server] ←→ [External API]
   ↑                        ↑
   └── Confía en el         └── Puede leer/escribir
        server para             en nombre del host
        ejecutar acciones
```

| Vector | Descripción | Relevancia |
|--------|-------------|------------|
| **Server malicioso** | Server que ejecuta comandos no autorizados | Baja (solo servers oficiales/locales) |
| **Supply chain** | Dependencia npm de server comprometida | **Alta** (vía `npx -y`) — aplica a TODOS los servers via npx |
| **Token leakage** | Server que expone tokens vía log/error | **Media** (GitHub PAT en env) |
| **Data exfiltration (remote)** | Server HTTP envía query patterns a API externa | **Media** (context7 — nombres de librerías, patrones de búsqueda) |
| **Data exfiltration (local)** | Server STDIO lee archivos y los envía | Baja (STDIO local no tiene red) |
| **SSRF via Fetch/Playwright** | Server con capacidad HTTP accede a localhost, IMDS, o redes internas | **Media** (Fetch puede fetch any URL; Playwright puede navegar a localhost) |
| **Remote HTTP injection** | Servidor HTTP man-in-the-middle | Baja (HTTPS obligatorio) |
| **`npx -y` code execution** | `npx -y` ejecuta código arbitrario sin verificación de integridad | **Alta** — no hay lockfile, no hay hash verification. TOCTOU: el package puede cambiar entre approval y runtime. |
| **Dependency confusion** | Typosquatting de packages npm con nombres similares a MCP oficiales | **Media** — posible si se escribe mal un package name |
| **Cross-server contamination** | Server A comprometido accede a tokens/files del server B vía proceso compartido | **Media** — STDIO servers comparten el proceso host |
| **Memory poisoning** | Engram o Memory MCP almacena datos maliciosos que afectan comportamiento futuro del agente | **Media** — prompt injection via memoria persistente |
| **Cache/side-channel leakage** | Temp files o cache de MCP servers persisten entre sesiones | Baja — aceptado para repo personal |

---

## 3. NSA Advisory Mapping

**Fuente**: `U/OO/6030316-26` (May 20, 2026) — Cybersecurity Information Sheet, 17 páginas.

### Controles evaluados vs nuestro contexto

| # | Control NSA | ¿Aplica? | Implementación |
|---|-------------|----------|----------------|
| 1 | Egress filtering proxies entre agentes y MCP endpoints | 🔴 No (riesgo aceptado) | No tenemos proxy. Para STDIO local no aplica. Para remote (context7), el riesgo es aceptado para un repo personal. |
| 2 | Sandboxing de servidores MCP | 🔴 No (riesgo aceptado) | STDIO corre **en el mismo proceso** que OpenCode. No hay sandbox real. El filesystem boundary mitiga acceso a archivos pero NO es un sandbox de proceso. Aceptado para repo personal. |
| 3 | Tokens con mínimo privilegio | 🟢 Sí | GitHub PAT con scopes mínimos. API keys de contexto7 con rate limit básico. |
| 4 | Firmado de mensajes | 🔴 No | No implementado. NSA lo recomienda pero no hay soporte en spec actual (viene en 2026-07-28). **Aceptar riesgo**. |
| 5 | Logging estructurado de interacciones MCP | 🟡 Parcial | OpenCode logea tool calls. No hay logging específico de MCP. Mejorable. |
| 6 | Output filtering | 🟢 Sí | OpenCode permission system filtra reads (`.env` denegado). |
| 7 | Scans periódicos de MCP locales | 🟢 Sí | Script `scripts/check-mcp-security.ps1` — audit automatizado: source trust, transport, tokens, archived, tool budget. |
| 8 | No instalar servers de directorios no verificados en prod | 🟢 Sí | Solo servers oficiales (MCP Registry, vendor-published). |
| 9 | Asumir cada server puede leer todo lo que el agente puede leer | 🟢 Sí | Principio de mínimo privilegio por diseño. |

### Veredicto NSA

> Para un repo personal con servers STDIO locales y 1 server HTTP confiable (Context7), **el nivel de riesgo es ACEPTABLE** sin controles adicionales complejos. Los 3 controles NSA que más importan acá son:
> 1. Tokens con mínimo privilegio (#3)
> 2. No instalar servers no verificados (#8)
> 3. Asumir leak total (#9)
>
> Los controles #4 (firmado), #1 (proxy), #5 (logging enterprise) son relevantes para despliegues enterprise multi-tenant, no para este contexto.

---

## 4. Risk Assessment por MCP

### 4.1 Ya implementados

#### context7 (remote HTTP)

| Dimensión | Evaluación |
|-----------|------------|
| **Transporte** | HTTP remoto → envía queries a API de Context7 |
| **Data enviada** | Nombres de librerías, queries de búsqueda (metadata de consultas) |
| **Data recibida** | Docs de librerías públicas (open source) |
| **Auth** | API key opcional (rate limit) |
| **Privilegio** | Solo lectura de documentación pública |
| **Riesgo** | 🟡 **Medio** — Server HTTP remoto: exfiltra patrones de búsqueda a API externa. Aunque los datos son de bajo impacto (librerías open source), el transporte remoto introduce dependencia de red y disponibilidad. |
| **Supply chain** | Server mantenido por Upstash (vendor confiable). 58k ⭐. |
| **Mitigación** | Migrar a STDIO local vía `npx @upstash/context7-mcp` elimina el riesgo HTTP. **P0 - acción inmediata recomendada**. |
| **Nota** | Si se migra a STDIO, el riesgo baja a 🟢 pero se agrega el riesgo 🟡 supply chain de `npx -y`. |

#### engram (local STDIO)

| Dimensión | Evaluación |
|-----------|------------|
| **Transporte** | STDIO local |
| **Auth** | Ninguna |
| **Privilegio** | Solo lectura/escritura de base de datos Engram local |
| **Riesgo** | 🟢 **Bajo** — Proceso local, datos locales, sin red. |
| **Nota** | Riesgo de **memory poisoning**: Engram almacena observaciones que el agente lee en sesiones futuras. Si se introduce contenido malicioso vía un prompt contaminado, podría afectar comportamiento futuro. Mitigación: solo escribe el agente mismo (no hay multi-tenancy), y el contenido se revisa en el loop de aprendizaje. Aceptado. |

### 4.2 Pendientes (de mcp-viability.md)

#### Memory MCP (Phase 1)

| Dimensión | Evaluación |
|-----------|------------|
| **Riesgo** | 🟢 **Bajo** — STDIO local. Sin red. Sin auth. Solo persistencia local. |
| **Sup chain** | `@modelcontextprotocol/server-memory` — MCP Steering Group (confiable). |
| **Nota** | Podría solaparse con Engram. Evaluar antes de implementar. |

#### Sequential Thinking (Phase 1)

| Dimensión | Evaluación |
|-----------|------------|
| **Riesgo** | 🟢 **Bajo** — STDIO local. Sin red. Sin auth. Solo genera texto estructurado. |
| **Sup chain** | `@modelcontextprotocol/server-sequential-thinking` — MCP Steering Group. |

#### Fetch (Phase 1)

| Dimensión | Evaluación |
|-----------|------------|
| **Riesgo** | 🟡 **Medio** — SSRF vector: HTTP arbitrario puede acceder a localhost, IMDS, redes internas. Mismo riesgo que cualquier HTTP client. |
| **Sup chain** | `mcp-server-fetch` — MCP Steering Group. |
| **Mitigación** | SSRF aceptado para repo personal (riesgo documentado). No agrega capability nuevo sobre `webfetch` existente. Validar delta antes de instalar. |
| **Nota** | 1 tool. Budget mínimo. |

#### Playwright (Phase 2)

| Dimensión | Evaluación |
|-----------|------------|
| **Riesgo** | 🟡 **Medio** — ⚠️ **Mutating**: puede navegar, clickear, llenar formularios. Ejecuta un browser. |
| **Sup chain** | `@playwright/mcp` — Microsoft (oficial, 33k ⭐). Confiable. |
| **Mitigación** | Ejecutar solo cuando se invoca explícitamente. No mantener siempre activo. |
| **Nota** | Es el server de mayor riesgo en la lista por ser mutating. Requiere sandboxing. |

#### GitHub MCP (Phase 2)

| Dimensión | Evaluación |
|-----------|------------|
| **Riesgo** | 🟡 **Medio (condicional al PAT scope)** |
| | 🟢 si PAT es solo `issues:read` + `pull_requests:read` |
| | 🟡 si PAT incluye `repo` (read/write a código) |
| | 🔴 si PAT incluye `workflow`, `admin:org`, o `delete_repo` |
| **Auth** | GitHub PAT con scopes. **Crítico**: limitar scopes. |
| **Sup chain** | `github/github-mcp-server` — GitHub oficial (30k ⭐). |
| **Mitigación** | Usar token con scopes mínimos (repo, issues, pull requests). No usar token con `admin`, `workflow` o `delete_repo`. |
| **Ambiente** | `GITHUB_TOKEN` en environment del server, no en global. |

---

## 5. Security Controls Obligatorios

### 5.1 Control de Acceso a MCPs

Cada MCP server en `opencode.json` debe tener:

```jsonc
// Template mínimo de configuración segura
// NOTA: OpenCode usa {env:VAR} para interpolar variables del host.
// NO usar ${env:VAR} (sintaxis Bash, NO soportada por OpenCode).
"mcp": {
  "server-name": {
    "type": "local",                 // STDIO preferido sobre remote
    "command": ["npx", "-y", "@vendor/mcp-server"],
    "environment": {
      // Variables de entorno scoped al server, desde .env del host
      "API_KEY": "{env:API_KEY}"
    }
  }
}
```

**Reglas**:
- Preferir **local (STDIO)** sobre **remote (HTTP)** cuando sea posible
- Variables de entorno scoped al server, nunca globales
- No usar tokens con más permisos de los necesarios

> **Nota**: Todo MCP server que use `npx -y` tiene un **riesgo implícito 🟡 supply chain** (ejecución de código no verificado desde npm). Este riesgo se documenta como modifier en cada server relevante pero no cambia la clasificación base de riesgo del server — es un riesgo transversal que aplica a TODOS los servers via npx.

### 5.2 Supply Chain Verification

**Problema**: `npx -y` ejecuta código arbitrario sin verificación.

**Mitigaciones**:
1. Solo instalar servers de fuentes verificadas:
   - MCP Steering Group (`@modelcontextprotocol/*`)
   - Vendor oficial (Microsoft, GitHub, Upstash, Brave, etc.)
   - MCP Registry ([registry.modelcontextprotocol.io](https://registry.modelcontextprotocol.io))
2. Verificar SHA/checksum si el server lo provee
3. Para servers nuevos, ejecutar primero en entorno aislado
4. No usar `npx -y` con packages de autores desconocidos

### 5.3 Token Management

| Server | Token requerido | Scope mínimo | ¿Dónde se guarda? |
|--------|----------------|--------------|-------------------|
| context7 | Opcional (rate limit) | — | `.env` o ninguno |
| GitHub MCP | GitHub PAT | `repo`, `issues:read`, `pull_requests:read` | `.env` → environment scoped |
| Playwright | Ninguno | — | — |

**Regla**: Todos los tokens van a `.env` (ya está en `.gitignore` y denegado en `opencode.json` read permissions). Nunca hardcodeados.

### 5.4 Auditoría periódica

Script propuesto: `scripts/check-mcp-security.ps1`

Responsabilidades del script:
- Verificar que todos los servers MCP en `opencode.json` sean de fuentes permitidas
- Verificar que ningún server use `remote` transport sin HTTPS
- Verificar que ningún server exponga tokens en logs
- Reportar servers archived o sin mantenimiento
- Emitir warning si hay más de 5 servers activos (tool budget)

### 5.5 Tool Budget Gate

```
tools_activas ≤ 50 → OK
tools_activas > 50 → BLOQUEAR nuevo server hasta revisión
```

Cada server debe declarar su tool count estimado antes de aprobarse.

**Tool budget real estimado**:

| Server | Tools reales | Fuente |
|--------|-------------|--------|
| context7 | 2 | Official README |
| engram | 18 | Engram SDK |
| Memory | ~9 | `server-memory` README |
| Sequential Thinking | ~2-3 | `server-sequential-thinking` README |
| Fetch | 1 | `mcp-server-fetch` |
| Playwright | ~22 | `@playwright/mcp` — incl. navegación, snapshot, network |
| GitHub MCP | ~56 | GitHub MCP (remote server count) |

**Total si se activaran todos**: 2 + 18 + 9 + 3 + 1 + 22 + 56 = **111 tools** → excede el umbral de 50 por 2.2x.

**Conclusión**: No es posible tener TODOS los servers activos simultáneamente. La estrategia correcta es:
1. Elegir un **subset activo** (máximo 3-4 servers simultáneos + engram fijo)
2. Alternativa: configurar servers como `"enabled": false` y activarlos bajo demanda
3. Reevaluar cuando OpenCode implemente Dynamic Tool Loading (similar a Cursor's Dynamic Context Discovery)

### 5.6 Incident Response

En caso de compromiso de un MCP server:

| Paso | Acción |
|------|--------|
| 1 | **Desconectar** el server: `"enabled": false` en `opencode.json` |
| 2 | **Rotar tokens**: cambiar GitHub PAT, API keys de Context7, etc. |
| 3 | **Auditar logs**: revisar tool calls recientes del server comprometido |
| 4 | **Rollback**: `git checkout opencode.json` si el cambio fue reciente |
| 5 | **Reportar**: documentar el incidente en `docs/operations/incidents/` |
| 6 | **Reevaluar**: no reconectar el server hasta nuevo security gate |

---

## 6. MCP Security Gate Process

### 6.1 Go/No-go para nuevos MCP Servers

Checklist obligatorio **antes** de agregar cualquier MCP server:

```
□ 1. Source verification
    □ Server mantenido por vendor oficial o MCP Steering Group
    □ SHA/checksum verificado (si disponible)
    □ No es server archived

□ 2. Risk assessment
    □ Riesgo evaluado y documentado (🟢/🟡/🔴)
    □ Si es 🟡 → mitigación documentada
    □ Si es 🔴 → NO PASAR

□ 3. Token security
    □ Token con scopes mínimos
    □ Token en .env, no hardcodeado
    □ Environment scoped al server

□ 4. Tool budget
    □ tool count total post-instalación ≤ 50
    □ tool overhead documentado

□ 5. Documentation
    □ Riesgo registrado en este documento
    □ Config actualizada en opencode.json
```

### 6.2 Proceso de aprobación

```
Nuevo MCP server propuesto
        │
        ▼
  [1] Source verification ──── FAIL → ❌ DENIED
        │ PASS
        ▼
  [2] Risk assessment ──────── RED → ❌ DENIED
        │ YELLOW → mitigación requerida
        │ GREEN → continuar
        ▼
  [3] Token + Budget review ── FAIL → ❌ DENIED
        │ PASS
        ▼
  [4] Aprobación final → ✅ GO
```

### 6.3 Current MCPs Gate Status

| MCP | Source | Risk | Token | Budget | Gate |
|-----|--------|------|-------|--------|------|
| context7 | ✅ Upstash (vendor) | 🟡 Medio | ✅ Ninguno | 2 tools | ✅ PASS (riesgo aceptado) |
| engram | ✅ Engram SDK | 🟢 Bajo | ✅ Ninguno | ~18 tools | ✅ PASS |
| Memory | ✅ MCP Steering Group | 🟢 Bajo | ✅ Ninguno | ~9 tools | 🟢 SKIP — overlap con Engram, no justifica 9 tools |
| Sequential Thinking | ✅ MCP Steering Group | 🟢 Bajo | ✅ Ninguno | ~3 tools | ✅ INSTALADO (2026-06-30) |
| Fetch | ✅ MCP Steering Group | 🟡 Medio | ✅ Ninguno | 1 tool | ✅ GO (condicional: verificar delta con webfetch nativa) |
| Playwright | ✅ Microsoft (oficial) | 🟡 Medio | ✅ Ninguno | ~22 tools | 🟡 GO condicional — on-demand, con flags de seguridad |
| GitHub MCP | ✅ GitHub (oficial) | 🟡 Medio (condicional) | ✅ Requiere PAT (repo+read:org) | ~56 tools | ❌ NO-GO — excede tool budget 50 por 52% incluso solo |

**Subset activo actual**: engram(18) + context7(2) + Sequential Thinking(3) = **23 tools activas de 50** ✅
**Si se agregan**: Fetch(1) → 24 · Playwright(22 on-demand) → 46
**Sobran**: 27 tools para futuros servers

---

## 7. Verificación Cruzada

Este documento fue verificado por 3 subagentes independientes.

### Subagente A — Security Assessment Review
- **Rol**: Verificar que el threat model cubra todos los vectores relevantes
- **Enfoque**: Revisar contra NSA advisory, OWASP Top 10 for LLM, y patrones conocidos de MCP
- **Hallazgos**:
  - ❌ NSA #1 (Egress) clasificado 🟡 Parcial → **🔴 No**. No hay proxy.
  - ❌ NSA #2 (Sandboxing) clasificado 🟢 Sí → **🔴 No**. STDIO corre en mismo proceso.
  - ❌ NSA #7 (Scans) clasificado 🟢 Sí → **🟡 Parcial**. Script no existe aún.
  - ❌ Fetch MCP clasificado 🟢 → **🟡 Medio**. SSRF vía HTTP arbitrario.
  - 🟡 Falta integridad de dependencias (lockfile/pinning).
  - 🟡 Falta proceso de incident response.
  - 🟡 No cubre: TOCTOU en npx, dependency confusion, SSRF vía Fetch/Playwright.
- **Veredicto**: Changes needed — aplicados en secciones 3, 3.1, 5.6, y tabla de vectores.

### Subagente B — Technical Configuration Review  
- **Rol**: Verificar que las configuraciones propuestas sean técnicamente correctas
- **Enfoque**: Validar sintaxis de `opencode.json`, environment scoping, transport types
- **Hallazgos**:
  - ❌ `$` en `${env:VAR}` **no es válido** en OpenCode. Debe ser `{env:VAR}`. **Corregido** en §5.1.
  - ❌ Tool counts incorrectos: Engram ~18 (no ~15), Memory ~9 (no ~3), GitHub ~56 (no ~30), SeqThink ~3 (no ~5). **Corregidos** en §6.3.
  - ❌ "context-mode" en historial no existe en config actual. **Corregido** en §1.
  - ❌ Tool budget real con servers pendientes: 111 tools (excede 50 por 2.2x). **Agregado** en §5.5.
  - ❌ `mcp-viability.md` afirma que Engram es "session-only" — incorrecto. Engram sí tiene cross-session.
- **Veredicto**: Changes needed — tool counts y syntax corregidos.

### Subagente C — Risk Classification Review
- **Rol**: Verificar que las clasificaciones de riesgo (🟢/🟡) sean correctas y consistentes
- **Enfoque**: Cross-reference con data real de cada server (capa de red, permisos, mantenimiento)
- **Hallazgos**:
  - ❌ context7: 🟢 → **🟡 Medio**. Es HTTP remoto, exfiltra query patterns. **Corregido** en §4.1.
  - ❌ Fetch: 🟢 → **🟡 Medio**. HTTP arbitrario = SSRF vector. **Corregido** en §4.2.
  - ✅ Playwright 🟡 correcto, pero falta documentar SSRF, file://, exfiltration vectors.
  - ⚠️ GitHub MCP necesita clasificación **condicional** al PAT scope. **Corregido** en §4.2.
  - ✅ Engram 🟢 correcto, riesgo de memory poisoning documentado. **Expandido** en §4.1.
  - ⚠️ npx supply chain es riesgo transversal en todos los servers. **Documentado** en §5.2.
- **Veredicto**: Minor issues — reclassifications de context7 y Fetch aplicadas, GitHub condicional agregado.

---

## 8. Acciones Inmediatas

Basado en este análisis, las acciones priorizadas son:

| Prio | Acción | Por qué |
|------|--------|---------|
| P0 | **Migrar context7 de remote a local STDIO** | Eliminar dependencia HTTP. `npx @upstash/context7-mcp` es más seguro que HTTP remoto. |
| P0 | ✅ **`scripts/check-mcp-security.ps1` creado** | Auditoría automatizada: source trust, transport, tokens, archived, tool budget. |
| P1 | ✅ **Memory MCP vs Engram: SKIP (complementarios, no justifica 9 tools)** | Memory MCP es grafo entidad-relación; Engram es observaciones con FTS5. Overlap parcial, pero Engram ya cubre persistencia. 9 tools extra no justifican el tool budget. |
| P1 | ✅ **Scopes GitHub PAT definidos: mínimo `repo` + `read:org`** | `repo` da acceso a código privado + issues + PRs + Actions. `read:org` permite leer org metadata. Sin `workflow`, `admin:org`, `delete_repo`. |

### GitHub PAT Scopes — Definición

Para GitHub MCP, el token necesita:

| Scope | ¿Necesario? | Razón |
|-------|-------------|-------|
| `repo` | ✅ Sí | Acceso a repos privados, issues, PRs, code search, Actions status |
| `read:org` | ✅ Sí | Leer org metadata (útil si el repo pertenece a una org) |
| `workflow` | ❌ No | Permite modificar Actions workflows — riesgo alto |
| `admin:org` | ❌ No | Admin de org — riesgo alto |
| `delete_repo` | ❌ No | Eliminar repos — riesgo alto |
| `user` | ❌ No | No necesario para operaciones de repo |

**Config**:
```bash
# Token con scopes mínimos
gh auth login --scopes "repo,read:org"
# O crear token en: https://github.com/settings/tokens
# Scopes: repo (all), read:org
```

**Environment** en `opencode.json`:
```jsonc
"github": {
  "type": "local",
  "command": ["./github-mcp-server", "stdio"],
  "environment": {
    "GITHUB_TOKEN": "{env:GITHUB_TOKEN}"
  }
}
```

**Riesgo condicional**:
- 🟢 Con `repo` + `read:org` → riesgo **Medio** (puede leer/escribir código e issues)
- 🟡 Si se agrega `workflow` → riesgo **Alto**
- 🔴 Si se agrega `admin:org` o `delete_repo` → riesgo **Crítico** (no implementar)
### Memory MCP vs Engram — Análisis detallado

| Aspecto | Memory MCP | Engram |
|---------|-----------|--------|
| **Data model** | Entity-Relation-Graph (entidades + relaciones + observaciones) | Observaciones con tipos/topics/tags |
| **Search** | Por nombre de entidad, tipo, contenido de observación | FTS5 full-text, por tipo, por topic_key |
| **Persistencia** | Local JSONL file | SQLite + FTS5 |
| **Cross-session** | Sí | Sí |
| **Tools** | 9 (create/delete/read/search/open) | 18 (save/search/context/summary/etc) |
| **Instalación** | npx (necesita Node.js) | Binario Go único, ya nativo en OpenCode |
| **Propósito** | Memoria general tipo knowledge graph | Sesiones de coding agent, progressive disclosure |
| **Mantenido por** | MCP Steering Group (referencia) | Gentleman-Programming |
| **Overlap** | Alto — ambos persisten y buscan datos contextuales | |
| **Diferenciador** | Relaciones explícitas entre entidades (grafos consultables) | FTS5 rápido, progressive disclosure, diseño para sesiones de código |

**Veredicto**: 🟢 **SKIP por tool budget**. Engram ya cubre persistencia cross-session con FTS5. Memory MCP aporta modelo de grafo entidad-relación que Engram no tiene, pero:
- Son 9 tools extra (total pasaría a 29)
- Con Playwright (~22) y GitHub MCP (~56) esperando, no tenemos budget
- Si en el futuro se libera budget (Dynamic Tool Loading), reconsiderar

| P2 | ✅ **Security Gate para 5 MCPs completado** (3 subagentes) | Sequential Thinking → GO · Fetch → GO condicional · Playwright → GO condicional (on-demand) · GitHub → NO-GO (excede budget) · Memory → SKIP (overlap Engram) |
| P2 | ⏳ **Tool budget tracking** | `check-mcp-security.ps1` ya reporta tool budget (20/50). Pendiente: integrarlo en el pipeline de quality-gate o score-auto. Por ahora, auditoría manual vía script. |

---

## Apéndice A: Referencias

- [NSA Advisory U/OO/6030316-26](https://nsa.gov/Press-Room/2026/May-20) — May 20, 2026
- [MCP Spec 2026-07-28 RC](https://blog.modelcontextprotocol.io/posts/2026-07-28-release-candidate/) — May 21, 2026
- [MCP Architecture Overview](https://modelcontextprotocol.io/docs/learn/architecture)
- [MCP Registry](https://registry.modelcontextprotocol.io)
- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-llm-applications/)
- `docs/reference/mcp-viability.md` — Viability report previo
- `docs/research/mcp-servers-analysis.md` — Análisis detallado de servers
- `opencode.json` — Config actual
- `AGENTS.md` — Security section (Ponytail ladder, destructive operations gate)

---

## Apéndice B: Firmado

| | |
|---|-----|
| **Autor** | gentleman-vMK (deepseek-v4-flash-free) |
| **Fecha** | 2026-06-30 |
| **Próxima revisión** | 2026-07-30 (o antes si se agrega un MCP nuevo) |
| **Estado** | ✅ **Verificado** — 3 subagentes ejecutados, correcciones aplicadas |
| **Correcciones aplicadas** | Ver sección 7 |
