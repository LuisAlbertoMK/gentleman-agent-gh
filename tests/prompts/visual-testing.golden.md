# visual-testing golden prompt

## Skill
visual-testing (Playwright visual regression, screenshot diff, baseline management)

## Trigger
visual testing, screenshot, visual regression, playwight, vrt, diff

## Input
Visual regression test header component at viewports 375, 768, 1024, 1440 versus baseline; detect pixel diff.

## Expected Output
VRT:header.spec--2026-08-21 RESULT:fail DIFF:0.03 BASELINE:updated VIEWPORTS:[375/768/1024/1440]

## Assertion
- Response matches VRT:<spec>--<date> RESULT:<pass|fail> DIFF:<pixel-ratio> VIEWPORTS:[...] contract
- Catches: pixel diff above threshold, missing viewport coverage, baseline drift
- Within token_budget 2200
