# commit-crafter - Reference Materials

> **Externalized from** .agents/skills/commit-crafter/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Examples
```bash
git diff --cached --stat
feat(api): add user search endpoint   # fuzzy match + pagination; Resolves #142
fix(auth): handle nil token on refresh # root cause: omitted nil check after decode; +integration test
refactor(db): extract query builder   # moves 340 lines store.go→sqlbuilder; tests pass
perf(cache): reduce TTL lookups by 60% # 2.3ms/op→0.9ms/op (benchstat p<0.01)
feat(config)!: switch to env-only credentials # BREAKING CHANGE: .credentials.json no longer read
```


## Edge Cases
| Edge Case | Handling |
|---|---|
| Mixed-type diff | Split per type; never combine `feat` + `fix` |
| No scope match | Parent directory name; root → no scope |
| Empty body | OK for trivial; required for `feat`/`fix`/`perf` |
| Breaking in non-feat | `fix!`/`refactor!` valid; always add `BREAKING CHANGE:` footer |


