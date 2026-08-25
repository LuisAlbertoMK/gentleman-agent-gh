# SDD Init — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/sdd-init/SKILL.md) for the core activation, decision gates, and execution steps.

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

### 1. Registry exists & populated
```powershell
$r=gc .atl/skill-registry.md -Raw; $r-match'^\|.*\|' -and ($r-split'\n').Count-gt10
```

### 2. Testing capabilities persisted
```powershell
# Engram: mem_search("sdd-init/{proj}")|mem_get_observation → testing:{runner,layers,cov,linter,type,strict_tdd}
# Openspec: gc openspec/config.yaml|ConvertFrom-Yaml → .testing.runner,.layers,.coverage,.strict_tdd
```

### 3. Strict TDD resolution
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

## Externalized Sections (ADR-007 compression)
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

> See [reference.md](docs/skills/sdd-init/reference.md) for extended details, examples, and detailed patterns.
