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

## Examples (5)

### Example 1: Go Microservice (Standard Layout)

**Input**: `github.com/org/payment-svc` (root: `go.mod`, `cmd/`, `internal/`, `pkg/`)

```
## Project Map: payment-svc
### Classification: Infrastructure Layer / Payment Processing Service
### Tech Stack: Go 1.22 | Gin | PostgreSQL | testify | GitHub Actions
### Architecture: Go Standard Layout
cmd/server         -> entrypoint (main, wiring)
internal/handler   -> HTTP handlers (gin)
internal/service   -> business logic
internal/repository -> data access (sqlc)
internal/middleware -> auth, logging, metrics
pkg/errors         -> shared error types
pkg/config         -> config loading (viper)
### Dependency Graph
cmd/server -> internal/handler -> internal/service -> internal/repository
internal/service -> pkg/errors
internal/handler -> pkg/config
### Module Counts: Layer | Files | Lines | Total
entrypoint         | 3     | 120   | 120
handlers           | 8     | 450   | 570
services           | 12    | 1200  | 1770
repositories       | 6     | 600   | 2370
shared             | 4     | 200   | 2570
### Quick Stats: Tests (24, 68%), golangci-lint, Docker 28MB
### Suggested -> gap-analysis with go-microservice template
```

---

### Example 2: Next.js 14 App Router (Feature-Based)

**Input**: `apps/web` (root: `package.json`, `app/`, `components/`, `lib/`)

```
## Project Map: web (Next.js 14)
### Classification: Presentation Layer / SaaS Dashboard
### Tech Stack: TypeScript 5.4 | Next.js 14 (App Router) | Prisma/PostgreSQL | Vitest + Playwright | GitHub Actions
### Architecture: Feature-Based + Atomic Design Hybrid
app/(auth)/login       -> route group: auth pages
app/(dashboard)/       -> route group: protected dashboard
app/api/               -> route handlers (server actions)
components/ui/         -> atoms (Button, Input, Card)
components/forms/      -> molecules (LoginForm, SettingsForm)
components/layout/     -> organisms (Sidebar, Header, DashboardLayout)
lib/auth.ts            -> auth utilities (next-auth)
lib/db.ts              -> Prisma client singleton
lib/validators/        -> zod schemas
hooks/                 -> custom hooks (useAuth, useToast)
### Dependency Graph
app/(dashboard)/ -> components/layout/ -> components/ui/
app/api/         -> lib/auth.ts, lib/db.ts
components/forms/ -> components/ui/, lib/validators/
hooks/           -> lib/auth.ts
### Module Counts: Layer | Files | Lines | Total
routes             | 18    | 850   | 850
components         | 42    | 2100  | 2950
lib/utils          | 15    | 600   | 3550
hooks              | 8     | 320   | 3870
### Quick Stats: Tests (38, 72%), ESLint + Prettier, Docker 1.2GB
### Suggested -> gap-analysis with nextjs-saas template
```

---

### Example 3: Python FastAPI (Hexagonal / Clean)

**Input**: `services/user-api` (root: `pyproject.toml`, `src/`)

```
## Project Map: user-api (FastAPI)
### Classification: Application Layer / User Management API
### Tech Stack: Python 3.11 | FastAPI | SQLAlchemy/PostgreSQL | pytest | GitHub Actions
### Architecture: Hexagonal (Ports & Adapters)
src/domain/               -> entities, value objects, domain events
  entities/user.py
  events/user_created.py
src/application/          -> use cases, ports (interfaces)
  ports/user_repository.py
  use_cases/create_user.py
  use_cases/get_user.py
src/infrastructure/       -> adapters (implement ports)
  persistence/sqlalchemy_user_repo.py
  api/fastapi_routes.py
  config/settings.py
src/interface/            -> delivery (HTTP, CLI, gRPC)
  http/routes/users.py
  http/middleware/auth.py
tests/                    -> mirrors src structure
  unit/domain/
  unit/application/
  integration/infrastructure/
### Dependency Graph
src/interface/http -> src/application/use_cases -> src/domain
src/application/ports <- src/infrastructure/persistence (implements)
src/infrastructure/api -> src/application/use_cases
### Module Counts: Layer | Files | Lines | Total
domain             | 6     | 280   | 280
application        | 10    | 650   | 930
infrastructure     | 14    | 1100  | 2030
interface          | 5     | 300   | 2330
tests              | 28    | 1800  | 4130
### Quick Stats: Tests (52, 85%), ruff + mypy, Docker 145MB
### Suggested -> gap-analysis with python-hexagonal template
```

