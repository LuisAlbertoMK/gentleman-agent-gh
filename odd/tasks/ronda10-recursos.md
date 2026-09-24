# Ronda 10 - Optimización de recursos (RAM/CPU/GPU/VRAM/IO/Tokens/Security) - ODD Gate + Slice Plan + RDD Freeze (Fase 1: análisis, SIN código)

> Fase 1 - análisis y freeze. NO código, NO commit, NO push (deny), NO merge, NO tocar main.
> Rama: `experimento/mejora-ronda10-recursos` - HEAD `cd7c4c25` (tip R9, linaje ronda8→ronda9→ronda10, ramas apiladas) - main `77e983ce` intacto (solo lectura).
> Este archivo (`odd/tasks/ronda10-recursos.md`) es el ÚNICO write permitido de la fase. La ejecución lo commitea después (1 commit por slice + receipts).
> Precedente de formato: `odd/tasks/ronda9-contratos-ci.md` (200L) y `odd/tasks/ronda8-contratos.md` (194L): inventario + gate Q&A + ODD gate por slice + slice plan + freeze/tiers + verify + receipt templates + review log + rollback + resto a futuro. Este documento los imita en estructura.
> Alcance R10 mínimo: S1–S4 abajo. S5+S6 se derivan a R11 (sección 9, por capacidad/riesgo, no por falta de evidencia).

## 0. Inventario medido (evidencia citada de subagentes A/B/C, `confidence` por claim)

| # | Item | Estado medido | Evidencia |
|---|---|---|---|
| H1 | Host CPU/RAM | AMD Ryzen 7 3700U 4C/8T 2.3GHz; RAM 14.9GB (~7.7GB libre) | subagente A, `confidence: high` |
| H2 | GPU/VRAM | RX Vega 10 iGPU 2GB SHARED, sin VRAM dedicada; nvidia-smi inaplicable | subagente A, `confidence: high` |
| H3 | Discos/OS | ADATA SU650 240GB SATA + WALRAM 128GB NVMe; C: 56GB libre; Win11 Home 26200 | subagente A, `confidence: high` |
| H4 | Procesos vivos | 2× opencode RSS 1375MB/Priv 3066MB + 957MB/2135MB; PriorityClass Normal; Priv≫RSS = underreport bmalloc | subagente A, `confidence: medium` |
| G1 | small_model | AUSENTE en opencode.json | subagente A, `confidence: high` |
| G2 | subagent_depth | AUSENTE en opencode.json | subagente A, `confidence: high` |
| G3 | watcher | NULL en opencode.json | subagente A, `confidence: high` |
| G4 | mcp_timeout | experimental.mcp_timeout=60000 + codebase-memory 60000 + engram 30000 (peor que default 5000, fail-slow) | subagente A, `confidence: high` |
| G5 | snapshot | NULL en opencode.json | subagente A, `confidence: high` |
| G6 | Perfil en archivo | EXISTEN `scripts/hardware-profile.ps1`, `monitor-opencode.ps1`, `heap-snapshot.ps1`, `scripts/opencode-configs/{low,medium,high}-resource.json` + `profile-go/zen.json` — perfil NO aplicado en opencode.json | subagente A, `confidence: high` |
| G7 | compaction | `{prune:true,reserved:4000,keep.tokens:8000}` = CERRADO | subagente A, `confidence: high` |
| R1 | Referencia rota | `scripts/optimize-system.ps1` NO existe pero referenciado en `.agents/skills/development-mode/SKILL.md:25,34,47` y `docs/skills/development-mode/reference.md:12,68,186` | subagente A, `confidence: high` |
| T1 | Prompt estático | Orquestador ≈16.8K tok (opencode.json 23,608B + AGENTS.md 2,731B + prompts/ 40,822B = 67,161B ÷4) | subagente B, `confidence: high` |
| T2 | Skills optimizadas | 97 SKILL.md, 267,480B total, avg 2,758B vs 7,213B baseline C29; over5KB 20→1 (solo judgment-day 5,459B); over3KB 56→10; 97/97 con token_budget; carga sparse | subagente B, `confidence: high` tamaños / `medium` carga |
| T3 | opencode.db | 5.6GB: 1,234 sessions, 417M in / 17.3M out (ratio 24:1), cache_read 3.06B, $5.11, 104 compactions; ~34 msgs/sess, ~38 tools/sess | subagente B, `confidence: high` |
| T4 | laguna-high OUTLIER | 75 sess × 2.24M in/sess = 168M in ($1.16, 6× promedio) | subagente B, `confidence: high` |
| T5 | Deuda tokens | Cap laguna-high pendiente; db 5.6GB creciendo; cache_read 3B domina facturación; mcp_timeout 60000 ABIERTO (playbook proponía 10s) | subagente B, `confidence: high` |
| S1 | Default-allow | 71 reglas bash (allow 15/ask 7/deny 49) con `"*":"allow"`; MISSING en runtime: curl,wget,npx,npm install,node,pip install,ftp,scp,rsync,docker,git clone (solo Invoke-WebRequest/RestMethod en deny) | subagente C, `confidence: high` |
| S2 | Drift SSoT-vs-runtime | `prompts/shared/_permission-templates.md:24-39,61-68` y `tests/permission-rules-consistency.Tests.ps1:40-52` exigen curl/wget/node en deny; runtime no los tiene; BITACORA documenta drift (4 fallos) | subagente C, `confidence: high` |
| S3 | Secretos 3 capas | Hook staged-diff `:219`, `.gitleaks.toml:5-49`, CI trufflehog --only-verified, con FN conocido | subagente C, `confidence: high` capas / `medium` tasa |
| S4 | MCP | 5 servers, 3 enabled (codebase-memory local, engram local, context7 remote allowlisted `security-audit-mcp.ps1:51`); headroom+chrome-devtools DISABLED; chrome-devtools npx pineado @1.6.0 | subagente C, `confidence: high` |
| S5 | Supply chain | 3 devDeps, sin lockfile/npm audit; --no-verify bypassa 21 checks; rm/ssh SÍ están deny (NO citar como hueco) | subagente C, `confidence: medium-high` |
| S6 | #693 parcial | ADR-046 abrió python/npm run,ci,test + pip freeze,list,show; npm install/npx/node/pnpm SIN regla | subagente C, `confidence: medium` |
| B0 | Baseline riesgo | Score actual 10.0 (cycle39) → regla: ningún slice debe bajarlo; receipt honesto si algo no se puede probar | plan R10, `confidence: high` en regla / `medium` en score remoto |
| OK | tools/output | `tools={codebase-memory*,engram*}`; `tool_output={4096B,100 líneas}` OK | subagente A, `confidence: high` |

