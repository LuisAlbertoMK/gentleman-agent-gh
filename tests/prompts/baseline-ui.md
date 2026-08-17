# baseline-ui — golden prompt

**Trigger**: "ui slop", "ui cleanup", "polish ui"

```
This component is UI slop. It uses max-w-md fixed width, transition:all .6s, and color:#666.
Clean it up to match our anti-slop baseline: proper responsive grid, OKLCH tokens, reduced-motion.
Apply the baseline-ui patterns and report CRITICAL/HIGH/MEDIUM findings with fixes.
```

**Expected**: `UI-CLEANUP:<file>—<date> CRITICAL:[a11y|contrast]<issue>→<fix> HIGH:[layout|responsive]<issue>→<fix> MEDIUM:[tokens|anim]<issue>→<fix> VERIFY:[a11y|perf]→<pass/fail>`