---

### Example 4: .NET 8 Minimal API (Vertical Slice)

**Input**: `src/Ordering.Api` (root: `Ordering.Api.csproj`, `Features/`, `Shared/`)

```
## Project Map: Ordering.Api
### Classification: Application Layer / Order Processing API
### Tech Stack: C# 12 | .NET 8 Minimal API | Entity Framework Core/SQL Server | xUnit | GitHub Actions
### Architecture: Vertical Slice Architecture
Features/Orders/         -> complete vertical slice
  Commands/CreateOrder/
    CreateOrderCommand.cs
    CreateOrderHandler.cs
    CreateOrderValidator.cs
  Queries/GetOrder/
    GetOrderQuery.cs
    GetOrderHandler.cs
  Domain/
    Order.cs, OrderItem.cs, OrderStatus.cs
Shared/                  -> cross-cutting
  Kernel/                -> base classes, Result<T>, MediatR pipeline
  Infrastructure/        -> EF Core DbContext, repositories
  Presentation/          -> endpoint mapping, problem details
### Dependency Graph
Features/Orders/Commands -> Features/Orders/Domain
Features/Orders/Queries  -> Features/Orders/Domain
Shared/Kernel           -> (none, base)
Shared/Infrastructure   -> Features/Orders/Domain (EF mappings)
### Module Counts: Layer | Files | Lines | Total
features/orders        | 22    | 1400  | 1400
shared/kernel          | 8     | 400   | 1800
shared/infrastructure  | 6     | 500   | 2300
shared/presentation    | 4     | 250   | 2550
tests                  | 35    | 2200  | 4750
### Quick Stats: Tests (41, 78%), dotnet format + analyzers, Docker 180MB
### Suggested -> gap-analysis with dotnet-vertical-slice template
```

---

### Example 5: Monorepo (Turborepo + pnpm)

**Input**: `monorepo-root` (root: `turbo.json`, `pnpm-workspace.yaml`, `packages/`, `apps/`)

```
## Project Map: acme-monorepo
### Classification: Platform / Multi-App Monorepo
### Tech Stack: TypeScript 5.4 | Turborepo | pnpm 9 | Various per package | Changesets
### Architecture: Monorepo - Package-Based with Internal Packages
apps/web/              -> Next.js 14 (customer portal)
apps/admin/            -> Next.js 14 (admin dashboard)
apps/api/              -> NestJS (REST API)
packages/ui/           -> shared React component library (atomic)
packages/config/       -> shared ESLint, TSConfig, Tailwind config
packages/database/     -> Prisma schema + migrations
packages/auth/         -> shared auth utilities (next-auth config)
packages/eslint-config/-> shared lint rules
packages/tsconfig/     -> shared TS configs (base, nextjs, node)
### Dependency Graph
apps/web      -> packages/ui, packages/auth, packages/config
apps/admin    -> packages/ui, packages/auth, packages/config
apps/api      -> packages/database, packages/auth
packages/ui   -> packages/config, packages/tsconfig
packages/auth -> packages/config
### Module Counts: Layer | Files | Lines | Total
apps (3)              | 85    | 12000 | 12000
packages (6)          | 120   | 8500  | 20500
tooling/config        | 15    | 800   | 21300
### Quick Stats: Tests (156, 71% avg), turborepo pipeline, Docker multi-stage
### Suggested -> gap-analysis with monorepo-template (per-app + shared)
```

---

## Testing (3)

### Test 1: Detection Accuracy

```bash
# Given a fixture project with known structure
# Run project-mapper and verify:
# - Tech stack detected correctly (language, framework, DB)
# - Architecture pattern matches fixture classification
# - Module counts within 10% of actual
```

**Fixtures**: `test/fixtures/go-standard/`, `test/fixtures/nextjs-feature/`, `test/fixtures/python-hexagonal/`

### Test 2: Output Format Compliance

