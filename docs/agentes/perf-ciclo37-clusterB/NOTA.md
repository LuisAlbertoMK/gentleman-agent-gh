# Ciclo 37 — Cluster B: 10 exps finales (Go top-3 dif-listos + dieta skills + verificación global)

Fecha: 2026-09-15. Env: pwsh 7.6.6 Win32NT. Método: consolidar (no re-experimentar).
Go: SOLO lectura + diffs pulidos en esta NOTA — `cmd/` intacto, `go build` PROHIBIDO
(toolchain bloqueado). Skills: dieta AR externa aplicada real (gate ≤3072B + parse OK
en ambas). Script: E1-C36C frontmatter-lazy aplicado. PROHIBIDO
delete/push/commit/rm/opencode.json: cumplido. Worktree venía sucio de otros clusters
(opencode.json, check-token-budget.ps1, etc. ya M antes de este task) — no tocado;
hunks propios sin marca (archivos distintos a cluster A, 0 solape).

SkillOpt: dietas verificadas en shadow TEMP (`c37-clusterB/PT-shadow*.md`,
`EP-shadow*.md`) ANTES de aplicar real. Shadow1 (puntero largo): PT 2916 PASS,
EP 3105 FAIL (+33B) → se acortó puntero (misma dieta, estilo conciso) → shadow2:
PT 2863 + EP 3052 PASS → aplicadas reales: PT 2820B, EP 2998B.

## Tabla 10 (estado previo → acción → medida → veredicto)

| # | Exp | Estado previo | Acción | Medida | Veredicto |
|---|-----|---------------|--------|--------|-----------|
| B1 | sem-spike (Go) | `cmd/sync/main.go:873-878`: `wg.Add` + `go func` ANTES de `sem <- struct{}{}` — spike: N goroutines (stack+closure c/u) vivas y bloqueadas en el semáforo | Diff pulido §B1: adquirir `sem` en el loop ANTES de spawnear (backpressure; vivos ≤ parallel) | Estática: N vivos → ≤4 vivos; 0 compiles (prohibido); sin runtime (toolchain) | DIF LISTO, no aplicado |
| B5 | pool-94 (Go) | `cmd/sync/main.go:898`: `json.Marshal(chain)` por proyecto DENTRO de cada goroutine — N marshals del mismo payload | Diff pulido §B5: hoist marshal 1x fuera del fan-out; cada proyecto solo `Unmarshal` su copia (mutación lo exige) | Estática: N marshals → 1 (payload C: N·C → C bytes marshal); Unmarshal se mantiene | DIF LISTO, no aplicado |
| B2 | clone-chain (Go) | `cmd/fast/main.go`: `runCrossRef` L191-342 (152) vs `computeCrossRefForGate` L861-1015 (155) — ~130 líneas de scan duplicadas (índice skills, parse opencode.json, check README, fan-out por skill) | Patch §B2: 3 helpers puros (`loadSkillIndex`, `loadAgentIndex`, `checkSkillRefs`); loops fan-out se quedan (plumbing idéntico, riesgo bajo) | Estática: ~130 LOC dup → ~60 LOC helper + 2 call-sites de 3 líneas (~-55 LOC netos) | DIF LISTO, no aplicado |
| S1 | dieta PT AR | `performance-tracker/SKILL.md` 3367B (>3200 budget, over por 167B); tabla Anti-Rationalization 3x3 inline (658B) | AR → 1 puntero a `docs/skills/performance-tracker/reference.md` (tabla verbátim en §propuesta) | 3367 → 2820B (-547B, -16.2%); gate ≤3072 PASS; frontmatter 4/4; Refs intacto | APLICADA |
| S2 | dieta EP AR | `engram-protocol/SKILL.md` 3280B (>3200 budget, over por 80B); tabla Anti-Rationalization 3x3 inline (388B) | AR → 1 puntero a `docs/skills/engram-protocol/reference.md` (tabla verbátim en §propuesta) | 3280 → 2998B (-282B, -8.6%); gate ≤3072 PASS; frontmatter 4/4; Refs intacto | APLICADA |
| E1 | frontmatter-lazy E1-C36C | `scripts/build-skill-registry.ps1` `Get-Frontmatter` parseaba tags+dependencies SIEMPRE (4 regex) aunque el registry compacto los dropea (L119-132, solo name/triggers/path) | Param `-Fields` default `@('name','triggers')`; bloques tags/dependencies tras guard `if ($Fields -contains ...)`; call-site sin cambios (0 riesgo); único caller interno (grep: solo L22 def + L101 call) | Parse errs=0; rebuild a TEMP: 95 skills / 639 triggers OK (igual forma que antes); trabajo muerto: 2 regex × 95 skills eliminados por rebuild | APLICADA (4946 → 5496B: +550B comentarios, sin gate en scripts — el win es runtime, no bytes) |
| V1 | parse global | 3 archivos tocados | `[Parser]::ParseFile` ps1 + frontmatter 4 campos × 2 skills | errs=0; fm=True 4/4 en ambas | PASS |
| V2 | cross-ref global | `scripts/cross-ref-check.ps1` (solo lectura, ejecutado) | 9 checks post-dieta (AR removida no contenía `**skill**` — 0 refs afectadas) | 9/9 OK — ALL CHECKS PASSED (agents 48 match) | PASS |
| V3 | token-budget global | `scripts/check-token-budget.ps1 -Json` (solo lectura, ejecutado) | skills avg + over-budget count antes/después | passed=true; avg 2698/3200; over 5 → 3 (salen PT+EP; quedan context-watchdog 3266, delivery-harness 3708, judgment-day 4126 — fuera de scope) | PASS |
| V4 | scope + cierre | `git status --short` filtrado | Solo `M` en los 3 permitidos; `?? perf-ciclo37-clusterB/` = esta NOTA (nuevo permitido); opencode.json/cmd/ sin toques propios; sin commit/push/rm/build | 3/3 scope OK; 0 violaciones | PASS |

