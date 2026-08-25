# accessibility — golden prompt

**Trigger**: "a11y", "WCAG", "EAA", "keyboard navigation"

```
The checkout form fails WCAG 2.2 (EAA compliance). Audit and fix: contrast ≥4.5:1 (theme-aware),
label/aria-label on every input, errors in role="alert" with aria-invalid + aria-describedby,
keyboard focus visible (2px ring), no cognitive CAPTCHA, reduced-motion support.
Verify with axe, NVDA, and tab-order walkthrough.
```

**Expected**: `A11Y-AUDIT:<page>—<date> CRITICAL:[wcag-2.x]<violation>→<fix> HIGH:... MEDIUM:... VERIFY:[axe|nvda|tab]→<pass/fail>`
