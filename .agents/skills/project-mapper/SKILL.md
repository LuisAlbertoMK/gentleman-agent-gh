---
name: project-mapper
description: "Scan project structure, detect tech stack, classify architecture, generate dependency map; auto-chains to gap-analysis."
triggers: "Mapear, project map, estructura, tech stack, arquitectura"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2916
---
# Project Mapper
Scan project structure, detect stack, classify architecture. Auto-link to gap-analysis.
## When to Use
New project, unfamiliar codebase, "how is this structured", onboarding, pre-refactor assessment.
## Project Type Classification
Reference: gap-analysis skill (Phase 0.1) for classification tables. Avoid duplication.
## Stack Detection Signals
`go.mod`→Go(gin/echo/fiber/chi) | `package.json`→Node(express/next/react/vue/nest) | `pyproject.toml`/`Pipfile`→Python(django/fastapi/flask) | `Cargo.toml`→Rust(actix/axum/rocket) | `composer.json`→PHP(laravel/symfony) | `*.csproj`→C#/.NET | `build.gradle`/`pom.xml`→JVM(spring-boot/quarkus) | `Dockerfile`→Docker | `docker-compose.yml`→Compose | `makefile`/`justfile`/`Taskfile.yml`→Build/Task Runner | `turbo.json`/`nx.json`→Monorepo | `pnpm-workspace.yaml`/`yarn.lock`→Workspaces.
## Auto-Chain Protocol
After map: "Project classified as {tech layer}/{business type}. Run gap-analysis with {template}? (Y/n)". Only auto-execute on explicit confirm or `--auto`.
## Rules
1. Start root `ls`/`Get-ChildItem` → top-level detection. 2. Classify from signals (multiple passes if ambiguous). 3. Drill 2-3 levels for architecture. 4. Validate: test count, coverage, lint, Docker size. 5. >50 files → summary counts per layer. 6. Adapt output to project size. 7. Suggest gap-analysis. 8. Save to engram `topic_key: architecture/project-map:{name}`.
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "stack adivinado sin evidence" | Stack sin señales go.mod/package.json/pyproject/Cargo/composer | Verificar Stack Detection Signals con file:line + drill 2-3 niveles + test count/coverage/lint |
| "dependency map manual en vez de tool-backed" | Map manual sin validación tool-backed | Verificar dependency map tool-backed + Auto-Chain Protocol a gap-analysis file:line + engram architecture/project-map |
| "clasificación Tech/Biz sin checklist" | Clasificación sin tablas gap-analysis Phase 0.1 | Verificar Project Type Classification vía gap-analysis tables + validación >50 files summary file:line |


## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
gap-analysis · research · execution-mode · sdd · skill-graph · engram-protocol
## Reference
Architecture Detection table + Output Format → docs/skills/project-mapper/reference.md

