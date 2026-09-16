# Ciclo 34 — Cluster B: Go-gate + wrappers PS (sin compilar Go)

> Scope: lectura `cmd/gate/main.go`, `cmd/fast/main.go`, `cmd/sync/main.go`.
> Escritura: SOLO esta NOTA + edits menores en los 3 wrappers PS.
> PROHIBIDO: tocar `cmd/` reales, `go build`, delete/push/commit/rm.
> Método Go: hotspot `file:line` + hipótesis + estimación analítica (sin compilación).
> Método PS: medida real antes/después con `Measure-Command`.

## Baselines medidos (pwsh, 1 run, incluye startup ~150-200ms)

| Wrapper | Baseline | Dominado por |
|---|---|---|
| `scripts/delegation-fit-gate.ps1` (`-FileCount 3 -LineCount 10`) | ~211 ms | startup pwsh; cuerpo trivial |
| `scripts/validate-write-scope.ps1` (scope NOTA) | ~613 ms | 1× spawn `git diff` + startup |
| `scripts/check-token-budget.ps1 -Json` | ~524 ms | 2× `Get-ChildItem -Recurse` + 6+ pasadas `Where-Object` |

Hallazgo lateral (no tocado, fuera de scope): `check-token-budget.ps1 -Json` emite
`ADVERTENCIA: El JSON resultante se trunca porque la serialización ha superado
la profundidad establecida de 2` — `ConvertTo-Json -Compress` sin `-Depth`
trunca `stats.skills/stats.prompts`. Mismo riesgo en `validate-write-scope.ps1 -Json`
(usa `-Depth 3`, OK) y `delegation-fit-gate.ps1 -Json` (plano, OK).

## Tabla 10 experimentos

