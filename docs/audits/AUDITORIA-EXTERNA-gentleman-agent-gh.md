# Auditoría Externa — gentleman-agent-gh

> Rol aplicado: `external-auditor` (tu propio skill), ejecutado por un agente externo el 2026-07-03.
> Método: `git clone --depth 1`, lectura/diff/grep de 30+ archivos fuente — no solo README. Toda afirmación cita ruta y, cuando aplica, línea.

## Veredicto

Tenés más andamiaje de verificación que cualquier repo personal que haya auditado — 23 anti-patrones catalogados con causa raíz, `external-auditor`, `bias-calibration.json`, cross-ref checks. El problema no es falta de proceso. Es que los tres hallazgos de tu propia auditoría del 23/06 (F1, F2, F3 — las tres marcadas "✅ Done") están rotos otra vez en el snapshot actual, y uno (F3) es funcionalmente grave, no cosmético.

---

## 1. Hallazgo central — los fixes no se sostienen

`docs/operations/external-audit-findings.md` (23/06) dio por resueltos tres hallazgos. Estado real hoy:

| # | Hallazgo (23/06) | Declarado | Verificado ahora (03/07) |
|---|---|---|---|
| F1 | Conteo de skills inconsistente (69 vs 70 real) | ✅ Done | **Roto de nuevo.** `README.md`=67 skills/45 scripts. `package.json`=69 skills. Real: 67 skills+`_shared` (68 dirs) / **52** scripts `.ps1`. Cambiaron los dígitos, no el patrón. |
| F2 | Score/Cycle desactualizado (9.7→9.9, Cycle 7→8) | ✅ Done | **Roto, y peor**: ahora hay DOS archivos "canónicos" de score que discrepan entre sí. `PROJECT-SCORE.md`=9.8/10 (24/06, trend stable, Cycle 9). `docs/operations/project-score.md`=9.9/10 (30/06, trend **down**, Cycle 13). `README.md` + `PLAN-OPTIMIZACION-GENTLEMAN.md` + `docs/hallazgos-completos.md` dicen los tres **10/10**. `docs/ciclos/` ya tiene `cycle15-20260630.md`. Cuatro fuentes, cuatro números. |
| F3 | `install.ps1`/`.sh` instalan el binario de otro repo (`gentle-ai` upstream) | ✅ Done | **No arreglado.** `scripts/install.ps1:42-44` y `scripts/install.sh:17-19` siguen con `$GITHUB_OWNER="Gentleman-Programming"`, `$GITHUB_REPO="gentle-ai"`. `README.md` (Instalación → Windows) sigue mandando a correr exactamente ese script. |

**Hipótesis de causa raíz para F3** (no confirmada con `git blame`, pero consistente con el resto del diseño): `pull-upstream.ps1` sincroniza archivos nuevos/modificados desde `Gentleman-Programming/gentle-ai` (AGENTS.md sección H). Si `install.ps1/.sh` no están en una lista de exclusión explícita, cada sync upstream pisa el fix local con la versión de gentle-ai — que instala gentle-ai, correctamente, para gentle-ai.

**Por qué F3 pesa más que F1/F2**: F1/F2 son metadata cosmética. F3 es funcional — alguien nuevo que sigue tu propio README termina con el binario equivocado instalado.

---

## 2. Otros hallazgos verificados

