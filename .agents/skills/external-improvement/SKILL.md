---
name: external-improvement
description: "5-phase improvement cycle for external projects — 3+ subagents per phase."
triggers: "improve external project, mejora proyecto, proyecto externo, 5-phase cycle, ciclo 5 fases, analizá este proyecto, corré el ciclo, revisame el proyecto, !5fases, !extimprove, aplicá las 5 fases"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
5-phase improvement cycle for external projects — 3+ subagen


## 5-Phase Cycle

Each phase: 3+ subagents via `task()` or `delivery-harness`. Return 4-field: `Decision Taken | Files Changed | Key Findings | Nuance`.

| Phase | Subagents | Focus | Output | Gate |
|-------|-----------|-------|--------|------|
| **P1 EXPLORE** | 3 | Structure, Architecture, Dependencies | `docs/external/<proj>/P1-EXPLORE.md` | All 3 reports must exist |
| **P2 DIAGNOSE** | 3+ | Quality, Security, Performance (+Tests opt) | `P2-DIAGNOSIS.md` | ≥3 subagents complete |
| **P3 PLAN** | 3 | I/R scoring, dep graph, rollback strategy | `P3-PLAN.md` | ≥1 batch with I/R ≥ 1.0 |
| **P4 EXECUTE** | 2/batch | Apply fixes + doc/tests per batch | `P4-EXECUTION.md` | All batches applied or SKIP'd |
| **P5 VERIFY & LEARN** | 3 | Regression, Score delta, Learning extraction | `P5-REPORT.md` | Score drop >0.5 → revert |

**Rule**: If P3 finds no batch with I/R ≥ 1.0 → STOP (project healthy).

## Behaviors
- **Internal** (gentleman-agent-gh): P1 skip, P2 ↔ score-auto.ps1, P3 light, P4 full, P5 full
- **External**: full 5 phases with standalone fallback
- Serial batches unless dep graph says parallel. Rollback per batch.
- Max 3 consecutive SKIP → abort. Score drop >0.5 → full revert.
- Stdlib doesn't cover this (needs 3 tool types in one pass).

## Output
```
docs/external/<project>/
├── P1-EXPLORE.md
├── P2-DIAGNOSIS.md
├── P3-PLAN.md
├── P4-EXECUTION.md
└── P5-REPORT.md
```

## Error Handling
| Failure | Action |
|---------|--------|
| Subagent timeout | Retry once with stricter scope, then SKIP |
| Phase gate not met | STOP phase, try next if independent |
| Score drop >0.5 | Full revert |
| 3 consecutive SKIP | Abort cycle, write partial report |
| Human needed | `conflict` file + escalation |

## Refs
delivery-harness · project-mapper · gap-analysis · sdd-propose/verify · triple-verify · codebase-memory · bitacora · commit-crafter · CYCLE.md (§5-Phase Cycle Loop)

## Anti-Patterns
Skip P1/P2 (explore/diagnose) · Parallelize dependent phases · Ignore score drop threshold · Over-commit on SKIP · Mix internal/external checklist · Reuse internal agents for external work · Skip P5 learning extraction (loses compound knowledge)

## Examples

### 1. Legacy Laravel API → Modernize Auth + Add Tests
**Context**: 5-year-old Laravel 8 API, no tests, JWT auth with hardcoded secrets.
**P1**: 3 agents → map routes, DB schema, middleware chain.
**P2**: 4 agents → security (secrets, SQLi), quality (god controllers), perf (N+1 queries), tests (0% coverage).
**P3**: I/R scoring → Batch 1: Extract secrets to env + rotate (I/R=3.2). Batch 2: Repository pattern + Pest tests (I/R=1.8). Batch 3: Eager loading fixes (I/R=2.1).
**P4**: 2 agents/batch → apply, verify tests pass.
**P5**: Score delta +0.7 → commit. Learning: "Laravel policies > middleware for authZ".

### 2. React SPA → Accessibility + Bundle Audit
**Context**: Create-React-App, 2.4MB bundle, 0 a11y, no CI.
**P1**: 3 agents → component tree, deps, routes.
**P2**: 4 agents → a11y (axe), bundle (webpack-bundle-analyzer), perf (INP), tests (RTL gaps).
**P3**: Batch 1: Code-split routes + lazy (I/R=2.8). Batch 2: Radix UI primitives + focus management (I/R=1.5). Batch 3: GitHub Actions + playwright a11y (I/R=1.2).
**P4**: Apply → bundle 890KB, a11y 94%.
**P5**: Delta +1.1. Learning: "Bundle analysis before code-split avoids over-splitting".

### 3. Go Microservice → Observability + Resilience
**Context**: Single Go service, no metrics, no circuit breaker, manual deploys.
**P1**: 3 agents → call graph, config, deployment.
**P2**: 4 agents → security (deps), quality (error handling), perf (pprof), tests (integration gaps).
**P3**: Batch 1: OpenTelemetry + Prometheus (I/R=2.5). Batch 2: Circuit breaker + retry (I/R=1.9). Batch 3: ArgoCD + canary (I/R=1.3).
**P4**: Apply → dashboards live, 99.9% SLO.
**P5**: Delta +0.9. Learning: "OTel auto-instrumentation first, custom spans after".

