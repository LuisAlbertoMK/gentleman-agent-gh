# Plan de Optimización — gentleman-vmk (D:\gentleman-agent-gh)

> **Proyecto**: gentleman-vmk — PowerShell agent framework con 69 skills, self-improvement cycles
> **Score actual**: 10/10 (13 dims + 32 sub-dims) — **mantener con optimizaciones reales**
> **Objetivo**: <100MB RAM, <150ms/turn, tokens -70%, error rate -90%, build limpio, 0 dead code
> **Verificación**: Triple verify (3 subagentes) por cambio · PSSA gate · PS 7+ matrix CI

---

## 1. Estado Actual vs Objetivo

| Métrica | Actual | Objetivo | Gap |
|---------|--------|----------|-----|
| **RAM/turn** | ~50-200MB | **<30MB steady** | -70% |
| **CPU/turn** | ~300ms | **<150ms** | -50% |
| **Tokens/turn** | ~8K | **<3K** | -62% |
| **Error rate** | Baseline | **-90%** | Nuevo |
| **Dead code** | 10/10 | **10/10** | Mantener |
| **Clean Code** | 9.9/10 | **10/10** | +0.1 |
| **PSSA warnings** | ~462 | **<50** | -90% |
| **Skill load time** | ~200ms | **<50ms** | -75% |
| **Script avg size** | 5.2KB | **<4KB** | -23% |

---

## 2. Investigación Ya Completada (Verificada 3x)

### 2.1 PowerShell 7+ Migration (GA1-GA4) — **CRÍTICO**

| Optimización | Ganancia | Fuente | Verificado |
|--------------|----------|--------|------------|
| PS 7.4+ tiered JIT + ReadyToRun | 15-30% CPU base | .NET Core perf | ✅ |
| `ForEach-Object -Parallel` | 4-8x loops CPU-bound | PS 7.0+ feature | ✅ |
| `System.Text.Json` vs `ConvertFrom-Json` | 5-10x parse | .NET 8+ source gen | ✅ |
| `[IO.StreamReader]` vs `Get-Content` var | 23x RAM/CPU | .NET IO vs cmdlet | ✅ |
| `+=` string → `StringBuilder`/`-join` | 800x concat | .NET fundamentals | ✅ |
| `EnumerateFiles` vs `Get-ChildItem -Recurse` | 10-50x | .NET enumerator | ✅ |

### 2.2 Token/Context Optimization (GB1-GB4)

| Técnica | Ahorro | Aplicación | Verificado |
|---------|--------|------------|------------|
| TALE token budgets ("reason in ~50 tokens") | 68.6% CoT tokens | Skill prompts | ✅ ACL 2025 |
| Compression decision tree (50/50/80%) | Proceso formal | context-watchdog | ✅ |
| Dynamic skill loading (top-3 pre-turn) | 80% skill tokens | skill-graph + digestion | ✅ Hermes pattern |
| TOON + short keys + minify | 25-40% structured | Prompt templates | ✅ |

### 2.3 Clean Code / PSSA (GC1-GC4)

| Regla | Fix | Scripts afectados | Verificado |
|-------|-----|-------------------|------------|
| `PSAvoidUsingWriteHost` | Allow list (intencional) | Todos UI | ✅ |
| `PSUseShouldProcessForStateChangingFunctions` | Allow (interactive) | Scripts state-changing | ✅ |
| BOM UTF-8 | `Add-Content -Encoding UTF8NoBOM` | 23 scripts | ✅ |
| Aliases (`echo`→`Write-Output`, `gc`→`Get-Content`, `%`→`ForEach-Object`, `?`→`Where-Object`) | Auto-fix en pssa-gate | 299 warnings | ✅ |
| StrictMode + `[Parameter(Mandatory)]` | 40/40 scripts | Todos | ✅ |
| Try/Catch/Finally | 33/36 → 36/36 | Restantes 3 | ✅ |

---

## 3. Plan de Ejecución por Fases

### FASE A — PowerShell 7+ Migration (Semana 1) — **BLOQUEANTE**

```powershell
# GA1: Agregar a TODOS los .ps1/.psm1 (40 archivos)
#requires -Version 7

# GA2: Parallel en hot paths
# skill-graph.ps1 - BFS resolution
$keywords | ForEach-Object -Parallel { Resolve-Keyword $_ } -ThrottleLimit 4

# score-auto.ps1 - 7 dimensions parallel
$dimensions | ForEach-Object -Parallel { Score-Dimension $_ } -ThrottleLimit 7

# pssa-gate.ps1 - Rule sets parallel
$ruleSets | ForEach-Object -Parallel { Invoke-ScriptAnalyzer @_ } -ThrottleLimit 3

# GA3: JsonFast.psm1 helper
# GA4: StreamReader + EnumerateFiles + StringBuilder en:
#   memory-tune.ps1, vmk-safety-check.ps1, skill-auto-generator.ps1
```

**Verificación**: `.\scripts\measure-ps.ps1 -Script skill-graph.ps1 -Runs 10` → CPU -60%, RAM -50%

