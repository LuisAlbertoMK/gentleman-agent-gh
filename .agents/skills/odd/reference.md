# ODD Reference

## Task Plan Template — `odd/tasks/<feature>.md`

```markdown
# <Feature Name>

## Intent
[One sentence: what behavior this delivers]

## Scope In
- Item 1
- Item 2

## Scope Out
- Item A (not in this feature)
- Item B

## Slice Plan
| # | Scope | Est. Lines | Preset | Commit |
|---|-------|-----------|--------|--------|
| 1 | <scope> | ~N | P3 | `feat(<scope>): ...` |
| 2 | <scope> | ~N | P3 | `feat(<scope>): ...` |

Total est. lines: ~N

## Verification
- [ ] Slice 1 tests pass
- [ ] Slice 2 tests pass
- [ ] Repo works after each commit independently
- [ ] `git diff --stat` per slice ≤400L (≤800L docs-only)

## Review Log
| Date | Slice | Reviewer | Notes |
|------|-------|----------|-------|
| — | — | — | — |

## Rollback
Each slice commits independently. `git revert <commit-hash>` per slice.
```

## SMALL vs SUBSTANTIAL Examples

### SMALL (direct — no task plan needed)
```
Feature: Fix typo in README.md
Scope In: 1 file, <10 lines, no deps
Gate: ≤50L ✓, 1 file ✓, no schema ✓, no deps ✓, tier 0 ✓, ≤2 commits ✓
→ Direct: commit fix + test if applicable
```

### SMALL (direct)
```
Feature: Add env var to .env.example
Scope In: 1 file, ~5 lines, no deps
Gate: ≤50L ✓, 1 file ✓, no schema ✓, no deps ✓, tier 0 ✓, ≤2 commits ✓
→ Direct: commit add var
```

### SUBSTANTIAL (task plan required)
```
Feature: Add user profile page with avatar upload
Scope In: 3 files, ~200L, new dep (sharp for resize)
Gate: >50L ✗ OR >1 file ✗ OR new deps ✗
→ Create odd/tasks/user-profile.md with slice plan:
  Slice 1: Profile component (~80L) — P3
  Slice 2: Avatar upload endpoint (~100L) — P3
  Slice 3: Sharp resize integration (~40L) — P3
```

### SUBSTANTIAL (task plan required)
```
Feature: Migrate auth from sessions to JWT
Scope In: 4 files, ~300L, schema change, API change
Gate: >50L ✗, >1 file ✗, schema ✗, API ✗
→ Create odd/tasks/auth-jwt.md with slice plan
```

## Presets Detail

| Preset | Phase | Agent | Fallback | When to Use |
|--------|-------|-------|----------|-------------|
| P1 | Propose | analysis agent | vMK | Scope unclear, need research |
| P2 | Slice plan | implementation agent | quick | Break feature into slices |
| P3 | Implement | implementation agent | codex | Write code per slice |
| P4 | Verify | quality agent | deep | Tests, lint, type check |
| P5 | Review | review agent | vMK | Code review per slice |

> Agent names are abstract — route through `opencode-model-router` for actual model selection.

## ODD vs SDD Boundary

| Concern | SDD | ODD |
|---------|-----|-----|
| **What** | Spec-driven: defines requirements, scenarios, edge cases | Slice-driven: defines work units, commit boundaries |
| **When to use** | Registry needed, multi-phase design, cross-cutting concerns | Single feature, known scope, ≤day delivery |
| **Output** | `sdd/registry/{change-id}/` phase files | `odd/tasks/<feature>.md` + commits |
| **Risk handling** | Phases catch risk early (explore, propose, design) | Gate catches risk upfront (SMALL vs SUBSTANTIAL) |
| **Review** | End-of-phase gates | Per-slice review log |
| **Commits** | After apply+verify phase | 1 per slice, during implementation |

### Decision Tree
```
Is this a registry-level concern (schema, auth, API, cross-service)?
  YES → sdd (or sdd-quick for ≤3 files)
  NO  → Is scope ≤50L (or ≤150L docs-only), 1 file, no deps, tier 0, ≤2 commits?
    YES → ODD SMALL (direct)
    NO  → ODD SUBSTANTIAL (task plan + slice plan)
```

### Can They Combine?
Yes. Use SDD for the spec/design phase, then ODD for implementation slices:
1. SDD propose → defines what/why
2. ODD slice plan → defines how/commits
3. ODD implement → commits per slice with review
