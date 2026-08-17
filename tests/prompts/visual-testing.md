# visual-testing — golden prompt

**Trigger**: "visual diff", "VRT", "regression test", "layout shift"

```
Run a visual regression check on the header component: the nav overflows at 375px after the last change.
Use Playwright toHaveScreenshot at 375/768/1440, compare against the golden snapshot,
report DIFF regions with viewport info, and gate on unexpected layout shifts.
```

**Expected**: `VRT:<page>—<date> PASSED/FAILED:<n> DIFF:<region> VIEWPORTS:[375/768/1024/1440] VERIFY:[playwright|golden]→<pass/fail>`
