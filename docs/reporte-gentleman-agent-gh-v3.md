# Reporte Técnico v3 — gentleman-agent-gh (tercera pasada + verificación v1/v2)

**Alcance de esta pasada:** conteo exhaustivo de agentes reales en `opencode.json`, lectura línea por línea de la lógica central (`skill-graph.ps1`, 478 líneas), y comparación directa `setup-machine.ps1` vs `setup-machine.sh` (paridad Windows ↔ Linux/macOS).
**Resultado:** se confirman todos los hallazgos de v1/v2 sin cambios, y aparece **un hallazgo funcional nuevo de severidad alta** — más importante que los anteriores porque afecta si el sistema *arranca correctamente* en dos de las tres plataformas soportadas.

---

## 0. Hallazgo principal de esta pasada

**El instalador de Linux/macOS no copia `AGENTS.md` ni crea la junction de `prompts/sdd/` al config global — por lo que, siguiendo el flujo documentado, el protocolo completo del agente probablemente nunca se activa fuera de Windows.**

Evidencia directa, comentarios del propio código (`scripts/setup-machine.ps1`):
```powershell
# ── Step 6b: Global prompts junction ────────────────────────────────
# The global config may contain {file:prompts/sdd/*.md} references from agent
# definitions synced in Step 4. Those resolve relative to the global config dir,
# so we need the prompts directory there too.
...
# ── Step 6c: Global AGENTS.md ──────────────────────────────────────
# {file:AGENTS.md} in gentleman-vMK agent prompt resolves relative to global config
```
Es decir: los propios autores documentan que sin estos dos pasos, las referencias `{file:...}` en los prompts de los agentes **no resuelven**. `gentleman-vMK` es el agente orquestador principal, y su protocolo completo (Ponytail, Triangulate/E1-E2-E3, Engram, skill router, 20+ shortcuts — las 205 líneas de `AGENTS.md` documentadas en v2 §4) depende de que ese archivo exista en `~/.config/opencode/AGENTS.md`. Los 10 agentes `sdd-*` (orquestador + 9 subagentes) dependen igual de la junction de `prompts/sdd/` para cargar sus propios prompts (`{file:prompts/sdd/sdd-apply.md}`, etc., confirmados en `opencode.json`).

**Comparación de pasos, instalador por instalador:**

| Paso | `setup-machine.ps1` (Windows) | `setup-machine.sh` (Linux/macOS) |
|---|---|---|
| Env var `GENTLEMAN_AGENT_ROOT` | ✅ | ✅ |
| Hooks de pre-commit | ✅ (Step 2) | ❌ ausente |
| Variables de entorno OpenCode | ✅ | ✅ |
| Shortcuts globales de shell | ✅ | ✅ |
| Sync config global (mcp/permission/skills) | ✅ | ✅ |
| Symlinks de skills | ✅ | ✅ |
| **Junction de `prompts/sdd/`** | ✅ (Step 6b) | ❌ **ausente** |
| **Copia de `AGENTS.md` a config global** | ✅ (Step 6c) | ❌ **ausente** |
| **Instalación de binarios MCP** | ✅ (Step 7) | ❌ **ausente** |

Confirmado por `grep` directo: ni "AGENTS.md" (como destino de copia), ni "prompts junction", ni instalación de binarios MCP aparecen en ningún punto de `setup-machine.sh` (240 líneas vs. 344 del `.ps1`).

**Por qué el CI no lo detecta:** el único chequeo Linux en `quality-gate.yml` es:
```yaml
- name: Linux/macOS setup test — verify install.sh runs cleanly
  run: ./scripts/install.sh --yes --skip-env-var --skip-shortcuts
```
Esto valida que el script **termine sin error de código** — no que el resultado sea funcionalmente completo (no verifica que `~/.config/opencode/AGENTS.md` exista después, ni que la junction de prompts se haya creado, ni que los binarios MCP estén disponibles). Es el mismo patrón de fondo que el hallazgo de v2 sobre `skillspector-gate.ps1`: **el CI mide "corrió sin fallar", no "hizo lo que debía hacer"**.

**Impacto:** un usuario en macOS/Linux que siga el README ("Linux/macOS: `./scripts/install.sh`") probablemente termina con un `gentleman-vMK` que actúa como un asistente genérico sin ninguna de las reglas operativas (Ponytail, Triangulate, Engram, shortcuts), y con el pipeline SDD completo roto (los 10 agentes `sdd-*` referencian prompts que no van a resolver). Esto es más severo que los hallazgos previos porque no es deuda técnica silenciosa — es una **feature central que no funciona** en 2 de 3 plataformas soportadas, pese a que el README las presenta como equivalentes.

