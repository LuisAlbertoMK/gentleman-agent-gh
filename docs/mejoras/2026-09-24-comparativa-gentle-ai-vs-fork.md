# Comparativa gentle-ai original vs fork gentleman-agent-gh — 2026-09-24

> Archivo único de sesión con TODAS las comparaciones medidas el 2026-09-24.
> Listo para análisis por otro agente. Dictado por el orquestador + verificado en disco donde se indica.

## 1. Encabezado / Entorno

| Campo | Valor |
|---|---|
| Fecha | 2026-09-24 |
| Hardware | Dell Latitude 7420, i7-1185G7 4C/8T, 16 GB RAM, Win11 10.0.26200, SSD NVMe 512 GB, Iris Xe |
| Shells | PS 5.1.26100 + pwsh 7.6.6 en WindowsApps |
| Binario original (scoop) | gentle-ai v1.37.2 — 11,279,872 B (~10.76 MB) |
| Binario original (go-path) | gentle-ai v3.7.0 — 26,621,952 B (~25.39 MB) |
| Repo fork | `C:\Users\LuisOrozco\Downloads\gentleman-agent-gh` |
| Fork en disco (verificado sesión) | código 37.1 MB / total 196.6 MB (incluye node_modules) |
| `opencode.json` (verificado en disco 2026-09-24) | 43,039 B |
| `docs/mejoras/benchmark-baseline.json` (verificado en disco) | stale — baseline de `sync-vmk.ps1 -DryRun -Json`, median 62.13 ms, timestamp 2026-08-28 |

## 2. Tabla recursos (medias de 3 runs)

| Métrica | Original gentle-ai | Fork gentleman-agent-gh | Ratio / nota |
|---|---|---|---|
| Disco binario | v1.37.2 10.76 MB / v3.7.0 25.39 MB (2.36x entre versiones) | código 37.1 MB / total 196.6 MB | Fork código ~1.5x vs v3.7.0; total ~7.7x (node_modules) |
| Arranque original | v1 `--help` ~168 ms | — | baseline rápido v1 |
| Arranque v3.7.0 | ~1887 ms child (Measure con outlier 13 s → 5746 ms) | — | regresión vs v1 |
| Arranque fork | — | in-process 59–98 ms / hijo 397–1017 ms | fork in-process ~7x más rápido que v3.7.0 child |
| RAM | v3.7.0 ~9.7 MB | fork hijo ~77 MB | ~8x a favor del original |
| CPU | 20–40 ms (~1–2 %) | ~510 ms (~129 % 1-core) | ~25x a favor del original |
| GPU | 0 ambos | 0 | sin uso GPU |
| IO lectura | 26 MB = 34 ms | — | — |
| Coste creación proceso | PID muerto a 800 ms con wall 2.5–5 s | — | coste dominante = creación, no ejecución |
| Red | 0 → 353 B/s | — | telemetry no probado |
| Defender | RealTime activo | RealTime activo | Test con exclusión pendiente por no-admin (`IsInRole=False`) |

## 3. Tabla funcional

| Capacidad | Original | Fork (verificado en disco donde se marca) |
|---|---|---|
| Comandos `--help` | 29 (17 + 12 compat) | — |
| Subcomandos `review` | 23 | — |
| Skills | — | 97 (96 + `_shared`) — **verificado**: 97 dirs en `.agents/skills` |
| Agentes | — | 18 (dictado sesión) |
| Scripts | — | 133 top-level `scripts/*.ps1` — **verificado** (342 recursivo con subdirs); 23,483 líneas / 1,109,792 B (dictado sesión) |
| Commands | — | 25 — **verificado** en `commands/` recursivo |
| Pester | — | 174 Pester (dictado sesión) |
| Tests | Go 1.27.1 + 1 `*_test.go`; Playwright config + 2 e2e sin correr; Node v26.9.0 sin test barato | 44 tests (dictado sesión) |

## 4. Tabla tokens

| Métrica | Valor |
|---|---|
| `opencode.json` | 43,039 B (**verificado**), 58 agentes, `limits` con `max_bytes` 4096 + `max_lines` 100 presentes |
| Skills actual | 97 files / 259,967 B / media 2680 B |
| Skills baseline | 91 / 354,334 B / avg 3894 B |
| Delta | −26.6 %, tokens 101238 → ~74276 |
| Histórico Wave1 | 67–82 % |
| Histórico Wave2 | 81–83 % |
| Fuente histórica | `docs/mejoras/token-budget-reduction-20260818.md:39-50,56-57` (citar al auditar) |
| Tooluse | CodeGraph 2–4 K vs grep 8–15 K por llamada |

## 5. Tabla ejecución

