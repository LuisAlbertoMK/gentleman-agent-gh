# Plan: Gate de Execution-Mode contra perfeccionismo/sobre-ingeniería (Hook #5)

**Fecha**: 2026-09-02
**Origen**: sesión 2026-09-02 — debilidad #1 (perfeccionismo/sobre-ingeniería) era
`confidence: unvalidated` (nivel persona, sin doc previo). Diseño de opciones
presentado al owner; owner aprobó Opción B ("procedamos").
**Estado**: IMPLEMENTADO (Opción B — hook de clasificación obligatoria)

## Problema

El perfeccionismo no es un defecto de ejecución: es la AUSENCIA de un momento
estructurado donde responder "¿esto necesita ser perfecto o salir YA?" antes de
actuar. El skill `execution-mode` (QUICK/THOROUGH/DRAFT) existe pero no se invoca
obligatoriamente. Precedente del repo: *"Mecanismos existen, enforcement es nulo"*
(2026-07-28-orchestrator-self-analysis.md:13) — patrón idéntico al que motivó los
hooks #1-#4.

## Opciones evaluadas

| Opción | Mecanismo | Effort | Impact | Riesgo | Veredicto |
|--------|-----------|--------|--------|--------|-----------|
| A | Regla conductual en AGENTS.md | 5 min | bajo — evidencia del repo dice que conducta sola falla | bajo | descartada |
| B | **Hook de clasificación obligatoria** (prompt + reference) | ~10 líneas | alto — mismo patrón validado que hooks #1-#4 | bajo (reversible en 1 commit) | **ELEGIDA** |
| C | Hard gate por script (extender `validate-write-scope.ps1` con chequeo clasificación-vs-diff) | medio | alto | falsos positivos, código que mantener | **diferida** — solo si B falla 2× con hook activo |

## Diseño (Opción B)

Flujo del hook: **clasificar** (via `execution-mode`) → **declarar caps** en el
contract del subagente (o working notes si es directo) → **post-work footprint
check** → si QUICK excede caps: STOP, re-clasificar a THOROUGH con justificación
escrita o recortar. Nunca shipear en silencio un QUICK excedido.

Caps QUICK: ≤3 files, ≤20 líneas/file, cero abstracciones nuevas (interfaces,
factories "por si acaso"), sin pipeline SDD completo.

Detalles completos: `docs/prompts/gentleman-vMK/reference.md` → sección
"Execution-Mode Gate (Hook #5)".

## DoD

- [x] Sección Hook #5 en `docs/prompts/gentleman-vMK/reference.md`
- [x] Este plan documentado (la debilidad deja de ser `unvalidated`)
- [ ] Línea hook #5 en prompt global
      `C:\Users\MK\.config\opencode\prompts\gentleman-vMK.md` (bloque Hooks) —
      **bloqueada por guardrail del config** (`"**/.config/opencode/**": "deny"`
      en write/edit — by design: un agente no edita su propio prompt). Requiere
      paste manual del owner; texto exacto provisto en la sesión.
- Métrica a 30 días: upgrades QUICK→THOROUGH injustificados ≤2/ciclo. Si el
  exceso se sostiene con hook activo → ejecutar Opción C (learning loop:
  2× → catalogar, 3× → regla/hard gate).

## Rollback

Revert del commit que agrega la sección en reference.md — cero dependencias de
código, cero tests afectados. El plan en docs/mejoras queda como registro.