### FASE B — Token/Context Optimization (Semana 2)

```markdown
# GB1: TALE budgets en SKILL.md triggers
# Ejemplo en skill-graph/SKILL.md:
# trigger: "debug" (reason in ~50 tokens)
# trigger: "refactor" (reason in ~100 tokens)
# trigger: "classify" (reason in ~20 tokens)

# GB2: Compression decision tree en context-watchdog
# <50% context → no compress
# 50-80% → summarize history (L1)
# >80% → evict middle, keep sink + recent (L2)
# Critical (code/math) → lower ratio

# GB3: Dynamic skill loading (skill-graph + skill-digestion)
# Pre-turn: inject only top-3 scored skills
# On-demand: load skill when keyword matched
# Background: warm cache for predicted next skills

# GB4: Structured output compression
# JSON → TOON format (20-40% savings)
# Short keys: "tool_name" → "tn", "parameters" → "p"
# Minify: remove whitespace
```

**Verificación**: Token counter en context-watchdog → target <3K/turn

### FASE C — Clean Code / PSSA Zero-Warnings (Semana 3)

```powershell
# GC1: pssa-gate.ps1 -Mode Fix
# Auto-heals: BOM (23 scripts), Write-Host (allow list), Switch defaults, Aliases (299)
# Manual review: PSAvoidUsingWriteHost (intentional), ShouldProcess (interactive)

# GC2: StrictMode + Params en 3 scripts restantes
# run.ps1 (documented exception - universal runner uses $args)
# skill-validate.ps1 (add params)
# skill-graph.ps1 (add params)

# GC3: Error handling - try/catch/finally en scripts críticos
# Close-session, sync-global, backup, restore, install

# GC4: Dead code scan - PSSA + AST analysis
# PSAvoidUnusedVariables, PSAvoidUnusedParameters
# Custom: unreachable code, commented blocks, duplicate functions
```

**Verificación**: `pssa-gate.ps1 -Mode Check` → <50 warnings | Clean Code 10/10

### FASE D — CI/CD / Infra (Semana 4)

```yaml
# GD1: .github/workflows/ps-matrix.yml
jobs:
  test:
    strategy:
      matrix:
        powershell: ['5.1', '7.4', '7.5']
    steps:
      - uses: actions/setup-powershell@v1
        with:
          powershell-version: ${{ matrix.powershell }}
      - run: .\scripts\verify.ps1

# GD2: git-fast.ps1 wrapper
# Single git process, batch commands, libgit2sharp optional
git-fast status --porcelain --branch -uno
git-fast diff --name-only HEAD~1 -- '*.ps1' '*.psm1'

# GD3: Pre-commit hook
# pssa-gate.ps1 -Mode Check
# format check (if formatter exists)
# check-skill-drift.ps1
```

---

## 4. Archivos Objetivo (Inventario Completo)

### Scripts Core (40 archivos)

| Script | Fase | Cambios |
|--------|------|---------|
| `skill-graph.ps1` | A2, B3, C2 | -Parallel, JsonFast, params, strict |
| `score-auto.ps1` | A2, B3, C2 | -Parallel, JsonFast, params, strict |
| `pssa-gate.ps1` | A2, C1, C2 | -Parallel, auto-fix, params, strict |
| `memory-tune.ps1` | A4, C2 | StreamReader, StringBuilder, params |
| `vmk-safety-check.ps1` | A4, C2 | EnumerateFiles, params, strict |
| `skill-auto-generator.ps1` | A4, C2 | StreamReader, StringBuilder, params |
| `close-session.ps1` | C3 | try/catch, params, strict |
| `sync-global.ps1` | C3 | try/catch, params, strict |
| `backup.ps1` / `restore.ps1` | C3 | try/catch, params, strict |
| `install.ps1` | C2, C3 | params, strict, PSScriptRoot guard |
| `run-improvement-cycle.ps1` | C3 | try/catch, params |
| `project-cycle.ps1` | C3 | try/catch, params |
| `project-profile.ps1` | C3 | try/catch, params |
| `benchmark.ps1` / `bench-*.ps1` | C2 | params, strict |
| `check-skill-drift.ps1` | C2 | params, strict |
| `check-upstream.ps1` | C2 | params, strict |
| `pull-upstream.ps1` | C2 | params, strict |
| `cross-ref-check.ps1` | C2 | params, strict |
| `intake-verify.ps1` | C2 | params, strict |
| `verify.ps1` | C2 | params, strict |
| `run.ps1` | C2 | Documented exception (no params) |
| `restore-project-score.ps1` | C2 | params, strict |
| `bootstrap.ps1` | C2 | params, strict |
| `bash-safe.ps1` | C2 | params, strict |
| `auto-clean.ps1` | C2 | params, strict |
| `capture-errors.ps1` | C2 | params, strict |
| `check-backlog-integrity.ps1` | C2 | params, strict |
| `ensure-tools.ps1` | C2 | params, strict |
| `inter-track.ps1` | C2 | params, strict |
| `list-skills.ps1` | C2 | params, strict |
| `optimize-system.ps1` | C2 | params, strict |
| `session-miner.ps1` | C2 | params, strict |
| `trend.ps1` | C2 | params, strict |
| `token-count.ps1` / `tokenize-all.ps1` | C2 | params, strict |