| # | Hotspot file:line | Hipótesis | Medida / estimación | Destino |
|---|---|---|---|---|
| E01 | `cmd/gate/main.go:33-41,548-564` | 9 regex globales + OR encadenado por archivo → 1 regex alternada, 1 `MatchString` | Estimación: 9 `MatchString` (~1-3 µs c/u c/regex pequeña) → 1 (~3-5 µs). Ahorro ~10-20 µs por archivo staged; en commits de 50 archivos ~0.5-1 ms. No cambia semántica si se preserva orden de alternativas | Patch en NOTA §E01 |
| E02 | `cmd/gate/main.go:33-41` (`triggerPS1`, `triggerTestsPS1`, `triggerAgentsMD`, `triggerReviewRules`, `triggerProjectJSON`) | Triggers de sufijo no necesitan regex: `strings.HasSuffix` ~20-50 ns vs `MatchString` ~1-3 µs (≈50×) | Estimación: 5 de 9 triggers son sufijo puro; fast-path `HasSuffix` antes del OR deja solo 4 regex (prefijos `scripts/lib/`, `scripts/opencode-config/`, contiene `.agents/skills/`). Ahorro ~5-10 µs/archivo | Patch en NOTA §E02 (alternativo a E01, no acumulable tal cual) |
| E03 | `cmd/gate/main.go:314-316` | `rePlusPlus`, `reHunk`, `rePlusLine` se compilan EN CADA invocación del scan de secrets (dentro del bloque, no son vars paquete) | Estimación: `MustCompile` ~10-50 µs c/u → ~30-150 µs por commit con staged≠∅. Hoist a `var` paquete = costo cero amortizado. Puesta en marcha ya paga 10 regex globales; estas 3 son puro desperdicio repetido | Patch en NOTA §E03 |
| E04 | `cmd/gate/main.go:324-326` | `fmt.Sscanf(m[1], "%d", &n)` por cada hunk del diff para parsear nº de línea — Sscanf (~1-5 µs) vs parse manual (~50-100 ns) | Estimación: diffs grandes (50+ hunks) ahorran ~50-250 µs. Además evita `fmt` solo por esto | Patch en NOTA §E04 |
| E05 | `cmd/fast/main.go:379` (`extractSkillRefs`) | `reSplitDelim.MatchString(clean)` como sonda "¿hay delimitador?" usa regex para lo que `strings.ContainsAny(clean, "·|,")` hace en ns | Estimación: 1 regex/invocación × 2 llamadas (Refs + Anti) × ~90 skills × 2 modos (crossRef y gate duplican código) → ~360 regex evitadas por corrida `fast --gate`. ~0.3-1 ms | Patch en NOTA §E05 |
| E06 | `cmd/fast/main.go:761-769` (`runGate`) | `computeCrossRefForGate` (I/O: ~90 SKILL.md + README + opencode.json) y `computeTokenBudget` (2 walks) corren secuenciales; son independientes → goroutines + `sync.WaitGroup` | Estimación: wall time gate ≈ max(crossRef, tokenBudget) en vez de suma. Si crossRef ~80 ms y token ~40 ms → ~80 ms vs ~120 ms (≈33% menos wall). Sin cambio de salida JSON | Patch en NOTA §E06 |
| E07 | `cmd/sync/main.go:246-275` (`rewriteFileRefs`) + `:379-431` (`applySecurityFloor`) | (a) Cada string pasa por `ReplaceAllStringFunc`+regex aunque 99% no contiene `{file:` → guarda `strings.Contains`. (b) `for rule := range denyRules` reitera el mapa por CADA agente (~50 agentes × N reglas) → hoist `denyKeys []string` una vez | Estimación: (a) regex→Contains: ~1 µs→~30 ns por string sin refs; en configs de ~200 strings ~0.2 ms. (b) N iteraciones mapa → slice: menor, ~10-50 µs, pero elimina aleatoriedad de orden de mapa (determinismo gratis) | Patch en NOTA §E07 |
| E08 | `scripts/delegation-fit-gate.ps1:88` | `$AgentName -match '^gentleman-quick(-sub)?(-auto)?$'` levanta motor regex por invocación para un conjunto cerrado de 4 strings → 4× `-eq` (semántica idéntica: regex anclada `^...$` con grupos opcionales = exactamente esos 4 literales; `-match` y `-eq` ambos case-insensitive por defecto) | Medida: baseline ~211 ms → post-edit ver §Validación. Ahorro esperado en cuerpo: ~0.1-0.3 ms (ruido frente a startup; valor = eliminar dependencia del motor regex en hot-path pre-delegación) | ✅ Edit directo aplicado |
| E09 | `scripts/check-token-budget.ps1:83-86,93` | (a) 4 pasadas `Where-Object` (2× `$cmdFiles`, 2× `$promptFiles`) → 2 bucles `foreach` de conteo (batch). (b) L93 `(Get-Location).Path` se evalúa POR ARCHIVO dentro del `ForEach-Object` → hoist a `$locPrefix` (cache de invariante) | Medida: baseline ~524 ms → post-edit ver §Validación. (b) es el win real: 1 llamada `Get-Location` vs N (~150 archivos md). Ahorro esperado ~5-20 ms según N | ✅ Edit directo aplicado |
| E10 | `scripts/validate-write-scope.ps1:100-106,139-161` | (a) `Convert-GlobToRegex` se llama por archivo×patrón dentro del loop → precompilar 1× fuera (regex/batch). (b) Early-exit: patrón `*` suelto matchea todo → marcar CLEAN sin loop. (c) Filtro `runtimeFiles`: 3 `-match` por archivo → 1 regex combinada | Medida: baseline ~613 ms → post-edit ver §Validación. (a) domina cuando hay muchos changed files × patrones; (b) cortocircuita el peor caso | ✅ Edit directo aplicado |

## Top-3 (mayor impacto esperado)

1. **E06 — paralelizar etapas de `runGate`**: único exp que ataca wall-time de I/O (ms, no µs).
   Resto de exps Go ahorran µs; este ahorra decenas de ms por corrida de gate.
2. **E01 — regex trigger combinada** (o E02 como alternativa): está en el path de
   CADA archivo staged en CADA commit; efecto multiplicativo por tamaño del commit.