| # | Symptom | Root cause | Fix | Prevention |
|---|---|---|---|---|
| P0 | `PLAN-OPTIMIZACION-GENTLEMAN.md` y `hallazgos-completos.md` marcan la migración a PS7 como "**BLOQUEANTE — todo depende de esto**" (30+ subagentes, verificado 3x). Solo **10/52** scripts (19%) tienen `#requires -Version 7.6`; el resto declara 5.1. CI (`quality-gate.yml`) corre `shell: powershell` (5.1) en `windows-latest`, sin matrix — pese a que el plan mismo pide "PS 7+ matrix CI" | Brecha entre planificación (excelente, citada, con números) y ejecución. El plan está escrito; no está corrido | Ejecutar FASE A del propio plan antes de sumar más skills/scripts | Gate en CI que bloquee un `.ps1` nuevo sin `#requires -Version 7` |
| P1 | `.gitignore` declara `/skills/` ignorado ("canonical source: `.agents/skills/`"), pero 4 carpetas (`branch-pr`, `chained-pr`, `issue-creation`, `work-unit-commits`) están trackeadas en `skills/` con contenido **divergente** del canónico — `diff` confirma que `skills/branch-pr/SKILL.md` conserva secciones enteras ("When to Use", reglas críticas con links) que `.agents/skills/branch-pr/SKILL.md` ya comprimió/eliminó | Se commitearon antes de agregar la regla al `.gitignore`; nunca se corrió `git rm -r --cached skills/` | `git rm -r --cached skills/` + commit | `cross-ref-check.ps1` debería fallar si `git ls-files skills/` no devuelve vacío |
| P2 | El único job de `quality-gate.yml` corre en `windows-latest`. La ruta "Linux/macOS" del README (copiar `.agents/skills/*` a mano, sin ningún script de `scripts/`) no tiene cobertura automatizada — nadie valida que funcione | Diseño Windows-first heredado, nunca revisitado | Job liviano en `ubuntu-latest` (pwsh viene preinstalado en ese runner) que ejecute los pasos de esa sección del README | Path-filter: cambios a README §Instalación disparan el job |
| P3 | El gate "Overweight skill check" y `karpathy-loop` solo vigilan `.agents/skills/*/SKILL.md` (verificado: 0/68 archivos >3KB, promedio 1.8KB — este número **sí** es correcto). El protocolo Engram (búsqueda→recuperación, con etiqueta explícita STEP A/STEP B en 3 archivos: `sdd-apply`, `sdd-archive`, `sdd-verify`) aparece inline en **9 de 13** archivos `commands/sdd-*.md`, sin usar `_shared/engram-convention.md` — que el propio archivo admite: *"calls are inlined in each SKILL.md. This is supplementary reference"* | El scope de compresión está definido por carpeta (`.agents/skills/`), no por "todo lo que `opencode.json` inyecta como prompt real de subagente" | Extender el gate a `commands/` + `prompts/sdd/`; sacar el bloque Engram a una sola referencia | Iterar el check sobre cada clave `"prompt":` de `opencode.json`, no solo sobre archivos `SKILL.md` |
| P4 | `README.md` (tabla "Multi-Agent Architecture") declara `gentleman-deep`→Claude Sonnet, `gentleman-codex`→GPT-4o, `gentleman-quick`→Haiku. `opencode.json` real asigna `opencode/nemotron-3-ultra-free`, `opencode/deepseek-v4-flash-free`, `opencode/mimo-v2.5-free` — los tres modelos son otros, y los tres de tier gratuito | El README describe una arquitectura aspiracional (o una versión con modelos pagos) que nunca se sincronizó con `opencode.json` — probable cambio por costo, no documentado | Actualizar la tabla del README con los modelos reales, o marcar explícitamente "free-tier equivalents" si es decisión consciente | `cross-ref-check.ps1` debería parsear `agent.*.model` de `opencode.json` contra la tabla del README |
| P5 | `.env.example` (sección MCP Context7) tiene bytes corruptos donde debería haber separadores Unicode `─` — mojibake visible tal cual está commiteado | Mismo patrón que tu propio Anti-patrón #16 ("PS5.1 encoding corruption... Unicode chars corrupted"), pero en un archivo no-`.ps1` — el fix de #16 ("ASCII-only en .ps1") no cubre este caso | Re-guardar `.env.example` en UTF-8 limpio | Extender el chequeo de encoding de #16 a todo archivo de texto del repo, no solo `.ps1` |

---

## 3. Reducción de tokens sin perder calidad

Con tu propia heurística (`token-count.ps1`, 4 chars/token):

