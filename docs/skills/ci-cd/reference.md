# ci-cd - Reference Materials

> **Externalized from** .agents/skills/ci-cd/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Testing Patterns
- **Matrix coverage**: `git diff --name-only HEAD~1 | xargs -I{} dirname {} | wc -l` — verify changed dirs in matrix
- **Gate dry-run**: `./scripts/quality-gate.ps1; if ($LASTEXITCODE) { "GATE BLOCKED" }` — local CI gate test
- **Spec coverage**: `ls .sdd/specs/*/*.feature 2>$null | wc -l` — fail if zero specs


## Examples
- **Quality gate (pre-push)**: `./scripts/quality-gate.ps1 --exit-on-fail` — secrets, commit format, cross-ref
- **Coverage threshold**: `go test -coverprofile=c.out && go tool cover -func=c.out | grep total`


## Edge Cases
No tests→skip "No test files—skip"(not fail)|Monorepo→detect per dir;fallback"no runner"|SDD missing specs dir→skip coverage check|skip_tests→lint+quality only|Matrix partial→"api/windows:PASS|web/linux:FAIL|..."|No go.mod/pkg.json→"Run `project-mapper` first"|Timeout→"Check deadlocks"—use--timeout 5m|Coverage below→"Coverage X%<threshold Y%"|Runner offline→"Check status/fallback to ubuntu-latest"|Branch protection→"PR merge blocked—requires CI pass"