3. **E09 — batch + hoist `Get-Location` en token-budget**: mayor win medible del lado PS
   porque elimina N-1 llamadas a cmdlet y 2 enumeraciones completas de arrays.

## Patches Go (NO aplicados — propuestos para el dueño de `cmd/`)

### §E01 — trigger combinado

```diff
 var (
 	secretsRe = regexp.MustCompile(`(REDACTED_PAT_PREFIX|...)`)
-
-	// PS-only escalation triggers (regex on staged paths, from PS gate conditions).
-	// Compiled individually to keep behavior identical to PS -match.
-	triggerPS1            = regexp.MustCompile(`\.ps1$`)
-	triggerSkillMD        = regexp.MustCompile(`\.agents/skills/[^/]+/SKILL\.md$`)
-	triggerProjectJSON    = regexp.MustCompile(`\.project\.json$`)
-	triggerReviewRules    = regexp.MustCompile(`review-rules\.jsonc$`)
-	triggerSkills         = regexp.MustCompile(`\.agents/skills/`)
-	triggerOpencodeConfig = regexp.MustCompile(`scripts/opencode-config/`)
-	triggerLibOrOpencode  = regexp.MustCompile(`^(scripts/lib/|opencode\.json$)`)
-	triggerTestsPS1       = regexp.MustCompile(`\.Tests\.ps1$`)
-	triggerAgentsMD       = regexp.MustCompile(`AGENTS\.md`)
+	// PS-only escalation triggers as ONE alternation: 1 MatchString per path
+	// instead of 9. Order preserved; each alternative identical to PS -match.
+	triggerAny = regexp.MustCompile(`\.ps1$|\.agents/skills/[^/]+/SKILL\.md$|\.project\.json$|review-rules\.jsonc$|\.agents/skills/|scripts/opencode-config/|^(scripts/lib/|opencode\.json$)|\.Tests\.ps1$|AGENTS\.md`)
 )
```

<!-- placeholder: el prefijo de PAT clásico reescrito como REDACTED_PAT_PREFIX (match=False) para el secrets-gate -->

```diff
 func classifyTriggers(staged []string) []string {
 	var triggers []string
 	for _, p := range staged {
-		if triggerPS1.MatchString(p) ||
-			triggerSkillMD.MatchString(p) ||
-			triggerProjectJSON.MatchString(p) ||
-			triggerReviewRules.MatchString(p) ||
-			triggerSkills.MatchString(p) ||
-			triggerOpencodeConfig.MatchString(p) ||
-			triggerLibOrOpencode.MatchString(p) ||
-			triggerTestsPS1.MatchString(p) ||
-			triggerAgentsMD.MatchString(p) {
+		if triggerAny.MatchString(p) {
 			triggers = append(triggers, p)
 		}
 	}
```

### §E02 — HasSuffix fast-path (alternativa a E01)

```diff
 func classifyTriggers(staged []string) []string {
 	var triggers []string
 	for _, p := range staged {
-		if triggerPS1.MatchString(p) ||
+		// Suffix triggers need no regex engine (~50x cheaper per path).
+		if strings.HasSuffix(p, ".ps1") ||
+			strings.HasSuffix(p, ".Tests.ps1") ||
+			strings.HasSuffix(p, "AGENTS.md") ||
+			strings.HasSuffix(p, ".project.json") ||
+			strings.HasSuffix(p, "review-rules.jsonc") ||
+			triggerSkills.MatchString(p) ||
+			triggerOpencodeConfig.MatchString(p) ||
+			triggerLibOrOpencode.MatchString(p) ||
+			triggerSkillMD.MatchString(p) {
-			triggerSkillMD.MatchString(p) ||
-			triggerProjectJSON.MatchString(p) ||
-			triggerReviewRules.MatchString(p) ||
-			triggerSkills.MatchString(p) ||
-			triggerOpencodeConfig.MatchString(p) ||
-			triggerLibOrOpencode.MatchString(p) ||
-			triggerTestsPS1.MatchString(p) ||
-			triggerAgentsMD.MatchString(p) {
 			triggers = append(triggers, p)
 		}
 	}
```