```bash
# Verify output contains all required sections:
# - Project Map header
# - Classification line
# - Tech Stack line
# - Architecture line
# - Path -> Role mappings
# - Dependency Graph
# - Module Counts table
# - Quick Stats line
# - Suggested gap-analysis line
```

### Test 3: Auto-Chain Behavior

```bash
# Verify gap-analysis suggestion matches project type:
# - Go microservice -> go-microservice template
# - Next.js SaaS -> nextjs-saas template
# - Python hexagonal -> python-hexagonal template
# - .NET vertical slice -> dotnet-vertical-slice template
# - Monorepo -> monorepo-template
# Verify prompt format: "Project classified as X. Run gap-analysis with Y? (Y/n)"
```

---

## Edge Cases (4)

### Edge Case 1: Hybrid / Ambiguous Architecture

**Scenario**: Project mixes patterns (e.g., `internal/` + `src/domain/` + `app/Http/Controllers`)

**Resolution**: 
- Score each pattern by signal strength (file count, depth, naming)
- Report primary + secondary: "Primary: Go Standard (0.82), Secondary: Hexagonal (0.35)"
- Drill into conflicting directories to understand intent
- Document ambiguity in output for human review

### Edge Case 2: Empty / Skeleton Project

**Scenario**: Only `go.mod` + `main.go` (no internal structure yet)

**Resolution**:
- Detect "Initializing" state
- Output minimal map with "Architecture: Not yet established"
- Suggest: "Run after first feature scaffold. gap-analysis with go-microservice template when ready."
- Do NOT auto-chain

### Edge Case 3: Monorepo with Mixed Languages

**Scenario**: `apps/api` (Go) + `apps/web` (Next.js) + `packages/shared` (TypeScript)

**Resolution**:
- Map each app/package independently
- Produce per-app maps + aggregate monorepo map
- Tech Stack: list per app (Go | Gin, TypeScript | Next.js)
- Architecture: per-app classification
- Dependency Graph: cross-language via shared packages only

### Edge Case 4: Generated / Vendor Code Dominance

**Scenario**: `vendor/`, `node_modules/`, `dist/`, `build/` > 80% of files

**Resolution**:
- Exclude known generated directories by default (configurable via `.project-mapper-ignore`)
- Count source files only for module counts
- Flag: "Generated code excluded (vendor: 12k files, node_modules: 45k files)"
- If source < 20 files, warn: "Project appears to be mostly generated. Verify source root."

---

## Anti-Patterns (2)

### Anti-Pattern 1: Full Tree Dump on Large Projects

**Bad**: Printing 500+ lines of `tree` output for a 2000-file repo

**Good**: Summary counts per layer/module, drill-down on request
- >50 files: aggregate by architectural layer
- >200 files: aggregate by top-level domain/package
- Always show: "Use `--detail <layer>` to expand"

### Anti-Pattern 2: Classification Before Signal Validation

**Bad**: Seeing `package.json` → instantly output "Architecture: React" without checking `src/` structure

**Good**: 
- Pass 1: Collect ALL signals (root + 2 levels deep)
- Pass 2: Score each architecture pattern against signals
- Pass 3: Validate with deeper drill (3 levels) on top candidate
- Only then classify with confidence score

---

## Engram Integration

After successful mapping, save:

```python
mem_save(
    title=f"Project map: {project_name}",
    type="architecture",
    topic_key=f"architecture/project-map:{project_name}",
    content=f"""**What**: Mapped {project_name} structure and classified architecture
**Why**: Baseline for gap-analysis / onboarding / refactor planning
**Where**: {project_root}
**Learned**: {key_insights_or_ambiguities}"""
)
```

---

## Quick Reference Card

| Project Size | Depth | Output Style | Auto-Chain |
|--------------|-------|--------------|------------|
| < 20 files   | 3     | Full tree    | Ask        |
| 20-50 files  | 3     | Full tree    | Ask        |
| 50-200 files | 2-3   | Layer summary| Ask        |
| 200-1000     | 2     | Domain summary| Ask       |
| > 1000       | 1-2   | Top-level only| Ask       |

**Confidence thresholds**: High ≥ 0.8, Medium 0.5-0.8, Low < 0.5 (report all)