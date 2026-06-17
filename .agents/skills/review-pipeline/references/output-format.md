# Output Format

```
## Pipeline: review-pipeline

### Phase 0: Review Profile ✅
- Project: {name}
- Previous 4R score: {score}/10
- Focus R: {R} (most common failure)
- Sensitive files: {file1}, {file2}

### Phase 1: Quality Gate ✅ / ❌
- Tests: X/X pass | Secrets: clean / BLOCKED | PSSA: pass / fail
→ Result: PASS / FAIL

### Phase 2: 4R Code Review ✅ / ❌
| R | Score | Verdict |
|---|-------|---------|
| Risk | X/10 | 🟢 |
| Readability | X/10 | 🟡 |
| Reliability | X/10 | 🔴 |
| Resilience | X/10 | 🟢 |
→ Result: PASS / FAIL ({lowest R} = {score})

### Phase 3: Commit Message ✅
{conventional commit message}

### Summary
Pipeline: ✅ ALL CLEAR / ❌ BLOCKED at Phase {N}
Duration: {phases completed}/{total phases}
```
