# work-unit-commits — Reference Materials

> **Externalized from** .agents/skills/work-unit-commits/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains worked examples, verification steps, and SDD detail.

## Split Examples
| Weak | Better |
|---|---|
| `add models` | `feat(auth): add token validation model + tests` |
| `add services` | `feat(auth): wire token validation into login flow` |
| `add tests` | Included with each behavior commit |
| `update docs` | Included with the user-facing change |

## Examples
"split commit" → `git diff --stat` (6 files, 340 lines <400 → no chain) → `git add src/auth/token-validation.ts tests/auth/token-validation.test.ts` → `git commit -m "feat(auth): add token validation model + tests"` → 1. token validation model+tests ✓ 2. wire into login flow ✓ 3. document login flow ✓ — each = candidate chained PR slice.

## Testing
1. Unit size guard: `git diff --stat HEAD~1..HEAD` ≤400 lines. 2. Tests with code: `git show --stat HEAD` → test file in same commit. 3. Message tells outcome: `git log --oneline -5` → outcome-style, not file-type lists.

## SDD Relationship
From `sdd-tasks` Review Workload Forecast: **Low**→one PR | **Medium**→commit by unit, monitor lines | **High**→follow `delivery_strategy` (ask on `ask-on-risk`, auto-slice on `auto-chain`, require `size:exception` on `single-pr`, record accepted on `exception-ok`). Each work unit maps to commit/PR: clear start → clear finish → verification in same unit → rollback without removing unrelated work.