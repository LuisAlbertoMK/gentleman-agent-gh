# Plan: Auto-Mejora Autónoma v3 — 2026-08-13

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Base**: `main` HEAD `0d88467c`
**Branch propuesta**: `experimento/mejora-autonoma-2026-08-13`
**Presupuesto**: 3 ciclos max · 15 min/ciclo · $0 (free-tier models only)
**Escalado**: correctness > security > performance > size

**Escala ICE** (aclarada, no estaba definida): Impacto 1-10, Confianza 1-10, Esfuerzo 1-10 **inverso** (10 = mínimo esfuerzo). Prioridad = I×C×E.

### Baseline estadístico (§0.7) — 5-10 runs con mediana/IQR
**IMPORTANT**: `benchmark-baseline.json` contiene un solo valor (`BenchmarkSeconds: 0.763`). Protocolo v3 §0.7 exige mínimo 5-10 runs comparando mediana/IQR, no un número único.

**Método**: Antes de Ciclo 1, ejecutar en branch efímero:
```powershell
$samples = 1..10 | ForEach-Object {
  (Measure-Command { & 'scripts/sync-vmk.ps1' -DryRun -Json > $null }).TotalMilliseconds
} | Sort-Object

$count  = $samples.Count
$median = if ($count % 2 -eq 0) {
  ($samples[$count/2 - 1] + $samples[$count/2]) / 2
} else {
  $samples[[math]::Floor($count/2)]
}
$q1 = $samples[[math]::Floor($count * 0.25)]
$q3 = $samples[[math]::Floor($count * 0.75)]
$iqr = $q3 - $q1

[PSCustomObject]@{ Count=$count; Median=$median; Q1=$q1; Q3=$q3; IQR=$iqr } |
  ConvertTo-Json | Set-Content benchmark-baseline.json
```
Guardar `benchmark-baseline.json` actualizado con `mediana` + `IQR` + `count=10`. El plan solo procede con baseline estadístico real (no `Average/Min/Max`, que no equivalen a mediana/IQR).

### Entorno aislado (§0.9)
Todo ciclo corre en **GitHub Actions workflow efímero** (`.github/workflows/ci.yml` — Ciclo 3), runner `ubuntu-latest`, con `shell: pwsh` explícito en cada step (PowerShell Core, no Windows PowerShell) + branch `experimento/mejora-autonoma-2026-08-13`. **Nunca** contra infraestructura compartida. Tests Pester corren en job ephemeral sin persistencia. El agente auditor (`gentleman-deep-sub-auto`) solo revisa archivos, NO muta estado.

**Nota de portabilidad**: todo path usado en validaciones (ver Ciclo 3) debe ser relativo al workspace del runner — nada de rutas absolutas de Windows (`D:\...`), que no existen en `ubuntu-latest`.

### Estado Pester baseline (§3.5)
- **Baseline actual (main)**: 669 pass / **7 fail** (en `destructive-scripts.Tests.ps1`)
- **Root cause**: `clean-repo.ps1` (4 failures) + `engram-compact.ps1` (3 failures) — pre-existing bugs documentados en `mejora-log.md:18-21`
- **DoD target**: 0 NEW failures (no regression). Los 7 pre-existing failures están **documentados pero fuera de scope** para este ciclo (Blast Radius Alto, requeriría checkpoint humano separado).
- **DoD**: Si los 7 failures persisten → no es regression (confirmado vía `git diff` de test files)

---

## 0. Evidencia de Gaps

### G1: PowerShell `ConvertTo-Json` single-element array unwrapping
- **Fuente**: `sync-vmk.ps1:157` (L157: `$target | ConvertTo-Json -Depth 10 | Set-Content`), `use-gentleman.ps1:106` (`Get-DeepClone` usaba `ConvertTo-Json|ConvertFrom-Json`)
- **Evidencia**: Git churn — 30 commits en estos 2 archivos desde 2026-07. ADR-003 documenta el array unwrapping pero SOLO para `function returns` (usando `@(...)`), NO para `ConvertTo-Json` serialización
- **Bug demo**: `skills.paths: [".agents/skills"]` → `"paths": ".agents/skills"` (string) — causó el error original en el repo de destino
- **Blast Radius**: **Bajo** (scripts internos, API estable)
- **ICE**: 9×9×8 = 648

### G2: No CI quality gate valida config antes de deploy
- **Fuente**: No `.github/workflows/` existe. `benchmark-baseline.json` fue creado manualmente. Ningún test valida que `skills.paths` sea array
- **Evidencia**: 16 test files en `scripts/tests/` pero ninguno valida `opencode.json` schema. ADR-026 menciona "gate 18/18" pero no config validation
- **Blast Radius**: **Medio** (nueva CI pipeline, no rompe contratos existentes)
- **ICE**: 8×7×6 = 336

