---
name: project-mapper
description: "Scan project structure, detect tech stack, classify architecture, generate dependency map; auto-chains to gap-analysis."
triggers: "Mapear, project map, estructura, tech stack, arquitectura"
changelog: docs/ciclos/cycle28-20260815.md
---

# Project Mapper — C28 Depth

Scan project structure, detect stack, classify architecture. Auto-link to gap-analysis.

## When to Use

New project, unfamiliar codebase, "how is this structured", onboarding, pre-refactor assessment.

## Project Type Classification

Reference: gap-analysis skill (Phase 0.1) for classification tables. Avoid duplication.

## Stack Detection Signals

| Signal | Stack | Framework Hint |
|--------|-------|----------------|
| `go.mod` | Go | gin, echo, fiber, chi |
| `package.json` | Node/JS/TS | express, next, react, vue, nest, fastify |
| `pyproject.toml` / `Pipfile` | Python | django, fastapi, flask, litestar |
| `Cargo.toml` | Rust | actix, axum, rocket, tonic |
| `composer.json` | PHP | laravel, symfony, slim |
| `*.csproj` / `*.sln` | C#/.NET | aspnetcore, minimal-api |
| `build.gradle` / `pom.xml` | JVM | spring-boot, quarkus, micronaut |
| `Dockerfile` | Docker | multi-stage? |
| `docker-compose.yml` | Docker Compose | services count |
| `makefile` / `Makefile` | Build | targets reveal tasks |
| `justfile` / `Taskfile.yml` | Task Runner | commands reveal workflow |
| `turbo.json` / `nx.json` | Monorepo | turbo, nx |
| `pnpm-workspace.yaml` / `yarn.lock` | Workspaces | package manager |

## Architecture Detection Patterns

| Pattern | Structure Signal | Confidence |
|---------|------------------|------------|
| Go Standard Layout | `internal/`, `pkg/`, `cmd/` | High |
| Hexagonal / Clean | `src/domain/`, `src/application/`, `src/infrastructure/` | High |
| Atomic Design (React) | `src/components/atoms/`, `molecules/`, `organisms/`, `templates/`, `pages/` | High |
| MVC (Classic) | `app/Models/`, `app/Http/Controllers/`, `app/Views/` | High |
| Service Layer | `services/`, `repositories/`, `models/` | Medium |
| Feature-Based | `src/features/{feature}/` | Medium |
| Module-Based | `src/modules/{module}/` | Medium |
| Layered | `presentation/`, `business/`, `data/` | Medium |
| Microkernel / Plugin | `core/`, `plugins/`, `extensions/` | Low |
| Event-Driven | `events/`, `handlers/`, `projections/` | Medium |

## Output Format

```
## Project Map: {name}
### Classification: Tech Layer + Business Type
### Tech Stack: Lang | Framework | DB | Test | CI
### Architecture: {pattern}
{path} -> {role}
{path}/sub -> {role}
### Dependency Graph
{src} -> {dest} -> {dest}
### Module Counts: Layer | Files | Lines | Total
### Quick Stats: Tests (N, X%), Lint, Docker size
### Suggested -> gap-analysis with {template}
```

## Auto-Chain Protocol

After map completes, present: "Project classified as {tech layer}/{business type}. Run gap-analysis with {template}? (Y/n)"

Only auto-execute if user explicitly confirms or `--auto` flag passed.

## Rules

1. Start with root `ls` / `Get-ChildItem` → top-level detection
2. Classify tech+business from signals (multiple passes if ambiguous)
3. Drill 2-3 levels for architecture pattern
4. Validate: test count, coverage %, lint config, Docker size
5. >50 files → summary counts per layer, not full tree
6. Adapt output format to project size (micro/small/medium/large)
7. After mapping → suggest gap-analysis with matching template
8. Save findings to engram with topic_key `architecture/project-map:{name}`

## Refs

gap-analysis · research · execution-mode · sdd · skill-graph · engram-protocol
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when producing a project map:

- **Worked Examples (5)**: Go microservice, Next.js App Router, Python FastAPI, .NET Minimal API, Turborepo monorepo
  → docs/skills/project-mapper/reference.md
- **Testing, Edge Cases, Anti-Patterns, Engram Integration, Quick Reference Card**
  → same file above

---
