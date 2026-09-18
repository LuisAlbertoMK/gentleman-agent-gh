# Mejora IO — Commit Working Tree en Slices

## Intent
Desglosar y commitear el working tree de la rama `mejora-io` (9 archivos, 242+/233-) en 3 slices ODD independientes (1 slice = 1 conventional commit, ≤400L por slice, verify en el mismo commit, review log y rollback por slice), con el slice 3 **BLOQUEADO** pendiente de validación del scorer.

## Gate — SUBSTANTIAL
| Criterio | Valor | SMALL? |
|----------|-------|--------|
| Líneas | 242+/233- total (>50L) | ✗ |
| Archivos | 9 (>1) | ✗ |
| Schema/auth/API | Ninguno | ✓ |
| External deps | Ningunas | ✓ |
| Tier | 0 (conocido) | ✓ |
| Commits forecast | 3 (>2) | ✗ |

→ 3 criterios fallan → no cumple SMALL → **SUBSTANTIAL**: crear `odd/tasks/mejora-io-commit.md` con slice plan. (Fuente: `git diff --stat` — 9 files changed, 242 insertions, 233 deletions.)

## Scope In
- Slice 1: fixes en 5 scripts (`sync-global.ps1`, `health-check.ps1`, `inter-track.ps1`, `clean-worktree-temp.ps1`, `sync-n-projects.ps1`)
- Slice 2: migración de ids de modelo en `opencode.json` + `scripts/lib/opencode-base.json`
- Slice 3 (BLOQUEADO): `.project.json` + `docs/metricas/history.jsonl`

## Scope Out
- Cualquier cambio fuera de los 9 archivos listados
- Slice 3: **NO commitear** hasta validar si la caída de score y el drop de keys es regeneración esperada del scorer o pérdida de datos (gate explícito en Verification)

## Slice Plan
| # | Scope | Est. Lines (`git diff --stat`) | Outcome | Commit |
|---|-------|-------------------------------|---------|--------|
| 1 | fix: 5 scripts (`sync-global` 6, `health-check` 17, `inter-track` 6, `clean-worktree-temp` 13, `sync-n-projects` 2) | ~44 diff (~40L lógica real) | Scripts sin catches vacíos ni guardia frágil; sintaxis 5/5 OK + PSSA 0 errores | `fix(scripts): replace empty catch with Write-Debug and harden health-check guard` |
| 2 | chore: `opencode.json` (108) + `scripts/lib/opencode-base.json` (108) | ~216 diff (108+/108-) | Migración de modelos `opencode-go/muse-spark-1.3-contributor`→`opencode/muse-spark-1.3-contributor-free` y `opencode-go/deepseek-v4-flash`→`opencode/nemotron-3-ultra-free`; 0 líneas no-model en lib base | `chore(config): migrate contributor/flash model ids to opencode namespace` |
| 3 | **COMMITTED** `faef378a`: `.project.json` (214) + `docs/metricas/history.jsonl` (1) | ~215 diff | Gate resuelto 2026-09-18 — dictamen investigación profunda = veredicto (a): regeneración esperada (Cycle Activity 10.0→4.0 corrige 10.0 inflado; `subdimensions`/`SD_detail` raíz son legado que el scorer nunca persistió, detalle vive en `dimensions_detail.SD` con `e={"subd":42}`/`r`/`s`). Score 9.5, last_updated 2026-09-18; history.jsonl +1 línea score 9.5 trend down commit `a77a2c4a` | `chore(metrics): update project score to 9.5` |

Total est. lines (diff): ~475 (242+/233-)

## Verification

### Slice 1 — fix (re-ejecutar contra el commit; ya validado en sesión: 5/5 sintaxis OK, PSSA 0 errores)
```powershell
# Sintaxis — Parser API, expect 5/5 OK (0 parse errors c/u)
$scripts = @('scripts/sync-global.ps1','scripts/health-check.ps1','scripts/inter-track.ps1','scripts/clean-worktree-temp.ps1','scripts/sync-n-projects.ps1')
foreach ($s in $scripts) {
  $tokens = $null; $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $s), [ref]$tokens, [ref]$errors) | Out-Null
  '{0}: {1} parse errors' -f $s, $errors.Count
}
```
```powershell
# PSSA — expect 0 errores (salida vacía)
Invoke-ScriptAnalyzer -Path $scripts -Severity Error | Format-Table RuleName, ScriptName, Line
```
Checks de comportamiento (diff contra HEAD):
- `sync-global.ps1`: catch ~:73 con `Write-Debug` + patrón `$null = $DryRun...` :16-19
- `health-check.ps1`: guardia Check1→Check3 :181-190 con `Test-Path 'variable:globalByName'`, rename `$repoSkillsSet`→`$repoSkills` sin residuales → `Select-String 'repoSkillsSet' scripts/health-check.ps1` vacío
- `inter-track.ps1`: 4× empty catch → `Write-Debug`
- `clean-worktree-temp.ps1`: `$aborted`→`$escapeReasons` ArrayList :152/:168/:191/:195/:222 + 1 empty catch → `Write-Debug`; `Select-String '\$aborted' scripts/clean-worktree-temp.ps1` vacío
- `sync-n-projects.ps1`: 1 empty catch → `Write-Debug`

