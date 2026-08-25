# accessibility golden prompt

## Skill
accessibility (WCAG 2.2 + EAA 2025: color, keyboard, alt, aria, labels, nav)

## Trigger
accessibility, a11y, wcag, contrast, alt text, keyboard, aria

## Input
A11y audit https://form.ejemplo.com: missing alt text, broken focus trap, color contrast 2.8:1 on form fields.

## Expected Output
A11Y-AUDIT:https://form.ejemplo.com--2026-08-21 CRITICAL:[wcag]<issue>-><fix> HIGH:[contrast|focus]<issue>-><fix> MEDIUM:[alt|aria]<issue>-><fix> VERIFY:[axe|keyboard]->PASS

## Assertion
- Response matches A11Y-AUDIT:<url>--<date> CRITICAL/HIGH/MEDIUM:<cat><issue>-><fix> contract
- Catches: missing alt text, contrast below 4.5:1, focus trap failure, aria-label missing
- Within token_budget 1700
