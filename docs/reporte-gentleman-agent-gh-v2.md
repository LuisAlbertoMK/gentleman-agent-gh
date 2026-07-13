# Reporte Técnico v2 — gentleman-agent-gh (evaluación profunda + verificación de v1)

**Método:** inspección directa de código fuente completo (283 archivos), incluyendo AGENTS.md (205 líneas), opencode.json (388 líneas), CI, prompts compartidos, `review-rules.jsonc`, scripts de seguridad, tests, y metadatos de auto-calibración (`.learnings/bias-calibration.json`).
**Respecto al reporte v1:** se confirman 5 de 6 hallazgos, se **refina 1** con contexto adicional (permisos), y se descubren **2 hallazgos nuevos de severidad alta** que v1 no detectó.

---

## 0. Lo más importante primero

**Hallazgo nuevo, crítico: el "gate de seguridad" que corre en cada CI nunca bloquea nada, bajo ninguna circunstancia.**
`skillspector-gate.ps1` tiene tres caminos de salida — CLI disponible, Docker disponible, ninguno disponible — y **los tres terminan en `exit 0`**, incluso si SkillSpector no está instalado (que es el caso real en el runner de GitHub Actions, ya que no hay `Dockerfile` ni paso `pip install` en el workflow). El paso de CI se llama literalmente *"SkillSpector security gate — Docker fallback (blocking on failures)"* con `continue-on-error: false`, pero es imposible que falle: el script jamás retorna código de error. Es un gate 100% decorativo, en todas las ejecuciones, por diseño de código — no es un caso límite.

**Hallazgo nuevo, de proceso: el propio proyecto tiene evidencia cuantificada de que se autoevalúa optimista.**
`.learnings/bias-calibration.json` registra 3 auditorías donde el auto-score del sistema se compara contra un auditor externo. El offset promedio es de **+3.33 puntos en "Correctness"**, **+3.33 en "ErrPrev"**, **+2.67 en "Skill"**, **+2.0 en "Breadth"** (escala 0-10). Es decir: el propio historial del proyecto muestra que cuando se autocalifica, tiende a sobreestimarse por 2-3+ puntos frente a una revisión externa. Esto no es una opinión mía — es el dato que el propio sistema recolectó sobre sí mismo. El **9.3/10 en `.project.json` debería leerse con ese sesgo documentado en mente**, no como un score neutral.

---

## 1. Verificación de los hallazgos del reporte v1

| # | Hallazgo v1 | Veredicto tras revisión profunda |
|---|---|---|
| 2.1 | CI roto: `release.yml` apunta a `CHANGELOG.md` en vez de `docs/CHANGELOG.md` | ✅ **Confirmado**, sin cambios. Bug real, 1 línea de fix. |
| 2.2 | `catch {}` vacío en `wisdom-stats.ps1:98` | ✅ **Confirmado**. Además, `CYCLE.md` (Cycle 11) afirma *"7 catch→Write-Debug"* como trabajo ya cerrado — pero el catch vacío sigue presente. Es decir, el propio historial de ciclos dice haber resuelto esta clase de problema y no fue así al 100%. |
| 2.3 | Score README (8.5) vs `.project.json` (9.3) desincronizados | ✅ **Confirmado** como síntoma; ver §0 para la causa raíz (auto-score con sesgo documentado). |
| 2.4 | `dependabot.yml` con ecosistema `nuget` irrelevante | ✅ **Confirmado**, no hay artefactos .NET en el repo. |
| 3.1 | Modelo de permisos contradictorio en agentes "analyze-only" (`bash: allow`, `write: allow` pese al rol de solo-análisis) | 🟡 **Refinado, no descartado**. Existe una capa de mitigación que v1 no había revisado: `prompts/shared/_analyze-only-protocol.md` prohíbe explícitamente escritura fuera de `docs/agentes/` y limita bash a inspección de solo lectura (`git log`, `Get-Content`, etc.), y `CYCLE.md` documenta este endurecimiento como trabajo del Cycle 11. **Pero** esa restricción vive únicamente en el prompt (control "blando"), mientras que `opencode.json` (control "duro", a nivel de plataforma) sigue declarando `"bash": "allow", "write": "allow"`. Ante un intento de prompt injection vía contenido externo, el control duro es el que realmente importa, y ese sigue siendo permisivo. Sigue siendo un gap real de defensa en profundidad, solo que menos severo de lo que v1 sugería. |
| — | "Testing casi inexistente pese a declarar TDD" | ✅ **Confirmado y detallado** — ver §3. |