- **Unificar los 2 archivos de score** — elimina la ambigüedad de F2 y ~25 líneas duplicadas.
- **`docs/research/` pesa casi lo mismo que las 68 skills juntas**: 242,963 chars ≈ **60,740 tokens**, contra 243,431 chars ≈ **60,857 tokens** de `.agents/skills/`. Las skills tienen gate <3KB y compresión activa; `docs/research/` no tiene ningún control de tamaño ni de vigencia. Irónicamente, `token-context.md` — el doc sobre optimización de tokens — tiene **612 líneas**, uno de los archivos más largos del repo. Candidato directo a auditar: lo que ya esté "compilado" en `karpathy-loop`/`lean-context`/`context-watchdog` (todas <3KB) puede archivarse a `docs/archive/`, que ya existe y ya tiene precedente (`model-router-verdict.md`, `soul.md`).
- **Repo completo ≈ 1,225,830 chars ≈ 306,457 tokens** (md+ps1+sh+json). Referencia útil: justifica por qué `skill-graph.ps1` (sparse loading, −85/−92% reclamado) es arquitectura crítica — pero también muestra que la disciplina de compresión hoy cubre ~20% del peso real del repo (las skills), no el resto.
- **5 snapshots de `intake-report` del mismo día** (13/06, 14:47→15:32 — son iteraciones reales de tuning, verificado con `diff`, no basura) siguen en `docs/metricas/` vivo 3 semanas después. Mover a `docs/archive/` al cerrar el ciclo que los generó.

---

## 4. Riesgo meta — ¿el scoring se optimiza a sí mismo?

`CYCLE.md` (Cycle 6, backlog) registra textual: *"Score expansion: sub-dimensions to break the 10.0 ceiling — ⏳ Deferred — Low impact — taxonomy change, not real improvement."* Cycle 8 lo implementa igual (Pillar 2, ✅). Es una decisión de diseño válida, no un bug — pero es exactamente la pregunta que `karpathy-loop` haría sobre cualquier otra métrica: ¿un 9.9 vs 10.0 refleja calidad real, o la rúbrica se expandió porque venía pegando contra el techo? Vale aplicar el mismo escepticismo anti-hackeo-de-métrica al medidor, no solo al código que mide.

---

## 5. Lo que ya está sólido

- Disciplina de tamaño de skills, **verificada real**: 68/68 archivos ≤3KB (máx 3,060B), promedio 1,791B — coincide con lo que dice `PROJECT-SCORE.md`.
- `prompts/sdd/sdd-apply.md` (1 línea, 131 chars) como despachador puro hacia el `SKILL.md` — indirección elegante, no deuda.
- `.githooks/pre-commit` es POSIX `sh` puro, sin PowerShell — ya prueba que el quality-gate no necesita Windows, lo que abarata P0.
- 23 anti-patrones con fecha, causa raíz y prevención — mecanismo de aprendizaje real, no aspiracional (hay entradas tan específicas como bugs de regex PS5.1 o corrupción de encoding por BOM).
- `external-auditor` + `bias-calibration.json`: ya tenés la arquitectura para lo que este documento hace — este análisis es, en tu propio vocabulario, una corrida de `external-auditor`.
- `review-rules.jsonc` (fuente de verdad declarada para zonas) **sí** coincide con el resumen de `AGENTS.md` — `context_zones.green/yellow/orange/red` en 40/60/80/100% de contexto matchea exacto la tabla GREEN/YELLOW/ORANGE/RED del protocolo. No todo drifteó.

---

## 6. Auto-aplicación

Esta entrega sigue tus propias reglas:

- **Default-FAIL** (`AGENTS.md`): cada hallazgo cita archivo y, donde aplica, línea o número exacto — nada autoevaluado sin evidencia.
- **Anti-patrón #3/#4** (restatement/filler): sin "voy a analizar tu repo", sin resumen de lo pedido, sin cierre cordial.
- **Anti-patrón #2** (over-explaining tool output): los `diff`/`grep` crudos no se pegan; se sintetizan.
- **Paso 0 — Factibilidad**: antes de asumir que F1/F2/F3 seguían resueltos, releí los archivos actuales en vez de confiar en el "✅ Done" de hace 10 días.
- **Formato**: la tabla de la sección 2 usa tu propio esquema de `ANTI-PATTERN-CATALOG.md` (Symptom/Root cause/Fix/Prevention), no uno genérico.
