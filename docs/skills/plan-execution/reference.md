# plan-execution — Reference Materials

> **Externalized from** .agents/skills/plan-execution/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## EXAMPLES

### Example 1: Full Feature Plan (Multi-file, TDD)
**Plan**: Add user avatar upload with resize + CDN sync
```markdown
## Plan: avatar-upload
Tasks:
  T1: Add Avatar model + migration (depends: none)
  T2: POST /api/avatar endpoint (depends: T1)
  T3: Image resize pipeline (sharp) (depends: T1)
  T4: CDN upload (S3) + DB sync (depends: T3)
  T5: Integration tests (depends: T2, T4)
  T6: E2E smoke test (depends: T5)
```
**Execution**:
```
git checkout -b plan/avatar-upload
git commit -am "baseline: pre-avatar-upload"
→ T1: create migration, model, run `npm test` ✅
→ T2: add endpoint, validation, run `npm test` ✅
→ T3: add sharp resize, run `npm test` ✅
→ T4: add S3 upload, DB update, run `npm test` ❌ (AWS creds missing)
   → rollback T4 files, mark BLOCKED
→ T5: integration tests (mock S3), run `npm test` ✅
→ T6: e2e with mock, run `npm test` ✅
git commit -am "feat: avatar upload T1-T3,T5-T6 (T4 blocked)"
```
**Report**: Completed 5/6, Blocked 1 (T4: AWS creds), Failed 0

---

### Example 2: Refactor with Parallel Tasks
**Plan**: Extract shared validation library
```markdown
## Plan: shared-validation
Tasks:
  T1: Create lib/validation (schemas, types) (depends: none)
  T2: Migrate auth validators → lib (depends: T1)
  T3: Migrate api validators → lib (depends: T1)
  T4: Migrate cli validators → lib (depends: T1)
  T5: Update imports across codebase (depends: T2,T3,T4)
  T6: Run full test suite (depends: T5)
```
**Execution** (parallel T2/T3/T4 after T1):
```
git checkout -b plan/shared-validation
git commit -am "baseline: pre-shared-validation"
→ T1: create lib, types, tests ✅
→ T2,T3,T4: parallel migrate (3 terminals or async) ✅✅✅
→ T5: bulk import update, run lint ✅
→ T6: full suite, run `npm test` ✅
git commit -am "refactor: shared validation lib"
```
**Report**: Completed 6/6, Blocked 0, Failed 0

---

### Example 3: Plan with Rollback Triggered
**Plan**: Migrate from REST to GraphQL for user queries
```markdown
## Plan: graphql-migration
Tasks:
  T1: Add GraphQL schema (User, Query) (depends: none)
  T2: Implement resolvers (depends: T1)
  T3: Add DataLoader for N+1 (depends: T2)
  T4: Add Apollo Server + middleware (depends: T3)
  T5: Deprecate REST /api/users (depends: T4)
  T6: Load test (depends: T5)
```
**Execution**:
```
→ T1: schema ✅
→ T2: resolvers ✅
→ T3: DataLoader ✅
→ T4: Apollo Server, run `npm test` ❌ (schema validation error)
   → rollback T4, mark BLOCKED
→ T5: skipped (blocked on T4)
→ T6: skipped (blocked on T5)
→ Report to orchestrator: 2 consecutive failures? No, only 1.
   Fix T4 locally, re-run T4 ✅
→ T5: deprecate REST ✅
→ T6: load test ✅
```
**Report**: Completed 5/6, Blocked 0, Failed 1 (T4 resolved)

---

### Example 4: Cross-Language Plan (Go + TS)
**Plan**: Add gRPC service for payments
```markdown
## Plan: grpc-payments
Tasks:
  T1: Protobuf definition (shared) (depends: none)
  T2: Go server impl (depends: T1)
  T3: TS client stubs (depends: T1)
  T4: Go unit tests (depends: T2)
  T5: TS integration tests (depends: T3)
  T6: Contract test (buf breaking) (depends: T1)
```
**Execution**:
```
git checkout -b plan/grpc-payments
→ T1: proto/payment.proto, `buf lint` ✅
→ T2: Go server, `go test ./...` ✅
→ T3: `buf generate` TS stubs, `npm run build` ✅
→ T4: Go tests ✅
→ T5: TS tests ❌ (mock mismatch)
   → rollback T5, mark BLOCKED
→ T6: `buf breaking` ✅
→ Fix T5, re-run ✅
```
**Report**: Completed 5/6, Blocked 1 (resolved), Failed 0

---

### Example 5: Plan from SDD Spec (Spec-Driven)
**Plan**: Generated from `sdd-init` → `sdd-spec` → `sdd-design`
```markdown
## Plan: SPEC-042-user-preferences
Tasks (from tasks.json):
  T1: Database migration (preferences table) [P0]
  T2: PreferenceService CRUD [P0]
  T3: GET/PUT /api/preferences endpoints [P0]
  T4: React PreferencePanel component [P1]
  T5: Unit tests (service + endpoints) [P0]
  T6: E2E test (full flow) [P1]
```
**Execution**:
```
git checkout -b plan/spec-042
→ T1: migration, `npm test` ✅
→ T2: service, `npm test` ✅
→ T3: endpoints, `npm test` ✅
→ T4: component, `npm test` ❌ (snapshot mismatch)
   → rollback T4, mark BLOCKED
→ T5: unit tests ✅
→ T6: skipped (blocked on T4)
→ Fix T4 snapshot, re-run ✅
→ T6: e2e ✅
```
**Report**: Completed 6/6, Blocked 0, Failed 1 (resolved)

