# Task Template

```markdown
## Phase {N}: {name}
**Estimate:** ~{N} files | ~{N} lines added | ~{N} modified

### Task {N}.{M}: {title}
- **Description:** {what needs to be done}
- **Files:** {list of files}
- **Verify:** {how to confirm it works}
- **Deps:** {phase/task it depends on}
```

## Workload Forecast Example
| Phase | Files | Lines Added | Lines Modified |
|-------|-------|-------------|----------------|
| 1: Foundation | 3 | 120 | 0 |
| 2: Core | 5 | 250 | 40 |
| 3: Integration | 4 | 180 | 60 |
| 4: Testing | 2 | 80 | 10 |
| 5: Cleanup | 1 | 15 | 20 |
| **Total** | **15** | **645** | **130** |

> Total >400 lines → `Chained PRs recommended: Yes`
> Split: Phase 1-2 (PR 1), Phase 3-5 (PR 2)