| Métrica | Valor |
|---|---|
| Pester pwsh7 (Pester 5.5.0) | TOTAL 1718 / PASSED 1705 / FAILED 0 / SKIPPED 13 / SECONDS 327.4 s — **suite verde** |
| Pester PS5.1 | 192 fallos por `#requires 7` (no es fallo de contenido) |
| Scripts | 133 files / 23,483 líneas / 1,109,792 B |
| 5 scripts clave (pwsh7) | `health-check -Json` 1511 ms exit 1; `benchmark-core -Gate` 1645 ms exit 2; `token-count -Quiet` 781 ms exit 0; `skill-graph` 1024 ms; `check-token-budget` 893 ms |
| Bug conocido | `token-count.ps1:80,82` — display roto sin `-Quiet` (usa `-Quiet` como workaround hasta el fix; fix propuesto: `Write-Host -f`) |
| Baseline arranque pwsh | ~697 ms |
| Node | v26.9.0 sin test barato |
| Go | 1.27.1 + 1 `*_test.go` |
| Playwright | config + 2 e2e sin correr |

## 6. Veredicto simple

- **Original gana recursos puros**: RAM ~8x, CPU ~25x, disco ~1.5x (vs código fork).
- **Fork gana en arranque vs v3.7.0** (~7x in-process), **herramientas** (~5x: 97 skills + 18 agentes + 133 scripts + 25 commands), **tokens** (−26 %), **calidad** (suite Pester verde 1705/1718).
- **Pendientes**: bug display `token-count.ps1:80,82` y baseline stale (`benchmark-baseline.json` pinea `sync-vmk`, no el arranque real).

## 7. Para el próximo agente — preguntas abiertas

1. **Confirmar Defender con terminal elevada** (`IsInRole=False` en esta sesión): re-correr el benchmark de arranque con exclusión vía `Add-MpPreference` / `Remove-MpPreference` y comparar contra los números de §2 (168 ms v1 / 1887 ms v3.7.0 child / 59–98 ms fork in-process). Sin esto, el veredicto de CPU/arranque sigue contaminado por RealTime.
2. **Re-pinear baseline**: `docs/mejoras/benchmark-baseline.json` es stale (sync-vmk 2026-08-28). Generar baseline nuevo del arranque real (v1 vs v3.7.0 vs fork) y versionarlo.
3. **Fix `token-count.ps1:80,82**`: display roto sin `-Quiet`; aplicar `Write-Host -f` y re-correr los 5 scripts clave de §5 para confirmar exits/tiempos.
4. **Auditar 58 agentes** de `opencode.json` (43,039 B, limits 4096/100): ¿cuántos se usan realmente? Cruzar con skills (97) y commands (25) para detectar solapamiento y recorte de tokens adicional.
5. **Cerrar telemetry**: la columna red (0→353 B/s) quedó como "no probado" — medir con red aislada si v3.7.0 hace phone-home.
6. **PS5.1**: los 192 fallos son solo `#requires 7` — decidir si se marca skip formal o se mantiene el ruido.

---
*Generado 2026-09-24. Verificaciones en disco: `opencode.json` 43039 B; `.agents/skills` 97 dirs; `scripts/*.ps1` 133 top-level (342 recursivo); `commands/` 25 files; `benchmark-baseline.json` stale (sync-vmk 2026-08-28). Resto de cifras, dictado de sesión del orquestador.*

## 8. Post-optimización Fase 1+2 (2026-09-24)

> Datos verificados dictados por el orquestador — transcritos sin re-medir.

### O1a — `check-token-budget.ps1` (+26/−11): lazy scans + early-exit

- Recorrido de directorios perezoso + salida temprana cuando se superan límites.
- Failure-path: 83.5 → 43.5 ms (−48 %).
- Tibio child-vs-child: 893 → 807 ms (−9.6 %).
- Caché frío → tibio: −19.1 % (998 → 807 ms).
- Contrato `-Json` intacto: `passed:true`.

### O1b — `benchmark-core.ps1` (19+/5−): Length sin `-Raw` solo en bare Benchmark

- Gate conserva `-Raw` (paridad byte-idéntica, exit 0).
- Bare reporta 258707 B/8 vs exacto 255094 B/7 (no comparar rápido vs baseline).

### O3 — dot-source `platform.ps1` lazy por comando

- Ahorro ~93 ms en Regression/AsyncPush.

### O2 — caché en `$env:TEMP\opencode\counts-cache.json`

- TTL 60 min, fingerprint count+bytes+maxTicks, fallback silencioso.
- `cold.json` vs `warm.json` idénticos.

### Fixes previos

- `token-count.ps1` L80/L82 (2 líneas).
- Baseline re-pineada d9fdb85e (96 skills, 255094 B, 72884 tokens).

### Final N=3

| Modo | Antes | Después | Delta |
|---|---|---|---|
| `-Gate` | 1645 ms | 1385 ms | −15.8 % |
| bare | 781 ms | 1529 ms | +95 % APARENTE pero contaminado (ver nota) |

- Nota bare: run1 frío 1664 → 1391 tendencia + testigo gentle-ai +31.6 % misma sesión = ruido entorno. Re-medir en máquina quieta con warmup.
- RAM sin baseline homólogo (picos 93–107 MB child).
- Scope: 4M+1?? esperados, sin violación.

### Pendientes sin admin

- Exclusión Defender (ticket TI).
- Auditoría 58 agentes.
- Re-medición quieta N=5–10.