### 4. Python FastAPI → Type Safety + Contract Tests
**Context**: FastAPI, no mypy, loose schemas, flaky E2E.
**P1**: 3 agents → routers, models, dependencies.
**P2**: 4 agents → security (CORS, rate limit), quality (any types), perf (async DB), tests (contract gaps).
**P3**: Batch 1: Strict mypy + pydantic v2 (I/R=2.2). Batch 2: Schemathesis contract tests (I/R=1.7). Batch 3: Redis cache layer (I/R=1.4).
**P4**: Apply → mypy clean, contract tests in CI.
**P5**: Delta +0.8. Learning: "Contract tests catch schema drift unit tests miss".

### 5. Monorepo → Shared Tooling + Dependency Hygiene
**Context**: 12 packages, duplicated eslint/tsconfig, circular deps.
**P1**: 3 agents → workspace graph, configs, build order.
**P2**: 4 agents → security (supply chain), quality (dead code), perf (build time), tests (flaky e2e).
**P3**: Batch 1: Turbo + shared configs (I/R=3.0). Batch 2: Depcruise rules + fixes (I/R=2.4). Batch 3: Changesets + release automation (I/R=1.6).
**P4**: Apply → CI 40% faster, zero circular.
**P5**: Delta +1.3. Learning: "Shared tooling first unlocks all other improvements".

## Testing Patterns

### Pattern 1: Phase Gate Verification
```bash
# P1 gate: all 3 explore reports exist
ls docs/external/<proj>/P1-EXPLORE-*.md | wc -l  # must be 3

# P2 gate: ≥3 diagnosis subagents complete
grep -c "Decision Taken" docs/external/<proj>/P2-DIAGNOSIS-*.md  # must be ≥3

# P3 gate: ≥1 batch with I/R ≥ 1.0
grep "I/R" docs/external/<proj>/P3-PLAN.md | awk -F'[= ]' '$2 >= 1.0' | wc -l  # must be ≥1

# P5 gate: score drop check
python -c "
import json
before = json.load(open('docs/external/<proj>/P2-DIAGNOSIS.md'))['score']
after = json.load(open('docs/external/<proj>/P5-REPORT.md'))['score']
assert after - before > -0.5, f'Score drop {after-before} > 0.5 → REVERT'
"
```

### Pattern 2: Subagent Output Contract Validation
```python
# Each subagent must return 4-field format
def validate_subagent_output(output: str) -> bool:
    required = ["Decision Taken", "Files Changed", "Key Findings", "Nuance"]
    return all(field in output for field in required)

# Usage in delivery-harness aggregation
for result in subagent_results:
    assert validate_subagent_output(result), f"Invalid format: {result[:100]}"
```

### Pattern 3: Rollback Verification Per Batch
```bash
# After each P4 batch, verify rollback works
git stash push -m "batch-N-pre-rollback"
git stash pop  # should restore cleanly
# Verify tests still pass
npm test  # or pytest, go test, etc.
git stash drop
```

## Edge Cases

### 1. External Project Has No Git History
**Symptom**: `git log --oneline` returns empty or single commit.
**Handling**: Initialize git first (`git init && git add . && git commit -m "baseline"`). All phases work against this baseline. P5 score uses static analysis only (no delta).

### 2. Subagent Returns Partial/Truncated Output
**Symptom**: 4-field block cut off mid-field (common with large file outputs).
**Handling**: Require file-based fallback — subagent writes `docs/external/<proj>/P{phase}-{agent}.md` and echoes only the path. Orchestrator reads file for full content.

### 3. Dependency Graph Shows Circular Batches
**Symptom**: P3 dep graph has cycles (Batch A needs B, B needs A).
**Handling**: Merge into single batch with combined I/R. If combined I/R < 1.0 → STOP (project healthy). Never split circular deps.

### 4. Score Calculation Differs Between Phases
**Symptom**: P2 uses `score-auto.ps1` but P5 uses different metric.
**Handling**: Lock scoring method in P1 explore report. Both phases import same scoring module. Document formula in `P1-EXPLORE.md`.

### 5. Human Escalation During P4 Execution
**Symptom**: Subagent writes `conflict` file (per Error Handling).
**Handling**: Pause all batches. Orchestrator reads `conflict`, presents to user. User resolves → delete `conflict` → resume. Max 1 human intervention per cycle.

## Anti-Patterns (Extended)

### Anti-Pattern: Reuse Internal Agents for External Work
**What**: Using `gentleman-codex` or `gentleman-quick` agents for external project phases.
**Why it fails**: Internal agents assume repo context, conventions, test infra. External projects have none.
**Fix**: Always spawn fresh subagents with explicit project context via `delivery-harness`. Pass `projectPath` to every tool.

### Anti-Pattern: Skip P5 Learning Extraction
**What**: Treat P5 as "run tests and done" — skip `learning` field in session summary.
**Why it fails**: Compound knowledge lost. Next external project repeats same discoveries.
**Fix**: P5 subagent 3 MUST write `learning` to engram with `topic_key: external-improvement/<pattern>`. Verify via `mem_search` before next cycle.