## 1. Gate: 3 preguntas respondidas

### Q1. ¿Qué 3–5 oportunidades de mayor ratio ganancia/riesgo?

| Rank | Oportunidad | Ganancia | Riesgo | Ratio |
|---|---|---|---|---|
| 1 | S1 fix referencia rota `optimize-system.ps1` (retirar del skill o stub) | Integridad docs/skills, cero refs rotas | Casi 0 (solo docs, sin runtime) | Muy alto |
| 2 | S3 mcp_timeout 60000→10000 (fail-fast; engram 30000→10000) | Latencia fail-fast, menos hilos colgados RAM/CPU | Bajo-medio (reintentos más agresivos; mitigación: monitor 1 semana) | Alto |
| 3 | S2 aplicar perfil HW real (watcher.ignore + subagent_depth + small_model) | RAM/CPU/IO + tokens (menos indexación, menos fan-out) | Medio (cambia comportamiento agente) → OWNER | Alto con aprobación |
| 4 | S4 cerrar deny curl/wget/npx/npm install/node/pip install (+ftp/scp/rsync/docker/git clone) | Seguridad (score 10.0 no baja; cierra drift SSoT) | Medio (puede romper flujos que usan node/npx; mitigación: allowlist explícita + test consistencia) → OWNER | Alto con aprobación |
| 5 | S6 higiene opencode.db 5.6GB (vacuum/archive/retención) | Disco + queries más rápidas | Medio-alto (destructivo sin backup) → DERIVADO a R11 | Medio (fuera R10) |

### Q2. ¿Qué es config-level (sin código) vs código?

