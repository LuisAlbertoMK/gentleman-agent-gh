---
name: project-mapper
description: "Scan project structure, detect tech stack, classify architecture, generate dependency map; auto-chains to gap-analysis."
triggers: "Mapear, project map, estructura, tech stack, arquitectura"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1904
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
## Refs
gap-analysis · research · execution-mode · sdd · skill-graph · engram-protocol
## Reference
Architecture Detection table + Output Format → docs/skills/project-mapper/reference.md