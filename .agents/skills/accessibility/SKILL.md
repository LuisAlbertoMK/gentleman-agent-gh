---
name: accessibility
description: "WCAG 2.2 + EAA 2025 — audit and improve web accessibility."
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation, EAA, European Accessibility Act, contrast, focus, touch target"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1700
---

## When to Use
WCAG 2.2 + EAA 2025 — audit and improve web accessibility.

## Theme-Switching Contrast: Hero buttons on gradients → .hero .btn override (--clr-accent drops below 3:1 on dark). Footer spans on dark bg → --clr-white or test each theme. Verify getComputedStyle contrast ≥4.5:1 against bg AND text per theme.
## Grid A11y: NEVER grid-auto-flow: dense on interactive (breaks DOM tab flow). Preserve source order · TEST keyboard tab through every responsive variant.
## Cross-Refs: baseline-ui | web-quality-audit | ui-engine
**Standards**: WCAG 2.2 (w3.org/TR/WCAG22) · EAA (digital-strategy.ec.europa.eu) · WAI-ARIA (w3.org/TR/wai-aria) · axe (deque.com/axe)
## Output
`A11Y-AUDIT:<url>—<date> CRITICAL:[wcag\|color\|keyboard]<issue>→<fix> HIGH:[contrast\|focus\|alt]<issue>→<fix> MEDIUM:[aria\|label\|nav]<issue>→<fix> VERIFY:[axe\|keyboard]→PASS/FAIL`

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced

---

> See [reference.md](docs/skills/accessibility/reference.md) for extended details, examples, and detailed patterns.