**Fix sugerido:** portar Steps 6b, 6c y 7 de `setup-machine.ps1` a `setup-machine.sh` (son ~70 líneas de PowerShell a traducir a bash: `ln -s`/`cp` en vez de `New-Item -ItemType Junction`/`Copy-Item`), y añadir al CI un chequeo post-instalación que verifique la existencia real de `~/.config/opencode/AGENTS.md` y la junction/symlink de prompts, no solo el exit code del instalador.

---

## 1. Verificación de hallazgos previos (v1 + v2)

| Hallazgo | Origen | Estado tras 3ª pasada |
|---|---|---|
| CI roto: `release.yml` → `CHANGELOG.md` vs `docs/CHANGELOG.md` | v1 | ✅ Confirmado, sin novedad |
| `catch {}` vacío en `wisdom-stats.ps1:98` | v1 | ✅ Confirmado, sin novedad |
| Score README (8.5) vs `.project.json` (9.3) desincronizado | v1 | ✅ Confirmado — y agrava, ver §2 (conteo de agentes también desincronizado) |
| `dependabot.yml` con ecosistema `nuget` irrelevante | v1 | ✅ Confirmado, sin novedad |
| Permisos "analyze-only" con `bash/write: allow` a nivel plataforma pese a prohibición a nivel prompt | v1/v2 | ✅ Confirmado tal como quedó en v2 (control blando sí existe, control duro sigue sin reflejarlo) |
| `skillspector-gate.ps1` nunca puede fallar en CI (siempre `exit 0`) | v2 | ✅ Confirmado, releído completo — no hay ningún `exit 1` en el script |
| Sesgo de auto-score documentado en `bias-calibration.json` (+2 a +3.3 pts) | v2 | ✅ Confirmado, sin novedad |
| Testing casi inexistente (14 tests cubren 1 función de 1 script) | v1/v2 | ✅ Confirmado, sin novedad |

No se descarta ningún hallazgo previo en esta pasada. Se investigó específicamente si `$skillLookup` en `skill-graph.ps1` (usado en la línea 248, definido recién en la línea 345) era un bug de orden de ejecución — **se descarta**: en PowerShell el cuerpo de una función no se ejecuta al definirla, solo al invocarla, y la invocación real ocurre después de que `$skillLookup` ya fue poblado a nivel de script. Es código correcto, aunque el orden de lectura (función antes que sus dependencias) dificulta el análisis manual — vale la pena, como mejora menor, mover el bloque de `$skillLookup` antes de las funciones que lo usan por claridad, no por corrección.

---

## 2. Hallazgo nuevo — el README subcuenta agentes reales (9 subagentes ocultos no documentados)

Conteo exacto vía parseo de `opencode.json` (22 agentes definidos en total):

| Tipo | Cantidad | Modelo | ¿Aparece en README? |
|---|---|---|---|
| `gentleman-vMK` (orquestador) | 1 | default de la plataforma | Sí |
| `gentleman-*` especialistas (deep/quick/codex/security/seo/infra/frontend/performance/datascience/docs/implementer) | 11 | modelos free-tier explícitos | Sí (tabla del README) |
| `sdd-orchestrator` | 1 | `claude-sonnet-4-6` (pago) | Sí (tabla del README) |
| `sdd-apply/archive/design/explore/init/propose/spec/tasks/verify` | **9** | **sin especificar** (`model` ausente → cae al default global de OpenCode, no definido en este repo) | **No** — no aparecen individualmente en ninguna tabla del README |

El README dice *"12 agentes especializados además del orquestador principal"* — ese "12" corresponde exactamente a las 11 filas de la tabla + `sdd-orchestrator`. Pero **9 agentes adicionales existen y corren con permisos completos** (`bash: allow, edit: allow, write: allow` — confirmado en v1 §3.1) y **sin modelo asignado explícitamente**, lo cual tiene dos implicancias:

1. **Costo no garantizado en $0**: si el default global de OpenCode no es un modelo free-tier, la fase más sensible del pipeline SDD (`sdd-apply`, la que realmente escribe código; `sdd-verify`, la que valida el resultado) podría estar corriendo sobre un modelo de pago sin que el README lo mencione en ningún lado.
2. **Superficie de permisos subcontada**: la evaluación de riesgo de permisos (v1 §3.1) debería considerar 9 agentes más de los que originalmente se analizaron, todos con `write: allow` + `bash: allow` sin restricción de "analyze-only" (a diferencia de los especialistas `gentleman-*`, los `sdd-*` no usan `_analyze-only-protocol.md` en absoluto — su prompt es directamente el archivo de fase SDD correspondiente).

