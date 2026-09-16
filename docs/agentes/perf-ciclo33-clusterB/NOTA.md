# Perf Ciclo 33 — Cluster B: 10 micro-experimentos (ANÁLISIS ESTÁTICO, sin compilar)

> Toolchain Go 1.26.5 corrupto (stdlib `unicode` roto). PROHIBIDO `go build`.
> Todo lo medible sin compilar se midió; el resto es estimación estática + patch listo para aplicar cuando se repare Go.

## Baseline entorno (medido)

| Medición | Resultado |
|---|---|
| `go version` | `go1.26.5 windows/amd64` ✅ (binario responde) |
| `Measure-Command { go version }` | **~180 ms** (startup entorno; incluye spawn pwsh) |
| `gofmt -l cmd/sync/main.go cmd/fast/main.go cmd/gate/main.go` | **3/3 UNFORMATTED** (los 3 listados → formateo pendiente, confirma edición manual sin gofmt) |
| `go vet ./cmd/sync/` | **FALLA por stdlib corrupta**: `# unicode / graphic.go:24:2: undefined: L, M, N, P…` → anotado, se sigue sin compilar (NEVER STOP) |
| `json.Marshal/Unmarshal` (conteo lectura) | sync **18**, fast **7**, gate **8** = **33** sitios |
| `go func` (conteo lectura) | sync L875 (update-all) + fast L284 (runCrossRef) + fast L948 (computeCrossRefForGate) = **3** sitios spawn |
| `regexp.MustCompile|MatchString` (conteo lectura) | **43** ocurrencias totales cmd/ |

## Tabla 10 experimentos

| # | Hotspot file:line | Hipótesis | Ganancia estimada | Riesgo | Veredicto |
|---|---|---|---|---|---|
| B1 | `cmd/sync/main.go:873-878` sem adquirido DENTRO del goroutine | `wg.Add + go func` dispara N goroutines a la vez; el `sem <-` bloquea dentro, no limita spawn → spike memoria/threads con manifest grande | CPU: elimina N−4 goroutines estacionadas; RAM: −(N−4)×stack 8KB (~750KB @100 proy.); startup: igual | BAJO (reordenar 2 líneas) | ✅ APLICAR (top-3) |
| B2 | `cmd/sync/main.go:897-900` `chainBytes Marshal+Unmarshal` por proyecto | Clone JSON completo por proyecto (~opencode.json 90KB + agentes; research cita +30MB con chain grande) × N proyectos = O(N×chain) allocs + GC pressure | CPU: −1 Marshal + 1 Unmarshal por proyecto (~−2×90KB ser/de×N); RAM: −pico chain×N concurrente (4 workers → −270KB pico); GC: menos scans | BAJO si clone es shallow (permiso plano) — MEDIO si hay mutación anidada profunda | ✅ APLICAR (top-3): marshal 1 vez + `bytes.Clone` + unmarshal por worker, o shallow-copy |
| B3 | `cmd/sync/main.go:323-326` clone template por agente en `getChainConfig` | Mismo patrón que B2 pero por agente (Marshal/Unmarshal del template `readwrite` que es plano string→string) → round-trip JSON innecesario | CPU: −2×(nAgentes) ser/de (~10 agentes × ~2KB = −40KB ser/de); RAM marginal; código más simple | BAJO (template es `map[string]string`-like; shallow copy semánticamente igual) | ✅ APLICAR |
| B4 | `cmd/sync/main.go:735-736` `existingBytes/newBytes` doble Marshal para comparar | Serializar 2× config entera (~90KB×2) solo para `bytes.Equal` → cuesta 180KB ser/de por `update` aunque no haya cambios | CPU: −~180KB JSON encode por update; RAM: −180KB pico | BAJO (DeepEqual o comparar hash; riesgo: orden de claves map — Marshal ordena, DeepEqual no → usar hash del Marshal existente 1 vez o `reflect.DeepEqual`) | ⚠️ APLICAR con hash (ver patch) |
| B5 | `cmd/fast/main.go:282-329` + `:946-993` 1 goroutine por skill (~94) + `sync.Mutex` por append | 94 goroutines para leer 94 SKILL.md pequeños (I/O-bound, archivos ~3KB) → overhead spawn + contención mutex + `os.Stat` por ref dentro del loop | CPU: worker-pool NumCPU(×4-8) −90 spawns; RAM: −90 stacks (~720KB); wall: igual o mejor (I/O local) | BAJO (cambiar a pool + canal resultados sin mutex) | ✅ APLICAR (top-3) |
| B6 | `cmd/fast/main.go:369-390` 4 regex por archivo en `extractSkillRefs` | `reBoldToken.FindAll + reBoldClean.ReplaceAll + reSplitDelim.Match/Split + reStrictSkill.Match` × ~94 archivos; la mayoría de headers no tienen `**` → regex corre igual | CPU: pre-filtro `strings.Contains(raw,"**")` evita ~70-90% regex; −~300 invocaciones regex por run | BAJO (fallback a regex si hay `**`; strings es exacta) | ✅ APLICAR |
| B7 | `cmd/fast/main.go:260-265` + `:924-930` `strings.Contains(readmeLower, ag)` por agente | O(A×R): escanea README entero (~10-50KB) una vez POR agente (~20-90) = hasta ~4.5MB escaneados por run | CPU: tokenizar README a `map[string]bool` 1 vez → O(R+A); −~90% scans | BAJO (tokenización por campos; riesgo: match substring vs palabra — README usa nombres exactos, aceptable) | ⚠️ APLICAR (validar que no hay falsos substring) |
| B8 | `cmd/gate/main.go:314-316` 3 `regexp.MustCompile` DENTRO de `runHook` (por invocación) | `rePlusPlus/reHunk/rePlusLine` se recompilan en CADA `gate --hook` (cada commit) → startup +~0.5-2ms + allocs evitables | Startup: −~1ms por hook; CPU marginal pero gratis | MÍNIMO (mover a `var` global; regex literales fijos) | ✅ APLICAR |
| B9 | `cmd/gate/main.go:33-41` 9 `trigger*.MatchString` por staged path | 9 regex evaluados por path (9×P); 7 de 9 son sufijos literales (`\.ps1$`, `AGENTS\.md`, etc.) → regex overkill en hot-path pre-commit | CPU: −~80% costo clasificación (HasSuffix ≈ 5ns vs regex ≈ 200ns ×9); startup: −9 MustCompile (~−2ms) | BAJO (tabla sufijo+contains preserva semántica; riesgo: `triggerSkills` es substring — se conserva con Contains) | ✅ APLICAR |
| B10 | `cmd/fast/main.go:517-529,665-683` `d.Info()` + fallback `os.Stat` + 3 `WalkDir` secuenciales | Doble syscall por archivo + walks de skills/prompts/commands secuenciales (3× tree walk) aunque son directorios disjuntos | CPU/I-O: −~50% syscalls stat; wall: walks paralelos o single-walk −~30% latencia token-budget | BAJO (usar solo `d.Info()`, ignorar error; walks paralelos con WaitGroup ya disponible) | ⚠️ APLICAR (solo `d.Info`, diferir paralelización) |

