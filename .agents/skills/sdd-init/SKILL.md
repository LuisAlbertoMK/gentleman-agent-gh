---
name: sdd-init
description: "Initialize SDD context, testing capabilities, registry, persistence. Trigger: sdd init, iniciar sdd, openspec init."
triggers: "SDD init, initialize SDD, bootstrap SDD, SDD context setup"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP, delegate to `sdd-init` sub-agent. Executor: execute directly.

## Activation
Run when orchestrator/user asks to initialize SDD. You are the phase executor — do the work, don't delegate.

## Language
Generated artifacts default to English. Spanish: neutral/professional unless regional variant requested. Comments follow target context.

## Hard Rules
- Detect real stack, conventions, architecture, testing tools, persistence mode; never guess.
- `engram`: do NOT create `openspec/`. `openspec`: follow `../_shared/openspec-convention.md`, write files. `hybrid`: write both.
- Always persist testing capabilities as `sdd/{project}/testing-capabilities` or `openspec/config.yaml` `testing:`.
- Always build `.atl/skill-registry.md`; save `skill-registry` to Engram when available.
- `capture_prompt: false` for automated SDD/config saves.
- If `openspec/` exists, report what exists and ask before updating.

## Decision Gates
| Input | Action |
|---|---|
| `mode=engram` | Save context + capabilities to Engram only |
| `mode=openspec` | Create/update openspec bootstrap files only |
| `mode=hybrid` | Both Engram and openspec |
| `mode=none` | Return detected context only; no SDD artifacts except registry |
| Strict TDD marker/config found | Use that value |
| No marker but test runner exists | Default `strict_tdd: true` |
| No test runner | Set `strict_tdd: false`, explain unavailable |

## Execution Steps
1. Inspect project files (`package.json`, `go.mod`, `pyproject.toml`, CI, lint/test config) → summarize stack/conventions.
2. Detect test runner, test layers, coverage, linter, type checker, formatter.
3. Resolve Strict TDD from agent marker, `openspec/config.yaml`, detected runner fallback, or no-runner fallback.
4. Initialize persistence for resolved mode.
5. Build `.atl/skill-registry.md` using skill-registry scan rules.
6. Persist testing capabilities and project context.
7. Return structured initialization envelope.

## Output Contract
Return `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`. Include: project, stack, persistence mode, Strict TDD status, testing capability table, saved observation IDs/paths, registry path, next `/sdd-explore` or `/sdd-new` step.

---

## Examples (5)

| Scenario | Command | Stack | Mode | Strict TDD | Output |
|---|---|---|---|---|---|
| Node/TS + Jest | `sdd init --mode=engram` | pkg.json, jest, CI | engram | marker→true | registry, testing:{jest,[unit,int],80%} |
| Go + go test | `iniciar sdd --mode=openspec` | go.mod, golangci, CI | openspec | runner→true | config.yaml+specs/, hybrid Engram |
| Python no runner | `openspec init --mode=hybrid` | pyproject.toml, no test | hybrid | false+explain | Engram topic_key + config.yaml runner=null |
| Monorepo scoped | `sdd init --mode=engram --scope=apps/api` | turbo, apps/api/pkg.json, vitest | engram | marker→true | topic_key: sdd-init/proj/apps/api |
| Offline/air-gapped | `sdd init --mode=none` | pkg.json, no Engram | none | N/A | status=partial, registry only, warning |

---

## Testing Patterns (3)

**1. Registry exists & populated**
```powershell
$r=gc .atl/skill-registry.md -Raw; $r-match'^\|.*\|' -and ($r-split'\n').Count-gt10
```

**2. Testing capabilities persisted**
```powershell
# Engram: mem_search("sdd-init/{proj}")|mem_get_observation → testing:{runner,layers,cov,linter,type,strict_tdd}
# Openspec: gc openspec/config.yaml|ConvertFrom-Yaml → .testing.runner,.layers,.coverage,.strict_tdd
```

**3. Strict TDD resolution**
```powershell
# Fixtures: [marker→true], [no marker+runner→true], [no runner→false+explain]
# Assert output.contract.strict_tdd per fixture
```

---

## Edge Cases (4)

| Case | Behavior |
|---|---|
| **Multi-project monorepo** | Respect `--scope`; detect pkg at scope root; registry scans all skills; topic_key includes scope |
| **Engram unavailable (offline)** | `engram\|hybrid`→degrade to `none`+warning; registry built; return `status=partial` |
| **Partial registry (scan failures)** | Continue on per-skill errors; log failed in footnote; don't fail init |
| **Legacy openspec/ exists** | Report existing; ask before update; merge not overwrite; preserve history |

---

## Anti-Patterns (2)

| Anti-Pattern | Fix |
|---|---|
| Guessing stack/runner | Always inspect pkg files + CI + lint; fallback only when truly absent |
| Overwriting openspec/ blindly | If exists→report→ask→merge; never blind overwrite |

---

## Refs
- `references/init-details.md` — detection checklist, Engram payloads, config skeleton, output templates
- `../_shared/engram-convention.md` — Engram artifact naming
- `../_shared/openspec-convention.md` — openspec layout and rules

> **Size tradeoff**: Core boilerplate (frontmatter, gates, steps, contract, refs) = ~4KB required for SDD init contract. Depth (examples, testing, edge cases, anti-patterns) = ~1KB. Total ~5KB exceeds 3KB target but all sections are essential — no further compression without losing actionable guidance.