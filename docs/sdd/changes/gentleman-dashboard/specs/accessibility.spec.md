# SDD Delta Spec: gentleman-dashboard — Accessibility (a11y)

## ADDED Requirements

### Requirement: Semantic landmarks
The dashboard HTML MUST use semantic landmarks:
- `<header>` for page title
- `<main>` for primary content (cards + table)
- `<section aria-labelledby="gate-heading">` for Gate card
- `<section aria-labelledby="fast-heading">` for Fast card
- `<section aria-labelledby="agents-heading">` for Agents card
- `<section aria-labelledby="skills-heading">` for Skills card + table
- `<footer>` optional for generatedAt timestamp

Each card section MUST have an `<h2 id="...-heading">` referenced by `aria-labelledby`.

### Requirement: Color contrast ≥ 4.5:1
All text and interactive elements MUST meet WCAG 2.2 AA contrast ratio (≥4.5:1 for normal text, ≥3:1 for large text ≥18pt/14pt bold).
OKLCH dark theme colors MUST be validated against this ratio.
Focus indicators MUST have ≥3:1 contrast against adjacent colors.

### Requirement: Keyboard focus visible
All interactive elements (sortable table headers) MUST have visible focus styles:
- `outline: 2px solid` with OKLCH accent color
- `outline-offset: 2px`
- No `outline: none` or `outline: 0` without replacement

Tab order MUST follow visual order: cards top-to-bottom, then table headers left-to-right.

### Requirement: ARIA for sortable table
Table headers with sorting MUST have:
- `role="columnheader"`
- `aria-sort="none|ascending|descending"` updated on click
- `tabindex="0"` for keyboard activation
- `aria-label` describing sort action (e.g., "Sort by Delta, currently descending, press to reverse")

### Requirement: Live region for fetch error
The error message container MUST have `role="alert"` or `aria-live="assertive"` so screen readers announce fetch failures immediately.

## Scenarios

### Scenario: Happy path — semantic structure validated
Given the dashboard renders
When inspected with accessibility tree
Then landmarks header, main, section×4 present
And each section has aria-labelledby matching h2 id
And no landmark is empty

### Scenario: Happy path — contrast passes
Given OKLCH dark theme colors defined in CSS
When measured with axe-core or similar
Then all text contrast ≥4.5:1
And focus indicators ≥3:1

### Scenario: Happy path — keyboard navigation
Given user tabs through page
When focus reaches table headers
Then each header shows visible focus outline
And pressing Enter/Space toggles sort
And aria-sort updates accordingly

### Scenario: Edge case — reduced motion
Given `prefers-reduced-motion: reduce`
When dashboard loads
Then no animations/transitions play (CSS respects media query)

### Scenario: Error case — fetch error announced
Given fetch fails
When error message appears
Then screen reader announces "Failed to load dashboard data. Run generator script." immediately (aria-live)

### Scenario: Error case — zoom 200%
Given browser zoom at 200%
When dashboard renders
Then no horizontal overflow on viewport ≥320px
And all content readable without horizontal scroll