### Slice 2 — chore mecánico
```powershell
# Cero líneas no-model en lib base — expect vacío
git diff -U0 -- scripts/lib/opencode-base.json | Select-String '^[+-][^+-]' | ForEach-Object { $_.Line.TrimStart('+-') } | Where-Object { $_ -notmatch 'muse-spark|nemotron' }
# Sustituciones exactas en AMBOS archivos (opencode.json y lib base) — expect 2 True / 2 False
$files = @('opencode.json','scripts/lib/opencode-base.json')
foreach ($f in $files) {
  $raw = Get-Content $f -Raw
  '{0}: nuevo muse-spark -> {1} | nuevo nemotron -> {2} | viejo muse-spark -> {3} | viejo deepseek -> {4}' -f $f,
    ($raw -match 'opencode/muse-spark-1.3-contributor-free'),
    ($raw -match 'opencode/nemotron-3-ultra-free'),
    ($raw -match 'opencode-go/muse-spark-1.3-contributor'),
    ($raw -match 'opencode-go/deepseek-v4-flash')
}
```
Esperado: `True True False False` por archivo; diff de ambos archivos con la misma sustitución 108+/108-.

### Slice 3 — BLOQUEADO (NO ejecutar hasta autorización)
Gate de validación explícito — solo se commitea si la caída es **regeneración esperada**:
1. Regenerar `.project.json` con el runner del scorer sobre los mismos inputs y comparar con el working copy: si `subdimensions` y `SD_detail` **reaparecen** → el drop del working copy era pérdida de datos → **NO commit**; restaurar ambos archivos y reportar bug del scorer.
2. Si el scorer regenera **sin** esas keys de forma determinista en score 9.5 → regeneración esperada → commit OK.
3. `history.jsonl`: validar que la nueva línea (score 9.5, trend down, commit `a77a2c4a`, 2026-09-18) mantiene el esquema de la línea previa (mismos campos) y que `a77a2c4a` existe en `git log`.

### Global
- [ ] `git diff --stat` por slice ≤400L
- [ ] Repo funciona tras cada commit independientemente
- [ ] Tests/verify en el mismo commit que el behavior

## Review Log
| Date | Slice | Reviewer | Notes |
|------|-------|----------|-------|
| 2026-09-18 | 1 (fix scripts) | plan-execution | `90c21b4d` — Parser 5/5 OK, PSSA 0 errores, 0 residuales `repoSkillsSet`/`$aborted`, gate 28/28; 5 files, 28+/16- |
| 2026-09-18 | 2 (chore config) | plan-execution | `67bad1bc` — 108+/108- por archivo, 0 líneas no-model (100% `"model":`), check plan `True True False False`, sustitución idéntica ambos archivos, gate 28/28; 2 files |
| 2026-09-18 | 3 (metrics) | plan-execution | `faef378a` — gate desbloqueado (dictamen veredicto a: regeneración esperada); `a77a2c4a` en git log, `dimensions_detail.SD` conserva detalle (`e={"subd":42}`, `r="Depth: 42 sub-dims: 9.4/10"`, `s=9.4`), history.jsonl esquema igual a línea previa, gate 28/28; 2 files. Plan doc commiteado aparte: `docs(odd)` |

## Rollback
Cada slice commitea independiente; los 3 slices NO se superponen en archivos, por lo que revertir N no toca N-1 ni N+1. Orden de revert (inverso, para restaurar el working tree original):
1. `git revert <hash3>` — `.project.json` + `docs/metricas/history.jsonl` (solo si el gate autorizó el commit; si el gate falla, no existe commit 3 y no hay rollback que aplicar)
2. `git revert <hash2>` — `opencode.json` + `scripts/lib/opencode-base.json`
3. `git revert <hash1>` — `scripts/sync-global.ps1`, `scripts/health-check.ps1`, `scripts/inter-track.ps1`, `scripts/clean-worktree-temp.ps1`, `scripts/sync-n-projects.ps1`