# performance-tracker — golden prompt

**Trigger**: "performance score", "perf tracking", "benchmark"

```
Score our Android app across the 6 dimensions (Load, Render, Memory, Network, Bundle, Energy).
Measure real data (dumpsys meminfo, lighthouse, apk size), assign 1-10 per the table,
save to mem_search with platform in the title (perf-score:myapp-android), and report the trend
(prev 5 vs recent 5; drop >0.5 = regression).
```

**Expected**: `PERF-SCORE:<app>—<date> DIMS:[Load|Render|Memory|Network|Bundle|Energy]=<1-10> AVG=<n.n> PLATFORM:<mob|desk|web> TREND:<delta>→<stable|drift|regression>`
