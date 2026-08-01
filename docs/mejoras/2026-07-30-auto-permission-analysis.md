# Análisis: Clasificador de Auto-Permiso — Patrones ASK vs ALLOW

**Fecha**: 2026-07-30
**Trigger**: `!analisis` — analizar patrones ASK vs ALLOW para ajustar la allowlist
**Pre-Answer Gate**: ✅ Evidencia existente en `docs/mejoras/2026-07-28-permission-modes-analysis.md`
**Confidence**: Hallazgos con `confidence: high` salvo donde se indique

> **⚠️ Corrección post-review (2026-07-30)**: Este documento fue revisado contra la codebase actual. Se corrigieron:
> - **H6**: `npm ci`, `pip freeze/list/show` YA están en `permission-gate.ps1` L94-L95. La tabla fue corregida.
> - **H8**: Se expandió para incluir los 4 agents adicionales con `bash: *: deny`: `frontend`, `performance`, `datascience`, `docs`.
> - Se agregó sección de secuencia de implementación y nota de write-protection.

---

## Resumen Arquitectónico

El sistema tiene **3 capas de permiso** que coexisten:

| Capa | Archivo | Propósito |
|------|---------|-----------|
| 🌐 Global | `opencode.json` root → `permission.bash` | Default para agents SIN bloque propio |
| 🤖 Agent-specific | `opencode.json` → `agent.{name}.permission.bash` | Permisos por agente (sobrescribe global) |
| 🚦 Runtime Behavioral | `scripts/permission-gate.ps1` | Script advertencial que clasifica comandos por modo |

Y **3 modos** de operación (leídos de `.gentleman-mode`, actual: **`auto`**):

| Modo | Estrategia | Agents Activos |
|------|-----------|----------------|
| `manual` | `*: ask` (todo pregunta) | Base: `gentleman-deep`, `-quick`, `-codex`, `-implementer`, `-vMK` |
| `semi` | `*: ask` + allowlist de solo-lectura | Variantes `-semi` |
| `auto` | `*: allow` + denylist de destructivos | Variantes `-auto` |

---

## Hallazgos Clave

### 🚨 H1. LAYERING BREAK — Las denegaciones globales NO afectan a agents auto/semi
`confidence: high`
**Evidence**: `opencode.json` L8-L81 (global) vs L291-L364 (gentleman-deep-auto permission bloque propio)

Las 60 reglas `deny` globales (python, node, ssh, docker, curl, etc.) SOLO aplican a agents SIN bloque `permission.bash` propio — actualmente solo `gentleman-reviewer`, `sdd-*` subagents, y agents base (`*: ask`).

Los 5 agents `-auto` y 5 `-semi` tienen SU PROPIO bloque `permission.bash`, lo que **sobrescribe completamente** las reglas globales. Si una regla deny falta en un agente auto, la global NO la salva — es un safety net agujereado.

**Hallado previamente en**: `docs/mejoras/2026-07-28-permission-modes-analysis.md` L222-L227 (mencionado como riesgo de implementación)

---

### 🚨 H2. ~960 líneas de DUPLICACIÓN — ~90% identical boilerplate
`confidence: high`
**Evidence**: Análisis cuantitativo de opencode.json (ver tool output)

```
Auto agents:   5 × ~72 líneas = ~360 líneas de permisos idénticos
Semi agents:   5 × ~120 líneas = ~600 líneas (~25 allow + 60 deny + 2 ask)
Total:         ~960 líneas de repetitivo en opencode.json (de 1534 totales)
```

Cada agente auto re-lista los mismos 61 deny + 10 ask. Cada semi-agent re-lista los mismos 25 allow + 60 deny + 2 ask. Si mañana se bloquea `gh secret set`, hay que tocar 10 bloques.

---

### 🚨 H3. ASIMETRÍA en auto agents — `git push --force` inconsistente
`confidence: high`
**Evidence**: `opencode.json` L300 vs L396 vs L491 vs L588 vs L897

| Auto Agent | `git push --force *` |
|------------|---------------------|
| `gentleman-deep-auto` | `deny` ✅ |
| `gentleman-quick-auto` | `ask` ❌ |
| `gentleman-codex-auto` | `ask` ❌ |
| `gentleman-implementer-auto` | `ask` ❌ |
| `gentleman-vMK-auto` | `ask` ❌ |

`gentleman-deep-auto` es el único que realmente bloquea `push --force`. Los otros 4 solo preguntan.

---

### 🚨 H4. DRIFT entre `permission-gate.ps1` y `opencode.json`
`confidence: high`
**Evidence**: `scripts/permission-gate.ps1` L55-L103 vs `opencode.json` agent blocks

El gate runtime dice:
- `^git push --force` y `^git push -f` → **deny** en TODOS los modos (L75)
- Pero en opencode.json:
  - Agents semi: NO tienen `git push --force` en deny list → cae a `*: ask` (pregunta, no deniega)
  - Agents auto (excepto deep): `git push --force *: ask` (pregunta)

