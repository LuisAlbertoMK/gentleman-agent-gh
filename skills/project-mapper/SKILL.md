---
name: project-mapper
description: >
  project-mapper skill
triggers: "Mapear, project map, estructura, tech stack, arquitectura"
  Scan project structure, detect tech stack, architecture, and generate dependency map.
  Trigger: "mapear", "project map", "estructura", "tech stack", "arquitectura", "project structure".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.4", changelog: "1.3->1.4: auto-chain now MANDATORY (not optional), direct linkage to intake-verify.ps1, FE/BE/DB template routing"
---

## When
New project, unfamiliar codebase, user asks "how is this structured".

## Project Type Classification
> Classification tables live in `gap-analysis` skill to avoid duplication.
> See `~/.config/opencode/skills/gap-analysis/SKILL.md` → Phase 0.1 Classify Project Type.

## Stack detection

| File | Detects | Configures |
|------|---------|------------|
| `go.mod` | Go | Module path, version |
| `package.json` | Node/JS/TS | Framework (express/next/react), scripts |
| `pyproject.toml` / `Pipfile` | Python | Framework (django/fastapi/flask) |
| `Cargo.toml` | Rust | — |
| `composer.json` | PHP | — |
| `*.csproj` | C#/.NET | — |
| `Dockerfile` | Docker | Base image, stages |
| `docker-compose.yml` | Docker Compose | Services, ports, volumes |

## Architecture detection

| Pattern | Architecture | Heuristic |
|---------|-------------|-----------|
| `internal/`, `pkg/`, `cmd/` | Go Standard | dir structure |
| `src/domain/`, `src/application/`, `src/infrastructure/` | Hexagonal/Clean | naming |
| `src/components/`, `src/containers/` | Atomic/React | naming |
| `app/Models/`, `app/Http/Controllers/` | MVC | naming |
| `services/`, `repositories/` | Service Layer | naming |

## Output format
```
## Project Map: {project name}
### Classification
- **Tech Layer**: {frontend|backend|db|mobile|desktop|full-stack|infra}
- **Business Type**: {saas|erp|ecom|cms|api|web|desktop|mobile}
- **Full-stack**: {FE framework} + {BE framework}
### Tech Stack
- Language: X | Framework: Y | DB: Z | Test: T | CI: C
### Architecture: {name}
{path}             → {role}
{path}/sub/        → {role}
### Dependency Graph
{src} → {dest} → {dest}
### Module Counts
| Layer | Files | Lines | **Total** | *sum* | *sum* |
### Quick Stats
- Tests: N (X% coverage) | Lint: clean | Docker: M MB
### Suggested Next Step
→ **MANDATORY**: gap-analysis with {template} (8 dims: UI/UX, Security, Optimization, Performance, Resource Usage, Project Velocity, Responsive Design, Infrastructure)
→ `powershell -File scripts/intake-verify.ps1 -ProjectPath "{path}" -Iterations 3`
→ Save results to `docs/metricas/`
```

## Auto-Chain: gap-analysis (MANDATORY)
After generating project map, MUST trigger gap-analysis with matching project type.
gap-analysis handles the 3-iteration intake verification cycle (roadmap, PR, PRD, README, Tests, CI/CD, Monitoring).

**Flow**:
1. project-mapper classifies tech layer + business type
2. Auto-runs `powershell -File scripts/intake-verify.ps1 -ProjectPath "..." -Iterations 1` for baseline
3. Loads gap-analysis skill with matching template (type + layer)
4. Gap-analysis runs 8-dim scoring + 3-iteration verification
5. Results saved to `docs/metricas/`

**THIS IS NOT OPTIONAL.** Every project MUST go through intake verification.
Projects without roadmap, PRD, or README get grade F and must fix before feature work.

Pass detected tech layer + business type to gap-analysis. Use templates:
- `fe-template.md` for frontend projects
- `be-template.md` for backend projects
- `db-template.md` for database projects
- Plus business-specific templates from gap-analysis/assets/

## Rules
1. Start with `ls` / `Get-ChildItem` of root → top-level detection
2. Classify tech layer + business type from signals
3. Drill 2-3 levels for architecture detection
4. Run 1-2 commands to validate (test count, coverage, lint)
5. If project >50 files → show summary counts, not full tree
6. Adapt Output format to project size — examples are templates, not mandates
7. After mapping → auto-suggest gap-analysis with matching template + 8-dim intake

