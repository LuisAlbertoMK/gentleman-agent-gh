---
name: project-mapper
description: >
  Scan project structure, detect tech stack, architecture, and generate dependency map.
  Trigger: "mapear", "project map", "estructura", "tech stack", "arquitectura", "project structure".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.2", changelog: "1.1->1.2: auto-chain gap-analysis trigger after mapping"
---

## When
New project, unfamiliar codebase, user asks "how is this structured".

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
```

## Auto-Chain: gap-analysis trigger
After generating project map, AUTO-trigger gap-analysis matching project type:
| Detected type | Auto-suggest |
|---------------|-------------|
| Web (HTML/CSS/JS/React) | gap-analysis depth=Quick, template=web-template |
| SaaS (multi-tenant, API) | gap-analysis depth=Standard, template=saas-template |
| ERP (inventory, invoices) | gap-analysis depth=Standard, template=erp-template |
| Desktop (Electron, Tauri, WPF) | gap-analysis depth=Quick, template=desktop-template |
| API/backend (Go, Node, Python) | gap-analysis depth=Quick, default layers: Technical+Security |
| Unknown/generic | gap-analysis depth=Quick, all 6 layers |

Present as: "Project mapped. Suggest auto-gap-analysis with {template}? (Y/n)"

## Rules
1. Start with `ls` / `Get-ChildItem` of root → top-level detection
2. Drill 2-3 levels for architecture detection
3. Run 1-2 commands to validate (test count, coverage, lint)
4. If project >50 files → show summary counts, not full tree
5. Adapt Output format to project size — examples are templates, not mandates
6. After mapping → auto-suggest gap-analysis based on detected project type