**Riesgo**: Un developer confía en el gate como source of truth, pero OpenCode runtime usa opencode.json. Si alguien skipea el gate, la protección es más débil de lo que el gate sugiere.

---

### 🚨 H5. SEMI agents: `$import` template vs expanded drift
`confidence: high`
**Evidence**: `scripts/opencode-config/semi-agents.json` L46, L98, L146, L197, L250 (usan `$import`) vs `opencode.json` bloques semi (ya expandidos sin `$import`)

`expand-config.ps1` resuelve el `$import` a `shared-deny-rules.json` inline en `opencode.json`. Pero:
1. `opencode.json` actual ya TIENE las reglas expandidas (no quedan `$import` markers)
2. Si `shared-deny-rules.json` se actualiza, `opencode.json` queda STALE
3. `expand-config.ps1` es idempotente (safe to re-run) pero NADIE lo ejecuta automáticamente

**Hallado previamente en**: `scripts/cross-ref-check.ps1` L260-L306 (verificación semi allowlist sync)

---

### 🔶 H6. SEMI allowlist vs GATE allowlist: diferencias menores (ACTUALIZADO)
`confidence: high`
**Evidence**: `opencode.json` semi blocks (32 allows) vs `permission-gate.ps1` L79-L98

> **Corrección**: La versión original de este hallazgo decía que `npm ci` y `pip freeze/list/show` faltaban en el gate. Estaban en `semi-agents.json` como `npm *` / `pip *` (wildcards), y desde entonces se refinaron en AMBAS direcciones (ver cambios pendientes en staging).

**Estado actual de diferencias**:

| Comando | En semi agents | En gate | Nota |
|---------|---------------|---------|------|
| `npm *` (wildcard) | ❌ reemplazado | ❌ reemplazado | Ahora usan reglas específicas |
| `npm ci *` | ✅ allow | ✅ `^npm ci` | Sincronizados |
| `pip freeze/list/show *` | ✅ allow | ✅ `^pip (freeze\|list\|show\|install --user)` | Sincronizados |
| `pip *` (wildcard) | ❌ reemplazado | ❌ reemplazado | Gate más restrictivo (exige subcomando específico) |
| `type\s` (PowerShell) | ❌ no está | ✅ allow | Gate más permisivo |
| `Get-Help`, `Get-Alias` | ❌ no está | ✅ allow | Gate más permisivo |

**Diferencia semántica importante**: opencode.json semi agents usan `npm *: allow` y `pip *: allow` (wildcards), mientras el gate usa patrones regex más restrictivos por subcomando. La refinación (pendiente en staging) reemplaza wildcards por reglas específicas en `semi-agents.json`.

---

### 🔶 H7. Modo `manual` actualmente INACTIVO
`confidence: high`
**Evidence**: `.gentleman-mode` L1 → `auto`

El sistema está en modo `auto` permanente. El flag de modo está implementado, los agents -semi y -auto existen, el routing en `gentleman-vMK.md` L29-L37 maneja los sufijos... pero **no hay shortcuts `!auto/!semi/!manual` implementados** en ningún lado. `SHORTCUTS.md` menciona la intención (según análisis previo L244-L253) pero no hay handlers.

---

### 🔶 H8. READ-ONLY SPECIALISTS incompletos — faltan 4 agents (ACTUALIZADO)
`confidence: high`
**Evidence**: `scripts/mode-gate.ps1` L65-L69 vs `opencode.json` agents con `bash: *: deny`

`mode-gate.ps1` tiene 3 agents en `readOnlySpecialists` (security, seo, infra). Pero hay **7 agents** con estructura `bash: *: deny + write: deny + edit: deny` en `opencode.json`:

| Agent | En readOnlySpecialists |
|-------|----------------------|
| `gentleman-security` | ✅ sí |
| `gentleman-seo` | ✅ sí |
| `gentleman-infra` | ✅ sí |
| `gentleman-frontend` | ❌ **falta** |
| `gentleman-performance` | ❌ **falta** |
| `gentleman-datascience` | ❌ **falta** |
| `gentleman-docs` | ❌ **falta** |

Además, `gentleman-reviewer` (`bash: ask, write: deny, edit: deny`) es un caso distinto — no es bash-deny pero sí write/edit-deny. Su inclusión en `readOnlySpecialists` es debatible y depende de si se quiere que bypass el mode suffix check.

**Riesgo**: En modo auto/semi, si el orquestador delega a cualquiera de estos 4 agents sin sufijo, `mode-gate.ps1` esperaría `-auto`/`-semi` y reportaría BLOCKED.

---

## Métricas del Clasificador

### Superficie total de permisos

| Dimensión | Valor |
|-----------|-------|
| Total agents en `opencode.json` | 33 |
| Agents con `*: allow` (auto mode) | 5 |
| Agents con `*: ask` | 8 (base 6 + sdd-orchestrator + gentleman-reviewer) |
| Agents con `*: ask` + allowlist (semi) | 5 |
| Agents con `*: deny` (read-only) | 7 (security, seo, infra, frontend, performance, datascience, docs) |
| Agents subagent (sdd-*) | 8 |
| Líneas totales de permisos en config | ~1,100 / 1,534 (~72%) |
| Líneas DUPLICADAS | ~960 (~87% del config de permisos) |

