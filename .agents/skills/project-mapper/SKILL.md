---
name: project-mapper
description: "Scan project structure, detect tech stack, classify architecture, and generate dependency map with auto-chain to gap-analysis"
triggers: "Mapear, project map, estructura, tech stack, arquitectura"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.2->1.3: project type classification (tech layer + business type)
---

Scan project structure, detect tech stack, architecture, and generate dependency map.Trigger: "mapear", "project map", "estructura", "tech stack", "arquitectura", "project structure".
## WhenNew project, unfamiliar codebase, user asks "how is this structured".
## Project Type Classification> Classification tables live in `gap-analysis` skill to avoid duplication.> See `~/.config/opencode/skills/gap-analysis/SKILL.md` â†’ Phase 0.1 Classify Project Type.
## Stack detection| File | Detects | Configures ||------|---------|------------|| `go.mod` | Go | Module path, version || `package.json` | Node/JS/TS | Framework (express/next/react), scripts || `pyproject.toml` / `Pipfile` | Python | Framework (django/fastapi/flask) || `Cargo.toml` | Rust | â€” || `composer.json` | PHP | â€” || `*.csproj` | C#/.NET | â€” || `Dockerfile` | Docker | Base image, stages || `docker-compose.yml` | Docker Compose | Services, ports, volumes |
## Architecture detection| Pattern | Architecture | Heuristic ||---------|-------------|-----------|| `internal/`, `pkg/`, `cmd/` | Go Standard | dir structure || `src/domain/`, `src/application/`, `src/infrastructure/` | Hexagonal/Clean | naming || `src/components/`, `src/containers/` | Atomic/React | naming || `app/Models/`, `app/Http/Controllers/` | MVC | naming || `services/`, `repositories/` | Service Layer | naming |
## Output format
```
## Project Map: {project name}
### Classification- **Tech Layer**: {frontend|backend|db|mobile|desktop|full-stack|infra}- **Business Type**: {saas|erp|ecom|cms|api|web|desktop|mobile}- **Full-stack**: {FE framework} + {BE framework}
### Tech Stack- Language: X | Framework: Y | DB: Z | Test: T | CI: C
### Architecture: {name}{path}             â†’ {role}{path}/sub/        â†’ {role}
### Dependency Graph{src} â†’ {dest} â†’ {dest}
### Module Counts| Layer | Files | Lines | **Total** | *sum* | *sum* |
### Quick Stats- Tests: N (X% coverage) | Lint: clean | Docker: M MB
### Suggested Next Stepâ†’ gap-analysis with {template} (8 dims: UI/UX, Security, Optimization, Performance, Resource Usage, Project Velocity, Responsive Design, Infrastructure)
```
## Auto-Chain: gap-analysis triggerAfter generating project map, AUTO-trigger gap-analysis matching project type.gap-analysis handles template selection (see its Phase 0). Pass detected tech layer + business type.Present as: "Project classified as **{tech layer}** / **{business type}**. Run gap-analysis? Includes intake checklist + 8 quality dimensions. (Y/n)"
## Rules1. Start with `ls` / `Get-ChildItem` of root â†’ top-level detection2. Classify tech layer + business type from signals3. Drill 2-3 levels for architecture detection4. Run 1-2 commands to validate (test count, coverage, lint)5. If project >50 files â†’ show summary counts, not full tree6. Adapt Output format to project size â€” examples are templates, not mandates7. After mapping â†’ auto-suggest gap-analysis with matching template + 8-dim intake
