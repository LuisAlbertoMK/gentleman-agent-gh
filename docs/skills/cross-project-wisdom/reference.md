# cross-project-wisdom — Reference Materials

> **Externalized from** .agents/skills/cross-project-wisdom/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### 1. React: State Lifting for Shared UI State
**Pattern**: Lift shared state to nearest common ancestor instead of prop drilling or Context overuse
**Severity**: HIGH
**Context**: 3 projects (dashboard, admin, e-commerce) — all hit prop-drilling >3 levels
**Check**: Any component passing same prop through 3+ intermediate components
**Fix**: Create a dedicated context/provider or lift to parent with `useReducer` for complex state

### 2. Node/TS: Zod Schema Co-location with Route Handler
**Pattern**: Define input/output Zod schemas in same file as route handler, export for tests
**Severity**: MEDIUM
**Context**: 4 APIs — separated schemas caused drift; co-location eliminated 12 type mismatches
**Check**: Schema files in separate `schemas/` folder from route handlers
**Fix**: Move schema adjacent to handler; `export const CreateUserSchema = z.object(...)` in `routes/users.ts`

### 3. Python/FastAPI: Dependency Injection for DB Sessions
**Pattern**: Use `Depends(get_db)` with contextmanager yielding session — never manual `SessionLocal()`
**Severity**: CRITICAL
**Context**: 2 services — manual sessions leaked connections under load; DI fixed via auto-close
**Check**: Any `SessionLocal()` call outside a `Depends` provider
**Fix**: Centralize in `database.py`; inject via `db: Session = Depends(get_db)`

### 4. Go: Error Wrapping with `%w` for Sentinel Errors
**Pattern**: Always wrap with `fmt.Errorf("context: %w", err)` — enables `errors.Is/As` checks upstream
**Severity**: HIGH
**Context**: 5 CLI tools — raw errors lost context; wrapped errors enabled targeted retry logic
**Check**: `errors.New()` or `fmt.Errorf()` without `%w` in call chains >2 deep
**Fix**: Replace with wrapped form; define sentinel `var ErrNotFound = errors.New("not found")`

### 5. Terraform: Module Composition over Resource Duplication
**Pattern**: Compose reusable modules with `for_each` — never copy-paste resource blocks across envs
**Severity**: MEDIUM
**Context**: 3 infra repos — drift between dev/staging/prod; modules cut 60% LOC and eliminated drift
**Check**: Identical `resource "aws_*"` blocks in multiple `.tf` files
**Fix**: Extract to `modules/<name>/main.tf` with variables; call via `module "name" { source = "..." for_each = var.envs }`

## Testing Patterns

### 1. Contract Testing for Cross-Service APIs
**Pattern**: Publish consumer-driven contracts (Pact) from integration tests; verify on provider CI
**Applies when**: Multiple services share HTTP/gRPC interfaces
**Verification**: `pact-verifier` runs in provider pipeline; fails build on contract breach
**Evidence**: 2 projects — caught 7 breaking changes before deploy

### 2. Property-Based Testing for Serialization Roundtrips
**Pattern**: Use `fast-check` (TS) / `hypothesis` (Py) / `gopter` (Go) to verify `decode(encode(x)) == x`
**Applies when**: Custom codecs, binary protocols, schema evolution
**Verification**: 1000+ random inputs per type; shrinks to minimal failing case
**Evidence**: Found 3 encoding bugs in message pack codec that unit tests missed

### 3. Mutation Testing for Critical Business Logic
**Pattern**: Run Stryker (TS) / mutmut (Py) / go-mutesting on domain core — require 80%+ mutation score
**Applies when**: Financial calculations, auth decisions, state machines
**Verification**: CI gate fails if score drops; survivors reviewed manually
**Evidence**: 1 project — caught 5 logic bugs where tests asserted wrong expectations

## Edge Cases

### 1. Pattern Context Mismatch (False Positive)
**Scenario**: Pattern matches tech stack but domain differs (e.g., React pattern from e-commerce applied to real-time dashboard)
**Mitigation**: Require `domain` + `tags` overlap ≥ 2; if only `technologies` match, downgrade severity to LOW

### 2. Stale Pattern (Architecture Drift)
**Scenario**: Pattern from monolithic architecture applied to microservices — e.g., shared DB transactions
**Mitigation**: Check `metadata.last_confirmed` < 6 months; if older, flag as `needs_review` and require manual validation

### 3. Conflicting Patterns
**Scenario**: Two patterns suggest opposite approaches (e.g., "use Context" vs "avoid Context for performance")
**Mitigation**: Present both with their contexts; let developer choose based on current constraints; log conflict for `cross-project-forge`

### 4. Pattern Overload (Context Pollution)
**Scenario**: >10 patterns matched for a simple task — noise drowns signal
**Mitigation**: Hard cap at 5 patterns per invocation; if more match, show top 5 by score + "N more available — run with --all"

## Anti-Patterns

- Never block commits/PRs based on patterns alone — patterns are advisory, not gates
- Don't load more than 5 patterns into context unless explicitly asked — cognitive load exceeds value
- Don't treat patterns as authoritative — always verify applicability to current architecture
- Don't store secrets or credentials in pattern evidence — patterns are committed to repo
- **Don't apply patterns blindly across architectural boundaries** — monolith patterns often fail in distributed systems
- **Don't treat pattern `confidence` as probability of success** — confidence reflects source reliability, not outcome guarantee

## Resources

`docs/cross-project/patterns/*.json` · `docs/cross-project/PLAN.md` · `docs/cross-project/README.md`

## Refs
cross-project-forge · dreaming · immune-system · research · session-resume

## Externalized Sections (ADR-007 compression)
## Commands

```powershell
# Manual load
Get-ChildItem "docs/cross-project/patterns/*.json" | ForEach-Object { Get-Content $_ | ConvertFrom-Json }

# Search by technology
$patterns | Where-Object { $_.context.technologies -match "gradient" }

# Search by severity
$patterns | Where-Object { $_.severity -eq "HIGH" -or $_.severity -eq "CRITICAL" }
```
