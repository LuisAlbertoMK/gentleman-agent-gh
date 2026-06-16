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
  changelog: "1.2->1.3: project type classification (tech layer + business type)"
---

Scan project structure, detect stack, classify architecture. Auto-link to gap-analysis.

## When
New project, unfamiliar codebase, "how is this structured"

## Project Type
Classification tables in gap-analysis skill (Phase 0.1). Avoid duplication.

## Stack Detection
go.mod -> Go | package.json -> Node/JS/TS (express/next/react) | pyproject.toml/Pipfile -> Python (django/fastapi/flask) | Cargo.toml -> Rust | composer.json -> PHP | *.csproj -> C#/.NET | Dockerfile -> Docker | docker-compose.yml -> Docker Compose

## Architecture Detection
internal/pkg/cmd -> Go Standard | src/domain/application/infrastructure -> Hexagonal/Clean | src/components/containers -> Atomic/React | app/Models/Http/Controllers -> MVC | services/repositories -> Service Layer

## Output Format
`
## Project Map: {name}
### Classification: Tech Layer + Business Type
### Tech Stack: Lang | Framework | DB | Test | CI
### Architecture: {pattern}
{path} -> {role}{path}/sub -> {role}
### Dependency Graph
{src} -> {dest} -> {dest}
### Module Counts: Layer | Files | Lines | Total
### Quick Stats: Tests (N, X%), Lint, Docker size
### Suggested -> gap-analysis with {template}
`

## Auto-Chain
After map, auto-trigger gap-analysis matching project type. Present as: "Project classified as {tech layer}/{business type}. Run gap-analysis? (Y/n)"

## Rules
1. Start with root ls/Get-ChildItem -> top-level detection
2. Classify tech+business from signals
3. Drill 2-3 levels for architecture
4. Validate (test count, coverage, lint)
5. >50 files -> summary counts, not tree
6. Adapt output format to project size
7. After mapping -> suggest gap-analysis with matching template