> Nota: `triggerTestsPS1` queda subsumido por `HasSuffix(p, ".ps1")` — se listó
> separado para explicitar que el OR original ya lo cubría; el diff neto es 5
> sufijos + 4 regex (skillMD contiene `/`, no es sufijo puro).

### §E03 — hoist hunk regexes a vars paquete

```diff
 var (
 	secretsRe = regexp.MustCompile(`(REDACTED_PAT_PREFIX|...)`)
+	// Hunk-parsing regexes were compiled per secrets-scan invocation (L314-316).
+	// Hoisted: identical patterns, zero amortized cost.
+	rePlusPlus = regexp.MustCompile(`^\+\+\+ b/(.+)$`)
+	reHunk     = regexp.MustCompile(`^@@ -\d+,\d+ \+(\d+),\d+ @@`)
+	rePlusLine = regexp.MustCompile(`^\+([^\+].*)$`)
 )
```

```diff
-		// Regexes for hunk parsing EXACTLY like PS lines 171-182
-		rePlusPlus := regexp.MustCompile(`^\+\+\+ b/(.+)$`)
-		reHunk := regexp.MustCompile(`^@@ -\d+,\d+ \+(\d+),\d+ @@`)
-		rePlusLine := regexp.MustCompile(`^\+([^\+].*)$`)
 		for _, dl := range lines {
```

### §E04 — parse de hunk header sin Sscanf

```diff
 		if m := reHunk.FindStringSubmatch(dl); m != nil {
-			// PS: [int]$Matches[1] - 1
-			var n int
-			fmt.Sscanf(m[1], "%d", &n)
+			// PS: [int]$Matches[1] - 1 — manual parse, Sscanf-free.
+			n := 0
+			for i := 0; i < len(m[1]); i++ {
+				c := m[1][i]
+				if c < '0' || c > '9' {
+					break
+				}
+				n = n*10 + int(c-'0')
+			}
 			lineInFile = n - 1
 			continue
 		}
```

> Edge: `m[1]` siempre es `\d+` por el regex `\+(\d+)`, el loop es total.
> Si el header viniera malformado, `n=0` → `lineInFile=-1`, igual que Sscanf fallido (`n=0`).

### §E05 — sonda de delimitador sin regex

```diff
 	hasBold := len(boldTokens) > 0
 	clean := reBoldClean.ReplaceAllString(raw, " ")
 	splitTokens := []string{}
-	if reSplitDelim.MatchString(clean) || !hasBold {
+	if strings.ContainsAny(clean, "·|,") || !hasBold {
 		parts := reSplitDelim.Split(clean, -1)
```

> `reSplitDelim = \s*[·|,]\s*`: si ninguno de `·|,|` está en `clean`, el split
> devolvería 1 parte sin token válido igualmente; la guarda es exacta.

### §E06 — etapas del gate en paralelo

```diff
 	// Run cross-ref internal (without printing) and token budget internal
-	// We need to capture crossRef data without duplicate print
+	// The two stages are independent (read-only scans) — run concurrently,
+	// wall time becomes max(stage) instead of sum(stage).
 	crossStart := time.Now()
-	crossRes := computeCrossRefForGate(repoRoot, crossStart)
 	tokenStart := time.Now()
-	skillVal, skillStats, promptVal, promptStats, violations, statsMap := computeTokenBudget(repoRoot)
+	var crossRes gateCrossRef
+	var skillVal SkillStats
+	var skillStats *SkillStats
+	var promptVal PromptStats
+	var promptStats *PromptStats
+	var violations []string
+	var statsMap map[string]interface{}
+	var wg sync.WaitGroup
+	wg.Add(2)
+	go func() { defer wg.Done(); crossRes = computeCrossRefForGate(repoRoot, crossStart) }()
+	go func() {
+		defer wg.Done()
+		skillVal, skillStats, promptVal, promptStats, violations, statsMap = computeTokenBudget(repoRoot)
+	}()
+	wg.Wait()
 	tokenElapsed := time.Since(tokenStart)
```