### G3: `sync-vmk.ps1` no incluye `gentle-orchestrator` + `sdd-*` agents
- **Fuente**: `sync-vmk.ps1:54` syncs `gentleman-*` only. `gentle-orchestrator` referenced by `rules.routing.delegate_to_agent` + `commands/sdd-*.md` (`agent: gentle-orchestrator`) pero no estaba en configs
- **Evidencia**: Global config tenía 39 agents (0 sdd-*, 0 gentle-orchestrator) vs repo config 50. 10 sdd-* agents + 1 gentle-orchestrator missing
- **Blast Radius**: **Alto** (contrato de routing afecta todos los SDD commands) ⚠️ **Checkpoint humano OBLIGATORIO — pendiente, ver §4**
- **ICE**: 9×9×7 = 567

---

## 1. Ciclo 1 — G1: PowerShell ConvertTo-Json array unwrapping

### Scope Lock
```
IN:  scripts/lib/json-utils.ps1 (nuevo)
     scripts/use-gentleman.ps1 (import + replace Get-DeepClone)
     scripts/sync-vmk.ps1 (import + replace inline fix)
     scripts/tests/json-utils.Tests.ps1 (nuevo)
OUT: todo lo demás (ADR mini si necesario)
```

### 3 Enfoques

| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (Minimal) | Extract `Get-DeepClone` (PSSerializer) + `ConvertTo-JsonSafe` (regex `[regex]::Replace` para `paths`) a `json-utils.ps1`. Import en ambos scripts | +15 líneas, bajo riesgo, testeable aislado | Solo fixa `skills.paths`, no generaliza |
| **B** (Module) | `JsonConfig.psm1` clase `[JsonConfig]` con `.Clone()`, `.ToJson()`, `.Validate()`. Grep-all `ConvertTo-Json` instances, reemplazar | Full codebase consistency | +200 líneas, mayor surface area |
| **C** (Defensive) | `json-utils.ps1` + `ConvertFrom-JsonStrict` con type assertions post-deserialize (valida arrays son arrays) | Máxima prevención, fail-fast | Overhead de validación en cada load |

### Ganador esperado
**A** — por metric hierarchy: correctness (Bajo). G2 y G3 lo consumirán como dependencia.
*(Confirmar tras benchmark real del ciclo — "esperado" no es "decidido".)*

### DoD (se marca solo tras ejecución, no antes)
- [ ] `json-utils.Tests.ps1`: 5/5 pass (single-element array preservation)
- [ ] `use-gentleman.Tests.ps1`: still pass (no regression)
- [ ] `sync-vmk.Tests.ps1`: still pass (no regression)
- [ ] Benchmark: `Measure-Command { sync-vmk.ps1 -DryRun }` ×10, mediana/IQR real vs baseline estadístico (§0.7)
- [ ] ADR-028: evaluation mini-doc
- [ ] Commit: `refactor: extract json-utils.ps1 with PSSerializer deep-clone`

---

## 2. Ciclo 2 — G3: sync-vmk.ps1 full agent sync (checkpoint Alto)

### Scope Lock
```
IN:  scripts/sync-vmk.ps1 (L54: agent section sync)
     scripts/tests/sync-vmk-full-agents.Tests.ps1 (nuevo)
OUT: todo lo demás
```

### Orden del ciclo (corregido — enfoques ANTES de implementar, por protocolo §3.3)
Este gap tuvo un fix aplicado fuera de proceso en una sesión anterior (`$target.agent = $canonical.agent`, full replace). Ese fix **no se da por bueno automáticamente**: se evalúa aquí junto a las otras dos alternativas, como exige el protocolo, y se conserva solo si gana la comparación.

### 3 Enfoques

| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (Full replace) | `$target.agent = $canonical.agent` — el fix ya aplicado en sesión previa | Simple, SSoT garantizado | Borra custom overrides (ninguno detectado hasta ahora, pero no verificado exhaustivamente) |
| **B** (Merge) | Merge por-key: preserve existing agents, add new ones | Permite custom overrides | Más complejo, posible drift |
| **C** (Diff) | Only sync missing agents | Minimal diff | No detecta config drift existente |

### Ganador esperado
**A** (full replace) — sujeto a confirmación en el checkpoint humano (ver DoD).

### DoD (se marca solo tras ejecución y checkpoint, no antes)
- [ ] `sync-vmk-full-agents.Tests.ps1`: 3/3 pass
- [ ] Global config: 50 agents (39 gentleman + 10 sdd + 1 gentle-orchestrator)
- [ ] ADR-029: full agent sync decision, incluyendo por qué A gana sobre B/C
- [ ] Commit: `fix(sync): sync all agents including sdd-* and gentle-orchestrator`
- [ ] **Checkpoint humano: PENDIENTE** — blast radius Alto, requiere aprobación explícita antes de merge (no antes de commit en branch experimental)

