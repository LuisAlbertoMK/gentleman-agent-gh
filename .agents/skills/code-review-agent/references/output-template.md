# Output Template

```
## CR: {file/summary}

### 4R Assessment
| R | Score | Verdict | Key Issue |
|---|-------|---------|-----------|
| Risk | 8/10 | 🟢 | None critical |
| Readability | 5/10 | 🟡 | Cyclo >15 in processOrder() |
| Reliability | 4/10 | 🔴 | No retry on upstream call |
| Resilience | 7/10 | 🟢 | Circuit breaker present |

**4R Score**: X.X/10
**Verdict**: ✅ APPROVED / 🔶 CHANGES REQUESTED / ❌ REJECTED

### Dimension Drill-down (evidence for each R)
| Dimension | Score | 4R Mapping | Issues |
|-----------|-------|------------|--------|
| Correctness | 7/10 | Risk | Edge case: empty order list |
| Architecture | 6/10 | Resilience | Handler >300 lines, no isolation |
| Performance | 8/10 | Reliability | OK |
| Security | 9/10 | Risk | OK |
| Readability | 5/10 | Readability | Cyclo >15 |
| Testability | 7/10 | Risk | Hard to mock upstream |

### Fixes
1. `file.go:line` — fix description (what + why)
2. `file.go:line` — fix description

### Evidence
- `go test ./...` — N/N pass
- `go vet ./...` — no warnings

### Meta
- Reviewed by: {model} via code-review-agent v2.0
- Diffs reviewed: {N} files, {N-N} lines
- Per-R checklist: verified before scoring
- Verifiable rules: R01-R07, RD01-RD07, RL01-RL07, RS01-RS07
```