Reverts: 0/10. Go: 3/3 dif-listo sin aplicar (mandato). Skills: 2/2 aplicadas reales
(gate+parse). Script: 1/1 aplicado. Verificación: 4/4 PASS.

## Top-3 Go final (aplicar post-toolchain, en orden B1 → B5 → B2)

### B1 sem-spike — `cmd/sync/main.go` hunk L873-878
```diff
 	for i, proj := range manifest.Projects {
+		sem <- struct{}{} // B1: adquirir ANTES de spawnear — backpressure, vivos <= parallel
 		wg.Add(1)
 		go func(idx int, p manifestProject) {
 			defer wg.Done()
-			sem <- struct{}{}
 			defer func() { <-sem }()
```
Edge: loop bloquea cuando pool lleno (intencional); `parallel` ya clamped a
`[1, NumCPU]` (L809-814); sin cambio semántico en error-paths (cada goroutine
libera vía defer igual que antes). Orden: aplicar 1º (hunk aislado, 0 solape con B5).

### B5 pool-94 — `cmd/sync/main.go` hunk L855-863 + L897-900
```diff
 	// Pre-generate chain config once (shared read-only)
 	chain, err := getChainConfig(chainRoot)
 	...
+	// B5: 1 marshal fuera del fan-out; cada proyecto deserializa su copia
+	// (el Unmarshal por copia se mantiene: cada goroutine muta la suya).
+	chainBytes, _ := json.Marshal(chain)
 ...
 		go func(idx int, p manifestProject) {
 ...
-			// Deep-clone chain for this project
-			chainBytes, _ := json.Marshal(chain)
 			var projConfig map[string]interface{}
 			json.Unmarshal(chainBytes, &projConfig)
```
Edge: `chainBytes` solo-lectura compartida (sin race: `json.Unmarshal` no muta
origen); `chain` ya era compartida read-only. Follow-up opcional (no incluido):
`sync.Pool` de `bytes.Buffer` + `json.Encoder` si el payload supera ~1MB
(medida post-toolchain con `go test -bench`). Orden: aplicar 2º (adyacente a B1,
hunks distintos, aplica limpio tras B1).