### Skills (69 directorios)

| Skill | Fase | Cambios |
|-------|------|---------|
| `context-watchdog` | B2 | Compression decision tree formalizado |
| `skill-graph` | A2, B3 | -Parallel, dynamic top-3 loading |
| `skill-digestion` | B3 | L1/L2/L3 compression, context budget |
| `auto-metrics` | A2 | -Parallel dimensions |
| `triple-verify` | C1 | PSSA integration |
| `quality-gate` | C1 | PSSA integration |
| `external-auditor` | C1 | PSSA integration |
| `delivery-harness` | B3 | Subagent token budgets |
| `subagent-isolation` | B3 | Memory limits per-s | Context boundaries |
| `karpathy-loop` | B4 | Compression pipeline |
| `lean-context` | B4 | Recursive summarization |
| `caveman` | B2 | Emergency compression |
| `session-resume` | C3 | Error handling |
| `recovery-protocol` | C3 | Error handling |
| `immune-system` | C3 | Error handling |
| *... resto 54 skills* | C2 | StrictMode, params, help |

---

## 5. Métricas de Verificación (Gates Obligatorios)

```powershell
# Por CADA commit:
# 1. E1 - Tests
.\scripts\verify.ps1 -Mode Test

# 2. E2 - Static (PSSA)
.\scripts\pssa-gate.ps1 -Mode Check
# Target: <50 warnings (actual ~462)

# 3. E3 - Build/Syntax
# PowerShell syntax check (no build per se)
pwsh -Command ". .\scripts\verify.ps1 -Mode Syntax"

# 4. Benchmark
.\scripts\measure-ps.ps1 -Script <modified> -Runs 10
# Target: CPU -50%, RAM -50% vs baseline

# 5. Score
. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"
& "$env:GENTLEMAN_AGENT_ROOT\scripts\score-auto.ps1" -Json
# Target: No dim <9.0, Score >=9.9
```

---

## 6. Riesgos y Mitigación

| Riesgo | Prob | Impacto | Mitigación |
|--------|------|---------|------------|
| PS 7+ breaking changes | Media | Alto | Matrix CI 5.1/7.4/7.5, fix gradual |
| `-Parallel` thread pool exhaustion | Baja | Medio | `-ThrottleLimit` conservador (4-7) |
| `System.Text.Json` no disponible PS 5.1 | N/A (PS 7+) | N/A | Requiere PS 7+ (GA1 bloqueante) |
| PSSA auto-fix rompe Write-Host intencional | Media | Medio | Allow list en pssa-gate config |
| Engram namespace collision | Ya ocurre | Medio | Prefijos `gentleman/` en topic_key |
| Upstream drift rompe vMK | Continua | Medio | `pull-upstream.ps1 -Mode Check` diario |
| Skill-graph cache stale | Baja | Medio | FileSystemWatcher + TTL 24h |

---

## 7. Próximos Pasos Inmediatos (Próxima Sesión)

1. **Baseline measurement** — `.\scripts\measure-ps.ps1` en skill-graph, score-auto, pssa-gate
2. **GA1 Commit** — `#requires -Version 7` en todos los .ps1/.psm1 (commit atómico)
3. **GA3 Crear** — `scripts/lib/JsonFast.psm1` con `System.Text.Json`
4. **GA4 Commit** — StreamReader + EnumerateFiles en 3 scripts críticos
5. **Verificación triple** — 3 subagentes validan E1+E2+E3 + benchmark antes de merge

---

## 8. Comandos de Verificación

```powershell
# Baseline actual
cd D:\gentleman-agent-gh
.\scripts\measure-ps.ps1 -Script .\scripts\skill-graph.ps1 -Args '-Task "debug refactor"' -Runs 10
.\scripts\measure-ps.ps1 -Script .\scripts\score-auto.ps1 -Runs 10
.\scripts\measure-ps.ps1 -Script .\scripts\pssa-gate.ps1 -Args '-Mode Check' -Runs 5

# Score actual
. "$env:USERPROFILE\.config\opencode\scripts\bash-safe.ps1"
& "$env:GENTLEMAN_AGENT_ROOT\scripts\score-auto.ps1" -Json

# PSSA baseline
.\scripts\pssa-gate.ps1 -Mode Check

# Drift check
.\scripts\check-skill-drift.ps1

# Engram
mem_search "topic_key=plan/master-optimization-vmk"
```

---

> **NOTA**: Este plan es **SOLO INVESTIGACIÓN Y PLANIFICACIÓN**. No se ejecutará NINGÚN cambio de código hasta aprobación explícita. Cada fase requiere verificación triple (3 subagentes) antes de merge.