> Requiere importar `sync` en `cmd/fast/main.go` (ya importado: L12, usado por cross-ref).
> `crossStart`/`tokenStart` se toman antes del fork: `ElapsedMs` conserva semántica.
> Follow-up no incluido: `collectMdPromptFiles(prompts)` + `collectMdPromptFiles(commands)`
> (L564-565) también son paralelizables de la misma forma.

### §E07 — sync: guard Contains + denyKeys hoisted

```diff
 func rewriteFileRefs(v interface{}, chainRoot string) interface{} {
 	switch val := v.(type) {
 	case string:
+		if !strings.Contains(val, "{file:") {
+			return val // fast path: 99% of strings carry no file ref
+		}
 		return reFileRef.ReplaceAllStringFunc(val, func(match string) string {
```

```diff
+// denyKeys hoists the deny-rule map iteration: computed once, reused per agent.
+func denyKeys(denyRules map[string]interface{}) []string {
+	keys := make([]string, 0, len(denyRules))
+	for rule := range denyRules {
+		keys = append(keys, rule)
+	}
+	return keys
+}
+
 func applySecurityFloor(config map[string]interface{}, denyRules map[string]interface{}) {
+	keys := denyKeys(denyRules)
 	...
-	for rule := range denyRules {
-		bash[rule] = "deny"
+	for _, rule := range keys {
+		bash[rule] = "deny"
 	}
 	...
-		if abash != nil {
-			for rule := range denyRules {
-				abash[rule] = "deny"
-			}
+		if abash != nil {
+			for _, rule := range keys {
+				abash[rule] = "deny"
+			}
 		}
```

## Edits PS aplicados (directos, menores)

- **E08** `scripts/delegation-fit-gate.ps1:88`: `-match` regex → 4× `-eq` literales.
- **E09** `scripts/check-token-budget.ps1:83-86,93`: 4 pasadas `Where-Object` → 2 `foreach`;
  `(Get-Location).Path` hoisted a `$locPrefix` fuera del `ForEach-Object` por archivo.
- **E10** `scripts/validate-write-scope.ps1:100-106,139-161`: `runtimeFiles` 3 `-match`
  → 1 regex combinada; `Convert-GlobToRegex` precompilado 1× + early-exit `*` suelto.

## Validación

- [x] Parser PS (`System.Management.Automation.Parser`) OK en los 3 wrappers (post-edit).
- [x] Smoke: `delegation-fit-gate` PASS/FAIL/WARN idénticos antes/después (casos: quick 93 files→FAIL
  exit 2, quick 1 file→PASS exit 0, codex+security domain→WARN exit 0 con `domain-reroute`).
- [x] Smoke `validate-write-scope -Json`: VIOLATION/CLEAN correctos; early-exit `*` → 14/14 CLEAN exit 0.
- [x] Smoke `check-token-budget -Json`: `passed=True`, skills avg 2707B, prompts avg 1199B, 0 violaciones
  (conteos idénticos por construcción: mismos predicados `−gt 3072/5120`).
- [ ] Go: SIN compilar por mandato — diffs listos para review del dueño de `cmd/`.

| Wrapper | Antes | Después | Δ (1 run c/u — startup/I/O dominan, ruido ±50-80 ms) |
|---|---|---|---|
| delegation-fit-gate | ~211 ms | ~127 ms | directionally ↓, cuerpo µs |
| validate-write-scope | ~613 ms | ~567 ms | ≈ igual (domina 1× `git diff` spawn) |
| check-token-budget | ~524 ms | ~412 ms | directionally ↓ (2 enumeraciones menos + 1 `Get-Location` vs ~150) |

> Lectura honesta: los 3 wrappers están dominados por startup pwsh (~150-200 ms) y
> syscalls (git spawn, `Get-ChildItem -Recurse`); los ahorros de cuerpo son µs–pocos ms
> y quedan dentro del ruido single-run. NO hay regresión y la semántica es idéntica
> (predicados y verdicts preservados 1:1). El valor real está en los diffs Go (E01-E07),
> donde E06 ataca wall-time de I/O (decenas de ms).
