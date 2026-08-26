# Verificación Real — Prioridades Sugeridas (Entire, Refract, Bun, Speculation, GSAP)

**Fecha**: 2026-08-27 — **Branch**: experimento/priority-verify-2026-08-27 — **Punto seguridad**: punto-seguridad-2026-08-27-priority-verify @a5a1d886 (9.9)
**Protocolo**: PEV + 3 subagentes paralelos + sandbox Temp + write-scope + cross-ref + PSSA + score

## Resumen Ejecutivo
| Prioridad | Veredicto Real | Métrica Medida | Beneficio para gentleman-agent-gh |
|---|---|---|---|
| **Entire Checkpoints** | **No es npm, es host git** | `@entire/checkpoints` → 404 npm, `entire.io` → Git hosting, install `curl https://entire.io/install.sh \| bash`, repo 3828 commits vs BITACORA 21KB/180 líneas | Complementario a BITACORA (sesión↔commit), no reemplazo. Requiere migrar hosting, no justificado ahora |
| **Bun 1.4** | **Instalado 1.3.14, no 1.4** | `bun --version` 1.3.14, `pnpm` 11.5.2, cold-start 1.18s vs 1.17s (igual), `npm` bloqueado por permission-gate, `Bun.Archive/TOML` no en help 1.3.14 | Mantener pnpm (ADR-046 allow), Bun disponible pero sin ventaja 1.4 hasta upgrade |
| **Refract** | **Cloneable, listo** | `git ls-remote Refractdev/refract-dev` ok, clone --depth1 ok, README "# Refract", candidato `score-auto.ps1` 262 líneas/12KB | Viable para refactor determinista de skills/scripts, piloto recomendado |
| **Speculation Rules** | **No aplica** | 0 HTML en docs/, 59 md/502KB, `Test-Path docs/index.html` False, MDN: solo para MPAs | Solo si se genera site estático para docs |
| **GSAP 3.15** | **No usado** | `pnpm view gsap` 3.15.0 disponible, 0 menciones en .agents/skills, baseline-ui 32 líneas CSS-native | Solo si hay UI interactiva con timelines, hoy marginal |

## Evidencia por Subagente

### Subagente 1 — Entire (read-only)
- `webfetch npmjs.com/package/@entire/checkpoints` → 404 redirect login `confidence: high`
- `webfetch entire.io` → "Git hosting for agents and humans", Checkpoints = session+commit pairing en host `confidence: high`
- `git log --all | Measure-Object` → 3828 commits `<1s`
- `BITACORA.md` → 21,006 bytes/180 líneas `<1s`
- Conclusión: Entire es servicio, no CLI npm. Beneficio real = traza automática por commit, pero requiere cambiar hosting. No reemplaza BITACORA (log humano).

### Subagente 2 — Bun + Refract
- `bun --version` → 1.3.14 (no 1.4) `confidence: high`
- `pnpm --version` 11.5.2, `npm` bloqueado (deny pattern) `confidence: high`
- `Measure-Command` bun vs pnpm → 1.18s vs 1.17s (igual cold-start) `confidence: high`
- `bun --help` → no Archive/TOML/bun:bundle (features 1.4) `confidence: high`
- `git ls-remote Refractdev/refract-dev` → refs ok, clone depth1 → README "# Refract" `confidence: high`
- `score-auto.ps1` → 262 líneas `confidence: high`

### Subagente 3 — Speculation + GSAP
- `Test-Path docs/index.html` False, 0 HTML en docs/ `confidence: high`
- `Get-ChildItem docs/mejoras/*.md | Measure-Object` → 59 archivos/502KB `confidence: high`
- `pnpm view gsap version` → 3.15.0 `confidence: high`
- `Select-String gsap .agents/skills/*.md` → 0 hits `confidence: high`

## Verificación Protocolar
- `score-auto -Json` → 9.9 (CC10 BP10 SD9.2 SP9) sin regresión `confidence: high`
- `cross-ref-check -Json` → allClean true `confidence: high`
- `pssa-gate -Mode Check` → PASSED 95 baseline `confidence: high`
- `validate-write-scope -AllowedPaths "docs/mejoras/*" -BaseRef HEAD` → CLEAN (solo este reporte) `confidence: high`
- `git diff --stat HEAD` → 1 file (este reporte) `confidence: high`

## Recomendación Verificada
1. **No instalar Entire ahora** — beneficio teórico no medible sin migrar hosting. Mantener BITACORA+Engram.
2. **No migrar a Bun** — pnpm sigue preferido ADR-046; upgrade a Bun 1.4 solo para pilotar Archive/TOML si hay caso.
3. **Piloto Refract** — sí, sobre `score-auto.ps1` (12KB) en Temp, sin tocar repo.
4. **Speculation/GSAP** — backlog, solo si hay site/docs UI.

**Punto seguridad intacto**: punto-seguridad-2026-08-27-priority-verify @a5a1d886 — revert con `git reset --hard punto-seguridad-...`
