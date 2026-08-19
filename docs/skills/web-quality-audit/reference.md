# Web Quality Audit — Reference

## Examples

### Example 1: Pre-Deploy Audit of Staging

**Trigger**: `web audit https://staging.example.com` (frontmatter: audit, web audit, lighthouse, page quality)

```bash
# Workflow step 1: Setup (site scan)
npx unlighthouse --site https://staging.example.com --reporter json > audit.json
```

**Expected output** (Output format, severity-ordered):

```
AUDIT:https://staging.example.com—2026-08-16 Scores:Perf=92 A11y=88 BP=95 SEO=97
CRITICAL:[a11y] contrast 3.1:1 → --text:oklch(0.2 0 0) (≥4.5:1)
HIGH:[perf] LCP=3100ms → <link rel=preload as=image href=hero.webp fetchpriority=high>
MEDIUM:[seo] title 42 chars → 50-60
```

**Result**: CRITICAL/HIGH block pre-deploy (CI/CD gate); targets Perf≥90 A11y=100 BP≥95 SEO≥95.

## Testing

1. **Audit produced** — `npx unlighthouse --site <url> --reporter json`:
   Expected: `audit.json` exists and contains per-category scores.

2. **Threshold compare** — parse scores against the Thresholds table (LCP<2500ms, CLS<0.1, INP<200ms, contrast≥4.5:1):
   ```powershell
   (Get-Content audit.json -Raw | ConvertFrom-Json).categories.performance.score -ge 0.9
   ```
   Expected: `True` (Perf ≥90 target) or a documented fail→fix from Remediation.

3. **Severity buckets** — report lists CRITICAL/HIGH/MEDIUM/LOW; a passing pre-deploy gate shows 0 CRITICAL + 0 HIGH:
   Expected: gate blocks on any CRITICAL/HIGH (CI/CD section).