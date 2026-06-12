---
name: project-mapper
description: >
  Scan project structure, detect tech stack, architecture, and generate dependency map.
  Trigger: "mapear", "project map", "estructura", "tech stack", "arquitectura", "project structure".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.3", changelog: "1.2->1.3: project type classification (tech layer + business type), 8-dim auto-chain"
---

## When
New project, unfamiliar codebase, user asks "how is this structured".

## Project Type Classification
Detect BOTH tech layer AND business type. This drives template selection in gap-analysis.

### Tech Layer Detection

| Signal | Layer | Detected Type |
|--------|-------|---------------|
| `package.json` + react/vue/angular/svelte/next | Frontend | Web SPA/SSR |
| `package.json` + electron/tauri | Desktop | Electron/Tauri |
| `pubspec.yaml`, `Podfile`, `build.gradle` (android) | Mobile | Flutter/Native/RN |
| `go.mod` + `cmd/` `internal/` | Backend | Go API/Monolith |
| `package.json` + express/fastify/nest | Backend | Node API |
| `main.py` + django/fastapi/flask | Backend | Python API |
| `*.csproj` + Program.cs | Backend | C# API |
| `Cargo.toml` (no tauri) | Backend | Rust API |
| `prisma/schema`, `migrations/`, `*.sql` | Database | SQL/NoSQL |
| `Dockerfile` + no app code | Infra | Container |
| `terraform/`, `k8s/`, `ansible/` | Infra | IaC |

### Business Type Detection

| Signal in code/docs | Business Type |
|---------------------|---------------|
| tenant, subscription, billing, plan | SaaS |
| invoice, order, stock, inventory, vendor | ERP |
| product, cart, checkout, payment, shipping | E-commerce |
| content, page, blog, post, article | CMS |
| api, endpoint (no UI) | API |
| landing, marketing, blog (public) | Web |
| window, dialog, tray, menu | Desktop App |
| screen, navigator, push notification | Mobile App |

### Full Stack Detection
If both frontend and backend signals found → classify as full-stack.
Detect FE/BE framework pairs: Next.js, Nuxt, Remix, Laravel, Django+template.

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
→ gap-analysis with {template} (8 dims: UI/UX, Security, Optimization, Performance, Resource Usage, Project Velocity, Responsive Design, Infrastructure)
```

## Auto-Chain: gap-analysis trigger
After generating project map, AUTO-trigger gap-analysis matching project type.
Use detected tech layer + business type to select template:

| Tech Layer | Business Type | Template | Intake includes |
|------------|---------------|----------|-----------------|
| Frontend | Web / CMS | web-template | 8 dims + responsive design |
| Full-stack | SaaS | saas-template | 8 dims + infra + velocity |
| Backend | API | api-template | Security + perf + infra |
| Backend | ERP | erp-template | Functional + security + infra |
| Full-stack | E-commerce | ecom-template | UX + security + perf |
| Desktop | Desktop App | desktop-template | UX + resource + infra |
| Mobile | Mobile App | mobile-template | UX + perf + resource |
| Any | Unknown | generic → all 6 layers | Basic intake |
| Database | Any | N/A (component, not system) | Skip, focus on host system |

Present as: "Project classified as **{tech layer}** / **{business type}**. Auto-gap-analysis with **{template}**? Includes intake checklist + 8 quality dimensions. (Y/n)"

## Rules
1. Start with `ls` / `Get-ChildItem` of root → top-level detection
2. Classify tech layer + business type from signals
3. Drill 2-3 levels for architecture detection
4. Run 1-2 commands to validate (test count, coverage, lint)
5. If project >50 files → show summary counts, not full tree
6. Adapt Output format to project size — examples are templates, not mandates
7. After mapping → auto-suggest gap-analysis with matching template + 8-dim intake
