# performance — golden prompt

**Trigger**: "performance", "INP", "speed up", "load time"

```
The page's INP is 300ms and LCP is 3.1s. Profile and fix: compare against budget
(LCP<2500ms, INP<200ms, CLS<0.1, TBT<200ms), identify root causes (long tasks, blocking resources,
large hero image), apply fixes (scheduler.yield(), preload hero with fetchpriority=high, code-split),
and verify with lhci or the test suite.
```

**Expected**: `PERF:<page>—<date> BUDGET:[LCP|INP|CLS|TBT]vs→PASS/FAIL FIX:<fix> VERIFY:[lhci|test]→<pass/fail>`