### Proporción ASK vs ALLOW vs DENY por modo

| Modo | ALLOW | ASK | DENY | Efectividad |
|------|-------|-----|------|-------------|
| `manual` | 0 comandos | * (todo) | 60 reglas | 🔒 Máxima seguridad |
| `semi` | 25 comandos (read-only) | Default + 2 (git branch -D, git stash drop) | 60 reglas | ⚖️ Balanceado |
| `auto` | Default (todo) | 10 (git push/commit/rebase/reset/merge, gh pr merge) | 61 reglas | 🚀 Máxima velocidad |

---

## Nota de Implementación

**Write-protection**: `opencode.json` tiene `edit/write: "*": "deny"` para todos los agents en modo auto. Esto significa que los cambios a `opencode.json` (items 1, 2, 4) **requieren intervención manual del usuario**. El agente solo puede modificar scripts (`.ps1`) y documentación (`.md`).

**Secuencia recomendada**:

1. **(Usuario)** Items 1-2-4: cambios a `opencode.json` — unificar push --force, eliminar redundancia, revisar deny list
2. **(Agente)** Items 8, 6, 3, 7: cambios ejecutables por el agente en modo auto
3. **(Usuario)** Re-ejecutar `expand-config.ps1` después de cambios a `opencode.json`
4. **(Usuario)** Verificar con `cross-ref-check.ps1` que todo esté sincronizado

**Item 7 ya implementado**: Los patrones `npm ci` y `pip freeze/list/show` ya están sincronizados entre `semi-agents.json` y `permission-gate.ps1` (cambios pendientes en staging).

---

## Recomendaciones para Ajustar la Allowlist

### Prioridad CRÍTICA 🔴

1. **Unificar `git push --force`**: Elegir `deny` o `ask` para TODOS los auto agents (H3). Recomiendo `deny` como `gentleman-deep-auto` — en modo auto, push --force debería ser denegado siempre.

2. **Eliminar redundancia con herencia**: Explorar si OpenCode soporta `$import` como mecanismo nativo (referencia en `semi-agents.json` pero no es feature de OpenCode — es de `expand-config.ps1`). Alternativa: crear `shared-deny-rules.json` para auto agents también.

3. **Automatizar `expand-config.ps1`**: Agregarlo como pre-commit hook o step de CI para que `shared-deny-rules.json` y `opencode.json` nunca divergan.

### Prioridad ALTA 🟠

4. **Revisar la lista deny de auto agents**: 60/61 entries son idénticas a las globales pero inefectivas. Propongo extraer la deny list a `shared-deny-rules.json` y usarla TAMBIÉN para auto agents via `$import`.

5. **Sincronizar `permission-gate.ps1` con `opencode.json`**: El gate tiene `^git push --force` como deny universal pero opencode.json semi agents no lo tienen como deny. Decidir cuál es la fuente de verdad y alinear.

### Prioridad MEDIA 🟡

6. **Agregar shortcuts `!auto`/`!semi`/`!manual`**: Sin los shortcuts, el modo switching existe como script pero no es usable desde OpenCode. El análisis previo ya lo documentó (H7).

7. **Completar allowlist del gate**: Agregar `npm ci`, `pip freeze/list/show` a `permission-gate.ps1` semi allowlist (H6).

8. **Agregar `gentleman-frontend`, `gentleman-performance`, `gentleman-datascience`, `gentleman-docs` a `mode-gate.ps1` read-only specialists** (H8). Evaluar si `gentleman-reviewer` (bash=ask pero write/edit=deny) también debería estar.

---

## Archivos Relevantes

| Archivo | Rol |
|---------|-----|
| `opencode.json` | Config central de permisos (global + 33 agents) |
| `scripts/permission-gate.ps1` | Runtime behavioral gate (clasifica comandos por modo) |
| `scripts/mode-gate.ps1` | Valida sufijo de agente vs modo actual |
| `scripts/switch-mode.ps1` | Cambia modo en `.gentleman-mode` |
| `scripts/cross-ref-check.ps1` | Valida consistencia semi allowlist vs gate |
| `scripts/opencode-config/semi-agents.json` | Template source con `$import` para semi agents |
| `scripts/opencode-config/shared-deny-rules.json` | 60 deny rules compartidas vía `$import` |
| `scripts/opencode-config/expand-config.ps1` | Resuelve `$import` markers inline |
| `.gentleman-mode` | Flag de modo actual |
| `prompts/gentleman-vMK.md` | Mode-aware routing (L29-L37) |
| `docs/mejoras/2026-07-28-permission-modes-analysis.md` | Análisis previo de modos de permiso |

---

*Documento generado como parte del análisis `!analisis` — clasificador de auto-permiso*