- **Config-level, sin código (opencode.json / prompts/** — OWNER-DECISION):** S2 (watcher.ignore, subagent_depth, small_model), S3 (mcp_timeout + timeouts MCP), S4 (reglas permiso runtime en opencode.json; SSoT en `prompts/shared/_permission-templates.md`), S5 cap/routeo laguna-high vía compaction/small_model routing (diseño en R11).
- **Código/scripts/docs (autónomo salvo que toque superficie compartida):** S1 (editar `.agents/skills/development-mode/SKILL.md` + `docs/skills/development-mode/reference.md`, o crear stub `scripts/optimize-system.ps1` — decisión en slice, ≤40L), S6 (script vacuum/archive + test, R11), S5 si requiere router code (R11).
- **Regla:** todo lo que toque `opencode.json` o `prompts/**` = OWNER-DECISION (sección 4). Lo demás = autónomo dentro de su slice-scope.

### Q3. ¿Cómo evitar degradar seguridad o determinismo (receipts/gates)?

- **Baseline 10.0 (cycle39) no baja:** cada slice re-corre `security-audit-mcp.ps1` (o gate vigente) + `tests/permission-rules-consistency.Tests.ps1` donde aplique; si baja → FAIL del slice, rollback, STOP.
- **Determinismo:** `Test-Json` para opencode.json tras cada edit config; `git diff` acotado al scope; sin `--no-verify` (bypassa 21 checks); receipts 011+ con freeze `HEAD-<base7>-<diff8>` + `lines_changed` solo scope.
- **Receipt honesto:** lo no-probable en local (CI remoto, badge, VRAM dedicada n/a en iGPU shared, facturación laguna-high) se declara `pendiente`/`n/a`, nunca PASS maquillado (precedente `rdd-receipt-001`).

## 2. ODD Gate por slice (1 slice = 1 conventional commit ≤400L)

Regla (precedente `ronda7-arranque.md` + skill `odd`): ALL criteria must pass para SMALL (≤50L, 1 file + test compañero, sin schema/auth/API, sin deps externas, ≤2 commits); si alguno falla → SUBSTANTIAL (1 slice = 1 commit ≤400L).

| Criterio (`odd`) | Umbral SMALL | R10-S1 ref rota (Tier 1) | R10-S2 mcp_timeout (Tier 2) | R10-S3 perfil HW (Tier 2) | R10-S4 permisos SSoT (Tier 2) |
|---|---|---|---|---|---|
| Líneas est. | ≤50L | ~20-40L → PASS | ~10-25L → PASS (pero falla otro) | ~30-60L → PASS/FAIL borde (pero falla otro) | ~40-80L → FAIL |
| Files | 1 (+ test) | 2 (skill + reference.md; o + stub) → FAIL | 1 (`opencode.json`) → PASS (pero falla otro) | 1-2 (`opencode.json` + nota) → FAIL borde | 2-3 (`opencode.json` + SSoT md + test ext) → FAIL |
| Schema/auth/API | None | Docs solamente → PASS | Config compartida runtime (timeouts) → FAIL | Config compartida (watcher/depth/model) → FAIL | Superficie seguridad (deny/allow) → FAIL |
| Deps externas | None | None → PASS | None → PASS | None → PASS | None → PASS |
| Commits forecast | ≤2 | 1 | 1 | 1 | 1 |
| **Veredicto** | - | **SUBSTANTIAL → Tier 1** | **SUBSTANTIAL → Tier 2 OWNER** | **SUBSTANTIAL → Tier 2 OWNER** | **SUBSTANTIAL → Tier 2 OWNER** |

- **Orden mandatorio: S1 → S2 → S3 → S4.** S1 primero (autónomo, desbloquea credibilidad docs, cero riesgo runtime). S2 antes que S3 (fail-fast primero para medir timeouts limpios antes de cambiar fan-out del perfil). S4 último (superficie seguridad más sensible; se verifica contra baseline 10.0 con todo lo anterior ya estable). Invertir S4 antes = riesgo de romper flujos sin timeouts/perfil fijados.
- **R10 total: 4 slices, 4 commits, ~100-205L agregadas.** Ningún slice excede 400L → **nada se deriva por capacidad dentro de R10**; S5+S6 a R11 por riesgo/diseño (sección 9).
- **OWNER vs autónomo:** S1 autónomo; S2+S3+S4 OWNER-DECISION (opencode.json y/o prompts/**). Ejecución NO aplica S2–S4 sin aprobación explícita del owner; S1 puede avanzar solo.

## 3. Slice Plan (scope / est. lines / outcome / orden)

- **R10-S1 - `docs(skills): fix referencia rota optimize-system.ps1`** (Tier 1, AUTÓNOMO) - PRIMERO
  Scope: en `.agents/skills/development-mode/SKILL.md:25,34,47` + `docs/skills/development-mode/reference.md:12,68,186`: retirar referencia ROTA o sustituir por stub `scripts/optimize-system.ps1` documentado (una de las dos, no ambas; default: retirar + nota "perfil en `scripts/opencode-configs/`"). NO tocar `opencode.json`, NO tocar permisos, NO tocar prompts. Est. ~20-40L en 2-3 files, 1 commit. `confidence: high`.
  Outcome: `Select-String 'optimize-system' SKILL.md + reference.md` = 0 hits rotos (o 1 stub existente y testeado).
- **R10-S2 - `config(mcp): mcp_timeout fail-fast 60s→10s`** (Tier 2, OWNER-DECISION) - SEGUNDO (requiere S1)
  Scope: solo `opencode.json`: `experimental.mcp_timeout` 60000→10000 + codebase-memory 60000→10000 + engram 30000→10000 (o valores owner; playbook proponía 10s). Validar `Test-Json` + arranque MCP. NO tocar watcher/modelos, NO tocar permisos. Est. ~10-25L en 1 file, 1 commit. `confidence: medium` (riesgo: reintentos; mitigación: ventana observación).
  Outcome: timeouts fail-fast; MCP verde en arranque local; latencia peor-caso 6× menor.
- **R10-S3 - `config(perf): aplicar perfil hardware real`** (Tier 2, OWNER-DECISION) - TERCERO (requiere S2)
  Scope: solo `opencode.json` (+ nota en plan): `watcher.ignore` (node_modules/.git/dist), `subagent_depth` acotado, `small_model` definido (valores desde `scripts/opencode-configs/medium-resource.json` o decisión owner; iGPU shared sin VRAM: nada de offload GPU). NO tocar timeouts, NO tocar permisos. Est. ~30-60L en 1-2 files, 1 commit. `confidence: medium`.
  Outcome: menos indexación IO/CPU, menos fan-out RAM, routeo barato activo; `monitor-opencode.ps1` sin regresión.
- **R10-S4 - `fix(security): reconciliar SSoT permisos vs runtime`** (Tier 2, OWNER-DECISION) - CUARTO (requiere S3)
  Scope: `opencode.json` (deny: curl,wget,npx,npm install,node,pip install +ftp/scp/rsync/docker/git clone según SSoT) + `prompts/shared/_permission-templates.md` si el SSoT necesita ajuste + extensión `tests/permission-rules-consistency.Tests.ps1` (Its que fallan si el drift reaparece). rm/ssh ya deny (no tocar). --no-verify sigue bypassando 21 checks (declarado, no se cierra aquí). Est. ~40-80L en 2-3 files, 1 commit. `confidence: medium` (riesgo ruptura flujos node/npx → allowlist explícita documentada).
  Outcome: SSoT=runtime (0 drift); `permission-rules-consistency` PASS; score seguridad no baja de 10.0.

## 4. Freeze EN ESTA RAMA + Tier + review plan + OWNER-DECISIONS

- **Freeze point:** rama `experimento/mejora-ronda10-recursos` @ HEAD `cd7c4c2527d3df95f38880593c189022326525fe` (prefijo `cd7c4c25` OK, = tip R9). Cada slice congela su base con `git rev-parse HEAD` + `git diff | git hash-object --stdin` (8 chars) en su receipt (plantillas sección 6, precedente `.rdd/rdd-receipt-007.json`). `main@77e983ce` nunca se toca.
- **OWNER-DECISIONS (requieren aprobación explícita antes de ejecutar):** S2 (valores timeout en `opencode.json`), S3 (valores watcher/subagent_depth/small_model en `opencode.json`), S4 (matriz deny final + allowlist node/npx si aplica, toca `opencode.json` y/o `prompts/**`). Sin "sí" del owner → esos slices quedan en `SKIP` con receipt honesto, no se aplican.
- **Autónomo:** S1 (docs/skills). R11 (S5/S6) requerirá su propio gate + owner (retención db, cap facturación).
- **Tiers y review (RDD rule 4):**
  - S1 Tier 1: `code-review-agent` 4R simple. Sin auto-fix en FAIL (max 2 intentos; al 3ro STOP + escalar).
  - S2/S3 Tier 2: `code-review-agent` 4R BLOCKER-capable OBLIGATORIO; `judgment-day` dual en FAIL. Nunca auto-fix en FAIL Tier 2. `Test-Json` opencode.json + arranque MCP verde obligatorios.
  - S4 Tier 2 seguridad: igual que S2/S3 + `security-audit-mcp.ps1` score ≥10.0 + `permission-rules-consistency` PASS. Cualquier baja de score = FAIL + rollback inmediato.
- **Write-scope por slice:** solo los paths de su Scope (sección 3) + su receipt en `.rdd/rdd-receipt-01{1,2,3,4}.json`. Cualquier path fuera → STOP y nuevo slice.

## 5. Verify por slice (comandos esperados, mismo commit)

- **S1:** `Select-String -Path .agents/skills/development-mode/SKILL.md,docs/skills/development-mode/reference.md -Pattern 'optimize-system'` (0 hits, o stub existe vía `Test-Path scripts/optimize-system.ps1`) + `pre-commit run --all-files` si aplica a md. Esperado: cero refs rotas.
- **S2:** `Get-Content opencode.json -Raw | Test-Json` (`True`) + `Select-String '"mcp_timeout"' opencode.json` (=10000 o valor owner) + arranque MCP (codebase-memory+engram OK) + `Invoke-Pester` smoke si existe. Esperado: JSON válido + timeouts fail-fast + MCP verde.
- **S3:** `Test-Json` opencode.json (`True`) + `Select-String 'watcher|subagent_depth|small_model' opencode.json` (presentes) + `powershell scripts/monitor-opencode.ps1` (sin regresión RSS/Priv) + `Invoke-Pester` smoke. Esperado: perfil aplicado, recursos ≤ baseline.
- **S4:** `Invoke-Pester tests/permission-rules-consistency.Tests.ps1` (PASS, incluye nuevas Its curl/wget/npx/node) + `security-audit-mcp.ps1` (score ≥10.0, no baja) + `Test-Json` opencode.json. Esperado: 0 drift SSoT-vs-runtime, score intacto. Brecha remota se declara pendiente, no PASS.

## 6. Receipt templates (plantillas, se rellenan al ejecutar cada slice)

```json
// .rdd/rdd-receipt-011.json (R10-S1, Tier 1 autónomo)
{
  "id": "rdd-receipt-011",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R10-S1 <commit-msg> en rama experimento/mejora-ronda10-recursos. diff8=<diff8> = working tree limpio (git diff vacio). lines_changed=<n> solo scope.",
  "tier": 1,
  "tier_justification": "RDD Risk Tiers: Tier 1 = solo docs/skills (SKILL.md + reference.md, +stub opcional). Sin runtime, sin opencode.json. Autónomo.",
  "files": [".agents/skills/development-mode/SKILL.md", "docs/skills/development-mode/reference.md"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "Select-String optimize-system 0 hits rotos (o stub Test-Path True).",
  "review": { "status": "<4R-verdict>", "method": "code-review-agent 4R", "gaps": [] },
  "blockers": [],
  "next": ["R10-S2 (OWNER)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-012.json (R10-S2, Tier 2 OWNER)
{
  "id": "rdd-receipt-012",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R10-S2 <commit-msg> en rama experimento/mejora-ronda10-recursos. OWNER-DECISION: valores timeout aprobados <valores>.",
  "tier": 2,
  "tier_justification": "RDD Risk Tiers: Tier 2 = opencode.json compartido (timeouts MCP, afecta todos los runs). Sin skip de owner.",
  "files": ["opencode.json"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "Test-Json True + mcp_timeout=<v> + MCP verde. Sin approval owner => SKIP honesto.",
  "review": { "status": "<4R-verdict BLOCKER-capable>", "method": "code-review-agent 4R BLOCKER-capable", "gaps": [] },
  "escalation": "judgment-day",
  "blockers": [],
  "next": ["R10-S3 (OWNER)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-013.json (R10-S3, Tier 2 OWNER)
{
  "id": "rdd-receipt-013",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R10-S3 <commit-msg> en rama experimento/mejora-ronda10-recursos. OWNER-DECISION: perfil HW <low|medium|high> aprobado. iGPU shared: sin offload VRAM.",
  "tier": 2,
  "tier_justification": "RDD Risk Tiers: Tier 2 = opencode.json (watcher/subagent_depth/small_model, cambia comportamiento agente).",
  "files": ["opencode.json"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "Test-Json True + watcher/subagent_depth/small_model presentes + monitor sin regresion. Sin approval => SKIP.",
  "review": { "status": "<4R-verdict BLOCKER-capable>", "method": "code-review-agent 4R BLOCKER-capable", "gaps": [] },
  "escalation": "judgment-day",
  "blockers": [],
  "next": ["R10-S4 (OWNER)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

```json
// .rdd/rdd-receipt-014.json (R10-S4, Tier 2 OWNER seguridad)
{
  "id": "rdd-receipt-014",
  "freeze": "HEAD-<base7>-<diff8>",
  "freeze_note": "Slice R10-S4 <commit-msg> en rama experimento/mejora-ronda10-recursos. OWNER-DECISION: matriz deny final aprobada.",
  "tier": 2,
  "tier_justification": "RDD Risk Tiers: Tier 2 seguridad = permisos runtime + SSoT (afecta todos los runs; score 10.0 no debe bajar).",
  "files": ["opencode.json", "prompts/shared/_permission-templates.md", "tests/permission-rules-consistency.Tests.ps1"],
  "lines_changed": "<n>",
  "lines_deleted": 0,
  "verdict": "PASS|FAIL|SKIP",
  "verdict_note": "permission-rules-consistency PASS + security-audit score >=10.0 + 0 drift. Sin approval => SKIP. --no-verify declarado fuera.",
  "review": { "status": "<4R-verdict BLOCKER-capable>", "method": "code-review-agent 4R BLOCKER-capable + security-audit", "gaps": [] },
  "escalation": "judgment-day",
  "blockers": [],
  "next": ["R11 (S5+S6)"],
  "auto_fix": false,
  "timestamp": "<date-time>"
}
```

## 7. Review Log (vacío en Fase 1, se rellena al ejecutar)

| Slice | Reviewer/método | Veredicto | Fecha | Notas |
|---|---|---|---|---|
| R10-S1 | inline 4R self-check (Tier 1) | PASS | 2026-09-24 | Enfoque A: 6 refs rotas retiradas → hardware-profile.ps1 + opencode-configs/; Select-String 0 hits; cross-ref PASS; frontmatter 117/117; SKILL.md 2831→2785B (budget 2582×1.1 OK) |
| R10-S2 | (pendiente, OWNER) | - | - | - |
| R10-S3 | (pendiente, OWNER) | - | - | - |
| R10-S4 | (pendiente, OWNER seguridad) | - | - | - |

## 8. Rollback (por slice, orden inverso)

- S4: `git revert <commit-S4>` o restaurar hunk deny en `opencode.json` + SSoT + test; re-correr `permission-rules-consistency` (PASS) + `security-audit-mcp.ps1` (score ≥10.0).
- S3: `git revert <commit-S3>` o quitar `watcher.ignore/subagent_depth/small_model` en `opencode.json`; `Test-Json` + `monitor-opencode.ps1` (vuelve a baseline).
- S2: `git revert <commit-S2>` o restaurar timeouts 60000/60000/30000; `Test-Json` + arranque MCP.
- S1: `git revert <commit-S1>` o reponer refs originales en SKILL.md + reference.md; `Select-String optimize-system` vuelve a hits conocidos.
- Nunca `git reset --hard` sobre trabajo ajeno; nunca tocar `main`; el plan R8/R9 no se toca en ningún rollback.
- Reposo final: repo vuelve a HEAD `cd7c4c25` + este plan (uncommitted en Fase 1; commiteado por la ejecución después).

## 9. Para Ronda 11+ (resto declarado, fuera de R10 mínimo)

1. **S5 cap/routeo laguna-high (R11):** 75 sess × 2.24M in = 168M ($1.16, 6× promedio). Requiere análisis por-sesión (qué skill/ruta genera el outlier) + diseño de cap (max-tokens por sesión, routeo a small_model, alerta) + decisión facturación con dueño. Est. ~60-120L + política. `confidence: medium`. No entra en R10 por riesgo de romper casos largos legítimos sin diseño previo.
2. **S6 higiene opencode.db 5.6GB (R11):** vacuum/archive/retención (1,234 sessions, 104 compactions, cache_read 3B). Requiere backup + ventana mantenimiento + decisión retención con dueño (cuántas sesiones, qué borrar, dónde archivar). Destructivo → Tier 2 con rollback por backup, nunca `reset --hard`. Est. ~40-90L (script + test + runbook). `confidence: medium`.
3. **Compaction/G5/G7 (futuro):** `snapshot` NULL, compaction cerrado `{prune:true,reserved:4000,keep:8000}` — evaluar abrir solo con datos S5/S6; hoy no se toca (determinismo receipts).
4. **Supply chain (futuro):** lockfile + `npm audit` (3 devDeps magras); `--no-verify` bypassa 21 checks (política, no slice técnico); chrome-devtools npx @1.6.0 seguir pineado.
5. **iGPU shared (nota permanente):** RX Vega 10 2GB SHARED → nada de offload VRAM/GPU en ningún slice; toda optimización GPU = no-op documentado, receipt honesto `n/a`.

---
*Fase 1 completa: plan + freeze. Ejecución (S1→S2→S3→S4) en siguientes sesiones, 1 commit por slice, receipts 011/012/013/014. S5+S6 a R11.*