**Fix sugerido:** documentar los 9 agentes `sdd-*` en el README con su modelo real (correr `opencode models sdd-apply` o equivalente para confirmarlo), y decidir explícitamente si deben heredar un modelo free-tier o si el uso de un modelo de pago en esas fases es una decisión consciente (razonable, dado que son las fases de mayor riesgo — pero debería ser explícito, no default implícito).

---

## 3. Confirmaciones adicionales sin severidad nueva

- `skill-graph.ps1`: la lógica de matching (tokenizar tarea → `[regex]::Escape($token)` → buscar substring dentro de cada trigger) es correcta y razonable; el `Sort-Object` inicial de `$MatchedNames` por score antes del BFS es trabajo redundante (el resultado final se reordena igual al final), inocuo pero desperdicia ciclos — no vale la pena una línea de recomendación aparte, es cosmético.
- No se encontraron más bloques `catch` vacíos fuera del ya reportado en `wisdom-stats.ps1` (119 bloques `catch` totales en el repo, 1 vacío).
- `docs/audits/` y `docs/errors/` están **vacíos** — pese a existir en la estructura documentada del proyecto (v1 §mapeo de arquitectura), no contienen ningún reporte previo. Esto significa que los hallazgos de v1/v2/v3 no están duplicando ni contradiciendo auditorías internas ya realizadas — es terreno no cubierto previamente por el propio sistema de auto-mejora del proyecto, pese a que ese es justamente el propósito declarado de esas carpetas.

---

## 4. Recomendaciones priorizadas (consolidado v1+v2+v3)

| Prioridad | Acción | Esfuerzo | Origen |
|---|---|---|---|
| 🔴 Alta | Portar Steps 6b/6c/7 (`AGENTS.md`, prompts junction, binarios MCP) de `setup-machine.ps1` a `setup-machine.sh` | Medio | **Nuevo v3** |
| 🔴 Alta | CI: verificar post-instalación en Linux que `AGENTS.md` y la junction de prompts existan realmente (no solo exit code) | Bajo | **Nuevo v3** |
| 🔴 Alta | `skillspector-gate.ps1`: hacer que pueda fallar de verdad, o quitar "blocking" del step de CI | Bajo | v2 |
| 🔴 Alta | Instalar SkillSpector real en `quality-gate.yml` | Medio | v2 |
| 🔴 Alta | Fix ruta `CHANGELOG.md` → `docs/CHANGELOG.md` en `release.yml` | 1 línea | v1 |
| 🟠 Media | Documentar los 9 agentes `sdd-*` en README + asignar modelo explícito (confirmar si heredan free-tier o pago) | Bajo | **Nuevo v3** |
| 🟠 Media | Espejar en `opencode.json` la restricción `write: deny` para agentes analyze-only (hoy solo vive en el prompt) | Medio | v1/v2 |
| 🟠 Media | Corregir README/.project.json para reportar el score con el offset de sesgo ya documentado, no en crudo | Bajo | v2 |
| 🟠 Media | Tests deterministas para `skill-graph.ps1`, `setup-machine.*`, `check-mcp-security.ps1` | Alto | v1 |
| 🟡 Baja | `catch {}` vacío en `wisdom-stats.ps1:98` | 1 línea | v1 |
| 🟡 Baja | Quitar bloque `nuget` de `dependabot.yml` | 1 línea | v1 |
| 🟡 Baja | Mover definición de `$skillLookup` antes de las funciones que lo consumen (legibilidad, no corrección) | Bajo | **Nuevo v3** |

---

## 5. Conclusión

Las tres pasadas convergen en un mismo patrón de fondo, cada vez más nítido: **el proyecto verifica que las cosas *corran* (exit code 0, sintaxis válida, tests de una sola función), pero tiene puntos ciegos sistemáticos en verificar que las cosas *funcionen como se pretende*.** Eso se vio en v2 con el gate de seguridad que nunca bloquea, y se repite en v3 de forma más grave con el instalador de Linux/macOS: el CI confirma que `install.sh` termina sin error, pero no confirma que, tras correrlo, el agente principal realmente cargue su protocolo operativo. Para un proyecto que declara "Triple verify" y "Default-FAIL: evidencia = output de herramienta, no autoevaluación" como principios centrales (`AGENTS.md`), esta es precisamente la clase de brecha que esos principios deberían haber atrapado — y no lo hicieron, porque el propio sistema de verificación mide la señal equivocada (¿corrió? en vez de ¿hizo lo correcto?) en más de un lugar del pipeline.
