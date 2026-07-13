# Refactoring Strategy Reference

## Strangler Fig Pattern
Replace incrementally: route calls to new code → validate → remove old.
```
[Old API] → 50% traffic to new, 50% old
          → 100% to new, old still running
          → Remove old code
```

## Test Baseline Requirements
| Coverage | Action |
|----------|--------|
| < 40% | Write tests first, then refactor |
| 40-70% | Add tests for the specific section you're changing |
| > 70% | Proceed with refactor, verify existing tests pass |

## Step Types by Risk

| Type | Risk | Verification |
|------|------|-------------|
| Extract function | Low | Existing tests pass |
| Rename/move | Low-Med | Tests + no import errors |
| Change signature | Med | Tests + integration |
| Split module | High | All tests + no regression |
| Merge modules | High | All tests + perf check |