### B2 clone-chain — `cmd/fast/main.go` (helpers nuevos + 2 call-sites)
Anclas: índice skills `runCrossRef` L219-234 ≡ `computeCrossRefForGate` L886-900;
parse opencode.json L236-257 ≡ L902-923; check README L259-268 ≡ L924-933;
cuerpo por-skill L299-327 ≡ L963-991. Helpers a añadir (puros, sin estado global):
`loadSkillIndex(repoRoot) (names, dirs []string, origMap map[string]string,
set map[string]bool)` · `loadAgentIndex(repoRoot) (ocAgents, ocAgentsAll []string,
warnings []string)` · `checkSkillRefs(dir, display string, set map[string]bool,
repoRoot string) (broken, missing []string)` (extrae el cuerpo L299-320 /
L963-985 incl. `extractSkillRefs`+`extractConfigRefs`, que NO se duplican — ya son
helpers compartidos). Call-sites: cada función conserva su fan-out
(`mu`/`wg`/acumuladores difieren en tipo de retorno) pero reemplaza ~45 líneas de
setup por 3 llamadas. Verificación post-toolchain: `go vet ./cmd/fast` +
`fast.exe --gate --json` igual salida que pre-patch (golden). Orden: aplicar 3º
(archivo distinto a B1/B5, 0 solape; el más grande — revisar con `git diff --stat`).

## Dieta aplicada KB

- performance-tracker: 3367 → 2820B (-547, -16.2%) — bajo budget 3200 (era over).
- engram-protocol: 3280 → 2998B (-282, -8.6%) — bajo budget 3200 (era over).
- Skills over-budget en repo: 5 → 3. Puntero uniforme:
  `## Anti-Rationalization → docs/skills/<skill>/reference.md (tabla 3x3 en NOTA ciclo37-clusterB)`.
- `build-skill-registry.ps1`: 4946 → 5496B (+550 comentarios E1-C36C; sin gate en
  scripts — win = -2 regex × 95 skills por rebuild; salida compacta idéntica:
  name/triggers/path + trigger_index).

## §propuesta (tablas verbátim para futuro append a reference.md — NO tocadas: resto solo lectura)

performance-tracker → `docs/skills/performance-tracker/reference.md` (nueva
sección `## Anti-Rationalization`, 658B):

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "score sin 6 dims" | Score sin 6 dims o dimensión adivinada | Verificar Hard Rules: Score EVERY dimension medición real + neutral 7 si unavailable + thresholds file:line |
| "trend sin historial" | Trend sin N≥5 historial | Verificar Score Storage: mem_save perf-score:{app}-{platform} + mem_search prev5 vs recent5 + Trend cada 10 |
| "mix plataformas o single run" | Trend mezclando plataformas o single lighthouse | Verificar NEVER mix platforms + median-of-3 lighthouse + regression >0.5→gap-analysis + never crash no process |

engram-protocol → `docs/skills/engram-protocol/reference.md` (nueva sección
`## Anti-Rationalization`, 388B):

| Rationalization | Red Flag | Check |
|-----------------|----------|-------|
| "Skill without verification" | Work w/o output check | Match ## Output contract + file:line |
| "Skip this skill to save time" | Direct use w/o deps | skill-graph + cross-ref check |
| "Output is self-evident" | No file:line/confidence | Cite file:line or `confidence: unvalidated` |

## Plan aplicación post-toolchain

1. Toolchain Go disponible → aplicar B1, `gofmt -l cmd/sync` + `go vet ./cmd/sync`.
2. Aplicar B5 → `go test ./...` (existe `scripts/gentle-batch-edit_test.go`; cmd sin
   tests propios — smoke: `sync update-all --manifest <test> --dry-run --json`).
3. Aplicar B2 → `go vet ./cmd/fast` + golden `fast.exe --gate --json` pre/post.
4. Append §propuesta a los 2 reference.md (docs, bajo riesgo) + re-run cross-ref +
   token-budget.
5. Candidatos over-budget restantes (context-watchdog, delivery-harness,
   judgment-day) → próximo ciclo (fuera de scope: no estaban permitidos).

## Verificación (repro)

- Parse: `[Parser]::ParseFile` build-skill-registry.ps1 errs=0; frontmatter 4/4 ×2.
- Rebuild: `build-skill-registry.ps1 -OutputFile TEMP\registry-test.json` →
  95 skills, 639 triggers (salida a TEMP, repo intacto).
- `cross-ref-check.ps1` → 9/9 OK ALL CHECKS PASSED. `check-token-budget.ps1 -Json`
  → passed=true, skills avg 2698, over 3.
- Rollback: `git diff` en los 3 archivos (skills: 1 hunk c/u; ps1: 3 hunks
  `E1-C36C`) — revert por hunk, 0 dependencias cruzadas; Go: nada que revertir
  (no aplicado). Shadows y registry-test en `TEMP\opencode\c37-clusterB\`.