---

## TESTING PATTERNS

### Pattern 1: Gate-Per-Task (Unit + Lint + Typecheck)
```bash
# After EACH task implementation:
npm test -- --testPathPattern="<task-files>"   # targeted unit tests
npm run lint -- <task-files>                   # lint only changed
npx tsc --noEmit --project <task-files>        # typecheck only changed
```
Use when: TypeScript/JS projects, fast feedback needed.

---

### Pattern 2: Full-Suite Gate (End of Plan)
```bash
# After ALL tasks complete:
npm test                                       # full unit suite
npm run lint                                   # full lint
npx tsc --noEmit                               # full typecheck
npm run build                                  # production build
```
Use when: CI gate, release preparation, cross-task dependencies.

---

### Pattern 3: Contract + Integration Gate (API/Service)
```bash
# For API/service plans:
npm run test:contract   # pact / schemathesis / buf breaking
npm run test:integration  # testcontainers / localstack
npm run test:e2e          # playwright / cypress
```
Use when: External contracts, schema evolution, multi-service.

---

## EDGE CASES

### Edge Case 1: Plan File Missing or Corrupt
**Symptom**: `plan.json` not found / invalid JSON / missing required fields
**Resolution**:
1. Search for alternatives: `find . -name "plan*" -o -name "tasks*" -o -name "TODO*"`
2. If none → STOP, ask orchestrator: "No valid plan found. Provide plan or confirm ad-hoc execution."
3. If ad-hoc confirmed → create minimal plan in memory, proceed with isolation.

---

### Edge Case 2: Git Unavailable (No Repo / No Permissions)
**Symptom**: `git checkout -b` fails / not a git repo / permission denied
**Resolution**:
1. Skip branch creation. Use temp dir for isolation: `mkdir -p .plan-exec-backup && cp -r src .plan-exec-backup/`
2. Rollback = `rm -rf src && cp -r .plan-exec-backup/src .`
3. Report in output: `Branch: N/A (no git), Backup: .plan-exec-backup/`

---

### Edge Case 3: Task Depends on External Resource (DB, API, Secrets)
**Symptom**: Task verification fails due to missing DB / API key / service
**Resolution**:
1. Mark task BLOCKED (not FAILED) — `Reason: external dependency unavailable`
2. Document required resource in notes: `Needs: POSTGRES_DSN, AWS_S3_BUCKET`
3. Continue unblocked tasks. Report blocked count.
4. Orchestrator decides: provide resource / mock / defer.

---

### Edge Case 4: Cascading Failure (One Task Breaks Multiple Downstream)
**Symptom**: T3 fails → T4,T5,T6 all blocked (depend on T3)
**Resolution**:
1. Rollback T3 only. Mark T3 FAILED.
2. Mark T4,T5,T6 BLOCKED (reason: upstream failure).
3. If T3 fixable in <5min → fix, re-verify, unblock downstream.
4. If not → STOP (2 consecutive failures if T3 fix fails), report to orchestrator with blast radius.

---

## ANTI-PATTERNS

### Anti-Pattern 1: "Verify at the End Only"
**What**: Skip per-task verification, run full suite once at the end.
**Why it fails**: 
- Defects compound — fix cost grows exponentially
- Rollback scope becomes entire plan (can't isolate)
- Blocked tasks indistinguishable from failed
- No early signal to orchestrator

**Correct**: Verify EVERY task (Pattern 1). Full suite at end (Pattern 2) is ADDITIONAL.

---

### Anti-Pattern 2: "Continue Past Failure Limit"
**What**: 3rd failure → "just one more task" / "it's minor" / ignore STOP rule.
**Why it fails**:
- PlanExecution protocol exists to protect system integrity
- 3 failures = systemic issue (env, plan, understanding)
- Continuing masks root cause, produces unstable state
- Orchestrator loses trust in agent reliability

**Correct**: At 3 total OR 2 consecutive → IMMEDIATE STOP. Report to orchestrator with:
- Failed tasks + error output
- Blocked tasks + reasons
- Current branch state
- Hypothesis for root cause

## Externalized Sections (ADR-007 compression)
## VERIFICATION GATES (auto-detect language)
| If present | Run |
|------------|-----|
| package.json | `npm test` / `npm run lint` / `npx tsc --noEmit` |
| pyproject.toml / setup.py | `pytest` / `flake8` / `mypy` |
| go.mod | `go test ./...` / `golangci-lint run` |
| Cargo.toml | `cargo test` / `cargo clippy` |
| pom.xml / build.gradle | `mvn test` / `gradle test` |
| Makefile | `make test` (if target exists) |

Single task timeout: 5 min. If exceeded → escalate.