## Top-3 priorizados (Impact/Risk)

1. **B1 — sem/worker-pool en `sync update-all`** (Impacto ALTO / Riesgo BAJO): elimina el spike de N goroutines; es el único con riesgo de OOM real con manifests grandes.
2. **B5 — worker-pool en `fast cross-ref`** (Impacto ALTO / Riesgo BAJO): 94 goroutines + mutex → pool acotado; reduce varianza de latencia del gate (fast-gate corre en CADA commit vía `gate`).
3. **B2 — clone chain 1 vez** (Impacto ALTO / Riesgo BAJO-MEDIO): el mayor consumidor de RAM/CPU medido por lectura (Marshal×N); prerequisito para manifests >20 proyectos.

## Patches propuestos (dif unificado, NO aplicados — toolchain corrupto)

### B1 — sync sem antes del spawn (worker-pool real)
```diff
--- a/cmd/sync/main.go
+++ b/cmd/sync/main.go
@@ -871,11 +871,17 @@
 	for i, proj := range manifest.Projects {
+		sem <- struct{}{} // adquirir ANTES de spawnear: acota goroutines vivas a `parallel`
 		wg.Add(1)
 		go func(idx int, p manifestProject) {
 			defer wg.Done()
-			sem <- struct{}{}
 			defer func() { <-sem }()
```
*Alternativa pool explícito (4 workers + job chan) si se quiere cero spawn por proyecto — veredicto: reordenar basta.*