---

## 3. Ciclo 3 — G2: CI quality gate + ConfigValidator

### Scope Lock
```
IN:  .github/workflows/ci.yml (nuevo)
     scripts/lib/ConfigValidator.psm1 (nuevo)
     scripts/tests/config-validator.Tests.ps1 (nuevo)
     ANTI-PATTERN-CATALOG.md (add entry)
OUT: todo lo demás
```

### 3 Enfoques

| Enfoque | Descripción | Pros | Contras |
|---------|------------|------|---------|
| **A** (Minimal) | `ConfigValidator.psm1`: `Test-SkillsPaths`, `Test-PromptRefs`, `Test-AgentDefinitions`. CI: quality-gate → tests → validate | Simple, rápido, target G1/G3 regression prevention | No schema completo |
| **B** (Schema) | JSON schema validation vs `https://opencode.ai/config.json` | Completo, preventivo | False positives, maintenance overhead |
| **C** (Pre-commit) | Git hook que valida antes de commit | Más temprano en pipeline | No cubre CI/CD de GitHub |

### Ganador esperado
**A** — por metric hierarchy: security (Medio). G1/G3 son los gaps; A es el validator que los previene.

### DoD (se marca solo tras ejecución, no antes)
- [ ] `config-validator.Tests.ps1`: 5/5 pass
- [ ] `Test-OpencodeConfig $env:GITHUB_WORKSPACE/opencode.json` (ruta relativa al workspace del runner, no `D:\...`) → returns 0 (pass)
- [ ] `.github/workflows/ci.yml`: runner `ubuntu-latest`, steps con `shell: pwsh`, secuencia quality → tests → validate (fail fast)
- [ ] ANTI-PATTERN-CATALOG.md: "ConvertTo-Json array unwrapping" entry
- [ ] Commit: `feat: CI quality gate validates opencode.json schema + ConfigValidator module`

---

## 4. Verificación Final & PR

### DoD Global (§3.8 binario) — checks solo tras ejecución real de los 3 ciclos
| Check | Status |
|-------|--------|
| Pester: 0 NEW failures | Pendiente de ejecución |
| Benchmark no regresivo (mediana/IQR, 10 runs baseline vs 10 runs final) | Pendiente de ejecución |
| 0 new critical/high vulns | Pendiente de ejecución |
| ADRs escritos | `ADR-027`, `ADR-028`, `ADR-029` |
| Commits in scope | Pendiente de verificación por ciclo |
| Rollback map | Pendiente — ver §5, hashes reales tras commits |
| **Checkpoint humano G3 (Alto)** | **Pendiente — obligatorio antes de merge a main** |

### Deliverables
```
docs/mejoras/plan-auto-mejora-v3-2026-08-13.md  ← ESTE ARCHIVO
docs/mejoras/benchmarks.md                       ← crear o actualizar (verificar si ya existe antes de asumir "update")
docs/mejoras/rollback-map.md                     ← nuevo
mejora-log.md                                    ← append Cycles 1-3
adr/ADR-027-mejora-autonoma-v3-kickoff.md        ← nuevo
adr/ADR-028-json-utils-evaluation.md             ← nuevo
adr/ADR-029-sync-vmk-full-agent-sync.md          ← nuevo
ANTI-PATTERN-CATALOG.md                          ← append entry
```

### PR (§6)
- **Base**: `main` · **Compare**: `experimento/mejora-autonoma-2026-08-13`
- **Title**: `fix: prevent PowerShell array unwrapping + CI config validation + full agent sync`
- **Body**: cycles evaluados, 3 enfoques cada uno, benchmark IQR real, ADRs, rollback map con hashes reales
- **NO merge to main** — espera aprobación humana explícita (obligatoria por G3 Alto, no solo recomendada)

---

## 5. Rollback Map
*(placeholder hasta que existan los commits reales — no se completa antes de ejecutar los ciclos)*

```
Commit <pendiente>  refactor: extract json-utils.ps1        → REVERTIBLE via git revert
Commit <pendiente>  fix(sync): full agent sync               → REVERTIBLE, restaura 39 agents
Commit <pendiente>  feat: CI config validator                → REVERTIBLE, elimina archivos nuevos
```

---

## Aprobación requerida

**Checkpoint Alto** (G3): fix candidato existe de una sesión previa, pero se re-evalúa contra B/C en el Ciclo 2 y **no se da por aprobado** hasta que un humano lo confirme explícitamente aquí abajo.

**Aprobado para ejecutar**: [ ] Sí — lanzar branch + 3 ciclos + PR
**Aprobado para merge de G3 a main** (independiente de lo anterior): [ ] Sí

*Protocolo: docs/protocolos/protocolo_mejora_autonoma_v3.md*
*Fecha: 2026-08-13*