---

## 2. Hallazgo nuevo — el gate de seguridad "SkillSpector" es un placebo en CI

**Evidencia (código):**
```powershell
# --- Try CLI ---
if ($sp) { ...; exit 0 }
# --- Try Docker ---
if ($dockerOk) { ...; exit 0 }
# --- Neither available ---
Write-Host "⚪ SkillSpector not installed — skipping"
exit 0
```
Los tres caminos terminan en `exit 0`. No existe ningún `exit 1` en todo el script.

**Evidencia (CI):** `quality-gate.yml` no instala `skillspector` (no hay `pip install`) ni construye la imagen Docker (no hay `Dockerfile` en el repo). Por tanto, en cada corrida de CI, el script cae siempre en la rama "Neither available" y sale con éxito, sin haber escaneado nada.

**Impacto:** el proyecto reporta esta capa como parte de su pipeline de seguridad ("`!ship`=triple+quality+security+skillspector-gate+commit" en AGENTS.md), pero en la práctica **nunca aporta señal real** — ni en local (si no se instaló SkillSpector) ni en CI (donde nunca se instala). Es deuda de seguridad silenciosa: da falsa sensación de cobertura.

**Fix sugerido:**
- Corto plazo: cambiar los `exit 0` finales por `exit 1` cuando `$riskScore -ge $FailOnRisk` y no está instalado el escáner, O documentar explícitamente que es best-effort/no bloqueante y quitarlo del lenguaje "blocking" del workflow.
- Medio plazo: agregar `pip install git+https://github.com/NVIDIA/SkillSpector.git` como paso previo en `quality-gate.yml` para que el escaneo real ocurra.

---

## 3. Testing — detalle ampliado

v1 señaló "casi no hay tests". Con inspección línea por línea:
- Existe **un solo archivo de test**: `scripts/score-auto.tests.ps1`, con **14 bloques `It`**.
- Esos 14 tests cubren **una única función** (`Add-Dimension`) extraída dinámicamente vía regex desde `score-auto.ps1` (251 líneas totales, 1 función definida en todo el archivo).
- El resto de la lógica de scoring (las 13 dimensiones, los 35 sub-dimensiones que produce el 9.3/10) **no tiene test automatizado** — se valida únicamente por ejecución manual y por el propio "auto-score", que como se documentó en §0 tiene sesgo optimista conocido.
- Los otros 57 scripts (`skill-graph.ps1` 478 líneas, `setup-machine.ps1` 344 líneas, `check-mcp-security.ps1` 320 líneas, etc.) tienen **cero cobertura de test**, solo validación de sintaxis (`ParseFile`) en CI — que detecta errores de sintaxis, no errores de lógica.

**Conclusión:** "Triple verify (E1/E2/E3)" es real como capa de revisión basada en agentes LLM, pero no sustituye una suite de tests determinista. El "TDD" declarado en las convenciones del README no se refleja en el código del propio tooling.

---

## 4. Complejidad del sistema de prompts — hallazgo cualitativo nuevo

`AGENTS.md` (205 líneas) define un sistema de reglas denso: 4 niveles de "ceremony" (GREEN/YELLOW/ORANGE/RED) cruzados con 4 niveles de "risk" por diff (TRIVIAL/LOW/MEDIUM/HIGH), más un modo "Ponytail" con 4 intensidades (lite/full/ultra/off), más zonas Roja/Amarilla/Verde en `review-rules.jsonc`, más 20+ shortcuts de comando (`!ship`, `!check`, `!fast`, `!draft`, `!compress`, `!sync`, `!health`, etc.), más un protocolo de memoria persistente (Engram) con reglas de cuándo guardar/buscar.

Esto no es un error, pero es una superficie de reglas considerable para que un LLM la siga de forma consistente turno a turno — cuantas más capas de "modo" existen (ceremony zone × risk zone × ponytail level × analysis mode), más fácil es que el modelo aplique la combinación incorrecta sin que haya manera automática de detectarlo (no hay test que verifique "dado este diff, ¿el agente aplicó la zona correcta?"). Es un riesgo de **consistencia**, no de código roto.

