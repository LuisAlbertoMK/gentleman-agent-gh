---
name: project-mapper
description: >
  Scan project structure, detect tech stack, architecture, and generate dependency map.
  Trigger: "mapear", "project map", "estructura", "tech stack", "arquitectura", "project structure".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1", changelog: "1.0->1.1 (sprint 1: 79->50 lines, -36.7%, condensed Output format example to template)"
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

## Rules
1. Start with `ls` / `Get-ChildItem` of root → top-level detection
2. Drill 2-3 levels for architecture detection
3. Run 1-2 commands to validate (test count, coverage, lint)
4. If project >50 files → show summary counts, not full tree
5. Adapt Output format to project size — examples are templates, not mandates
