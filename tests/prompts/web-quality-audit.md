# web-quality-audit — golden prompt

**Trigger**: "audit", "lighthouse", "web audit"

```
Audit https://staging.example.com (pre-deploy). Target is running and publicly reachable.
Compare scores against thresholds (LCP<2500ms, CLS<0.1, INP<200ms, contrast≥4.5:1, touch≥24×24),
bucket findings by CRITICAL/HIGH/MEDIUM/LOW, and block if any Critical/High exists.
```

**Expected**: `AUDIT:<url>—<date> Scores:Perf=<n>A11y=<n>BP=<n>SEO=<n> CRITICAL:[cat]<issue>→<fix> HIGH:... MEDIUM:...`