---

## 5. Seguridad — actualización tras revisión más profunda

Se mantiene lo positivo de v1 (`check-mcp-security.ps1` es sólido, no hay secretos hardcodeados, no hay `Invoke-Expression`, deny-list de `.env`/`credentials.json` correcta, trufflehog real vía GitHub Action de terceros — este sí es un control válido y bloqueante).

Ajuste sobre el hallazgo de permisos (§1, fila 3.1): el riesgo real no es "el agente de seguridad puede escribir libremente sin ninguna restricción" (v1 lo pintó así) sino, más precisamente: **"la restricción existe solo en el prompt, no en la plataforma"**. Para un uso normal (sin contenido adversarial) esto es bajo riesgo porque el modelo respeta el prompt. El riesgo aparece específicamente en escenarios de prompt injection (contenido de terceros que el agente lee — páginas web vía MCP, resultados de research) porque ahí el control blando es precisamente el que un ataque intenta evadir, y el control duro (`opencode.json`) no lo respalda.

**Nuevo, menor:** `skillspector-gate.ps1` y las skills `dreaming`/`immune-system` mencionan explícitamente hallazgos "RA1 (self-modification)" que se ignoran "by design" (`Where-Object { $_.id -ne "RA1" }`). Es una decisión de diseño consciente (agentes que modifican sus propias skills), pero vale la pena que quede documentada como riesgo aceptado explícito en `docs/operations/mcp-security-checkpoint.md`, no solo como comentario en el script.

---

## 6. Recomendaciones priorizadas (actualizada)

| Prioridad | Acción | Esfuerzo | Origen |
|---|---|---|---|
| 🔴 Alta | `skillspector-gate.ps1`: hacer que realmente pueda fallar, o quitar "blocking" del nombre del step en CI | Bajo | Nuevo (v2) |
| 🔴 Alta | Instalar SkillSpector real en `quality-gate.yml` (pip o Docker build) para que el escaneo exista | Medio | Nuevo (v2) |
| 🔴 Alta | Fix ruta `CHANGELOG.md` → `docs/CHANGELOG.md` en `release.yml` | 1 línea | v1 |
| 🟠 Media | Espejar en `opencode.json` la restricción que ya existe en `_analyze-only-protocol.md`: `write: deny`, `bash` con allowlist de solo-lectura para agentes analyze-only | Medio | v1 (refinado) |
| 🟠 Media | Tratar el offset de `.learnings/bias-calibration.json` como corrección obligatoria del score mostrado en README (score − offset promedio), no solo como dato interno | Bajo | Nuevo (v2) |
| 🟠 Media | Añadir tests deterministas a `skill-graph.ps1`, `setup-machine.ps1`, `check-mcp-security.ps1` (los de mayor tamaño/impacto sin cobertura) | Alto | v1 |
| 🟡 Baja | Corregir `catch {}` vacío en `wisdom-stats.ps1:98` (pese a que CYCLE.md dice ya resuelto) | 1 línea | v1 (persiste) |
| 🟡 Baja | Quitar bloque `nuget` de `dependabot.yml` | 1 línea | v1 |
| 🟡 Baja | Simplificar/consolidar niveles de ceremony (ponytail × zona × riesgo) o documentar con ejemplos concretos de cada combinación | Medio | Nuevo (v2) |

---

## 7. Conclusión

La revisión profunda **no cambia el diagnóstico general de v1** (ingeniería de prompts sobresaliente, ejecución con deuda técnica concreta y corregible), pero sí **eleva la severidad real** del proyecto en un punto específico: el pipeline de seguridad en CI tiene un gate que nunca puede bloquear nada, lo cual es más grave que un simple bug de configuración — es una falsa sensación de cobertura de seguridad. Por otro lado, el hallazgo de permisos de v1 se vuelve menos alarmante al confirmar que sí existe una capa de mitigación a nivel de prompt (aunque no a nivel de plataforma). Y el dato más interesante de esta segunda pasada no es técnico sino de proceso: **el propio proyecto ya demostró, con sus propios números, que su auto-scoring tiende a inflarse — la corrección a ese sesgo debería aplicarse al 9.3/10 que hoy se muestra como si fuera neutral.**