### B2 — marshal chain una vez + clone bytes por worker
```diff
--- a/cmd/sync/main.go
+++ b/cmd/sync/main.go
@@ -856,6 +856,9 @@
 	chain, err := getChainConfig(chainRoot)
+	// B2: serializar UNA vez; cada worker clona bytes (sin re-marshal del map).
+	chainJSON, _ := json.Marshal(chain)
@@ -897,8 +900,9 @@
-			// Deep-clone chain for this project
-			chainBytes, _ := json.Marshal(chain)
+			// Deep-clone chain for this project (reúsa serialización única)
+			chainBytes := bytes.Clone(chainJSON)
 			var projConfig map[string]interface{}
 			json.Unmarshal(chainBytes, &projConfig)
```
*Requiere `bytes` import. Ganancia: N−1 Marshals eliminados.*

### B3 — shallow-copy template (sin JSON round-trip)
```diff
--- a/cmd/sync/main.go
+++ b/cmd/sync/main.go
@@ -323,9 +323,12 @@
-		// Deep-clone the template
-		tplBytes, _ := json.Marshal(tplRaw)
-		var tpl map[string]interface{}
-		json.Unmarshal(tplBytes, &tpl)
+		// Shallow-copy: el template es plano string->string; el round-trip JSON es puro overhead.
+		tplSrc, _ := tplRaw.(map[string]interface{})
+		tpl := make(map[string]interface{}, len(tplSrc))
+		for k, v := range tplSrc {
+			tpl[k] = v
+		}
```

### B4 — comparar sin doble Marshal (hash único)
```diff
--- a/cmd/sync/main.go
+++ b/cmd/sync/main.go
@@ -735,9 +735,11 @@
-		existingBytes, _ := json.Marshal(existing)
-		newBytes, _ := json.Marshal(chain)
-		if bytes.Equal(existingBytes, newBytes) {
+		// B4: un solo Marshal del nuevo + hash; evita serializar el existente entero.
+		newBytes, _ := json.Marshal(chain)
+		existingBytes, _ := json.Marshal(existing)
+		// TODO(toolchain-ok): reemplazar por sha256(newBytes) vs cache en disco para 0 Marshals en no-change.
+		if bytes.Equal(existingBytes, newBytes) {
```
*Nota: el dif mínimo no ahorra hasta cachear hash; el ahorro real (0 ser/de en no-change) requiere guardar `.opencode.hash` — fase 2.*

### B5 — fast cross-ref worker-pool sin mutex
```diff
--- a/cmd/fast/main.go
+++ b/cmd/fast/main.go
@@ -273,7 +273,12 @@
-	var mu sync.Mutex
 	var wg sync.WaitGroup
+	workerN := runtime.NumCPU()
+	if workerN < 4 {
+		workerN = 4
+	}
+	jobs := make(chan int, len(skillDirs))
+	// resultados por índice: sin mutex (cada worker escribe su slot)
+	type res struct{ broken, missing []string }
+	results := make([]res, len(skillDirs))
```
*(Aplicar mismo patrón en `computeCrossRefForGate` L937-993. Requiere `runtime` import — ya existe `sync`; agregar canal.)*

### B6 — pre-filtro `**` antes de regex
```diff
--- a/cmd/fast/main.go
+++ b/cmd/fast/main.go
@@ -369,7 +369,11 @@
-	boldMatches := reBoldToken.FindAllStringSubmatch(raw, -1)
+	// B6: la mayoría de headers no tienen negritas → evita 4 regex por archivo.
+	var boldMatches [][]string
+	if strings.Contains(raw, "**") {
+		boldMatches = reBoldToken.FindAllStringSubmatch(raw, -1)
+	}
```
*(Extender: si `!strings.ContainsAny(raw, "·|,") && !hasBold` saltar `reSplitDelim.Split`.)*

### B7 — README a set una vez
```diff
--- a/cmd/fast/main.go
+++ b/cmd/fast/main.go
@@ -260,9 +260,13 @@
-		readmeLower := strings.ToLower(string(data))
-		for _, ag := range ocAgents {
-			if !strings.Contains(readmeLower, ag) {
+		readmeLower := strings.ToLower(string(data))
+		// B7: single-pass — tokeniza README a set, luego O(1) por agente.
+		readmeSet := make(map[string]bool, len(ocAgents)*2)
+		for _, tok := range strings.FieldsFunc(readmeLower, func(r rune) bool {
+			return r < 'a' || r > 'z' && r < '0' || r > '9' && r != '-' && r != '_'
+		}) {
+			readmeSet[tok] = true
+		}
+		for _, ag := range ocAgents {
+			if !readmeSet[ag] {
```

### B8 — gate regex a globales
```diff
--- a/cmd/gate/main.go
+++ b/cmd/gate/main.go
@@ -33,6 +33,11 @@
 	triggerAgentsMD       = regexp.MustCompile(`AGENTS\.md`)
+	// B8: antes compiladas POR invocación dentro de runHook — mover a global.
+	rePlusPlus = regexp.MustCompile(`^\+\+\+ b/(.+)$`)
+	reHunk     = regexp.MustCompile(`^@@ -\d+,\d+ \+(\d+),\d+ @@`)
+	rePlusLine = regexp.MustCompile(`^\+([^\+].*)$`)
@@ -314,9 +319,6 @@
-		rePlusPlus := regexp.MustCompile(`^\+\+\+ b/(.+)$`)
-		reHunk := regexp.MustCompile(`^@@ -\d+,\d+ \+(\d+),\d+ @@`)
-		rePlusLine := regexp.MustCompile(`^\+([^\+].*)$`)
```

### B9 — triggers por sufijo (sin regex)
```diff
--- a/cmd/gate/main.go
+++ b/cmd/gate/main.go
@@ -548,19 +548,20 @@
 func classifyTriggers(staged []string) []string {
 	var triggers []string
 	for _, p := range staged {
-		if triggerPS1.MatchString(p) ||
-			triggerSkillMD.MatchString(p) ||
+		// B9: 7/9 son sufijos literales → HasSuffix (~5ns) en vez de regex (~200ns c/u).
+		if strings.HasSuffix(p, ".ps1") ||
+			strings.HasSuffix(p, ".agents/skills/x/SKILL.md") ||
+			strings.HasSuffix(p, ".project.json") ||
+			strings.HasSuffix(p, "review-rules.jsonc") ||
+			strings.Contains(p, ".agents/skills/") ||
+			strings.Contains(p, "scripts/opencode-config/") ||
+			strings.HasPrefix(p, "scripts/lib/") || p == "opencode.json" ||
+			strings.HasSuffix(p, ".Tests.ps1") ||
+			strings.Contains(p, "AGENTS.md") {
-			triggerTestsPS1.MatchString(p) ||
-			triggerAgentsMD.MatchString(p) {
 			triggers = append(triggers, p)
 		}
 	}
```
*Afinar `triggerSkillMD` (regex original `\.agents/skills/[^/]+/SKILL\.md$`): el HasSuffix genérico arriba es aproximado — validar con test de tabla antes de aplicar.*

### B10 — un solo `d.Info()`, sin fallback Stat
```diff
--- a/cmd/fast/main.go
+++ b/cmd/fast/main.go
@@ -522,9 +522,7 @@
 			if !d.IsDir() && strings.EqualFold(filepath.Base(path), "SKILL.md") {
-				if info, err := d.Info(); err == nil {
+				if info, err := d.Info(); err == nil { // B10: d.Info() basta; el fallback os.Stat duplica syscall
 					skillSizes = append(skillSizes, info.Size())
-				} else if info2, err2 := os.Stat(path); err2 == nil {
-					skillSizes = append(skillSizes, info2.Size())
 				}
 			}
```
*(Mismo cambio en `collectMdPromptFiles` L674-678.)*

## Estimación CPU/RAM/startup global (estática, sin bench)

| Eje | Antes (estimado) | Después (10 patches) | Δ |
|---|---|---|---|
| `sync update-all` RAM pico (100 proy.) | chain×4 workers + N goroutine stacks + N×chainBytes clones (~30MB research) | chain×1 + 4 stacks + 4 clones | **−60-80% pico** |
| `fast cross-ref` goroutines | ~94 + mutex | ≤8 workers, sin mutex | **−90% goroutines, −~720KB stacks** |
| Regex invocaciones por `gate --hook` típico | ~9×P + 3 compile + secrets scan | ~2×P HasSuffix + 0 compile | **−~70% CPU clasificación, −~3ms startup** |
| Startup binarios (regex globales) | ~20 MustCompile totales | ~8 (resto lazy) | **−~2-5ms** (marginal pero gratis) |
| `gofmt` | 3/3 unformatted | pendiente `gofmt -w` cuando toolchain ok | — |

## Riesgos transversales

- Toolchain corrupto impide `go build/vet/test` → **ningún patch verificado por compilación**; todos quedan como propuesta en esta NOTA.
- B4/B9 cambian semántica sutil (orden claves / match aproximado) → requieren test de tabla post-reparación.
- `gofmt -l` marca los 3 archivos → aplicar `gofmt -w` junto con los patches para no mezclar formato+perf en un dif.

## Archivos leídos (solo lectura, sin edición)

- `cmd/sync/main.go` (1085L), `cmd/fast/main.go` (1015L), `cmd/gate/main.go` (644L), `go.mod`
