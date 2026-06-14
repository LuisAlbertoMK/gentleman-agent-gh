---
name: accessibility
description: Audit and improve web accessibility following WCAG 2.2 guidelines. Use when asked to "improve accessibility", "a11y audit", "WCAG compliance", "screen reader support", "keyboard navigation", or "make accessible".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.2"
---

# Accessibility (a11y)

Audit checklist basado en WCAG 2.2. Para ejemplos completos, ver [`references/`](references/).

## WCAG Principles: POUR

| Principle | Description |
|-----------|-------------|
| **P**erceivable | Content can be perceived through different senses |
| **O**perable | Interface can be operated by all users |
| **U**nderstandable | Content and interface are understandable |
| **R**obust | Content works with assistive technologies |

## Conformance levels

| Level | Requirement |
|-------|-------------|
| **A** | Minimum — must pass |
| **AA** | Standard — legal req. in many jurisdictions |
| **AAA** | Enhanced — nice to have |

---

## Perceivable

### Text alternatives (1.1.1)
- Every `<img>` needs `alt` (decorative → `alt=""` + `role="presentation"`)
- Icon buttons need `aria-label` or visually-hidden text
- Complex images use `aria-describedby` linking to description
- See [A11Y-PATTERNS.md](references/A11Y-PATTERNS.md) for full patterns

### Color contrast (1.4.3 AA, 1.4.6 AAA)
| Text Size | AA | AAA |
|-----------|----|------|
| Normal (<18px / <14px bold) | 4.5:1 | 7:1 |
| Large (≥18px / ≥14px bold) | 3:1 | 4.5:1 |
| UI components & graphics | 3:1 | 3:1 |
- Focus states need ≥3:1 against background (1.4.11)
- Don't rely on color alone — add icon/text indicator (1.4.1)

### Media alternatives (1.2)
- Video: captions (1.2.2) + audio description (1.2.3/1.2.5)
- Audio: transcript
- Live: captions (1.2.4 AA)
- See [A11Y-PATTERNS.md](references/A11Y-PATTERNS.md)

---

## Operable

### Keyboard accessible (2.1.1)
- All functionality via keyboard. Prefer native `<button>`, `<a href>`, form controls
- `<div onclick>` → needs `role="button"` + `tabindex="0"` + keydown handler
- No keyboard traps (2.1.2) — native `<dialog>` handles focus trap
- See [modal focus trap](references/A11Y-PATTERNS.md#modal-focus-trap)

### Focus visible (2.4.7) + Focus not obscured (2.4.11 AA, 2.4.12 AAA)
- Never `outline: none` without `:focus-visible` replacement
- Use `:focus-visible` for keyboard-only focus indicators
- Focused element must not be hidden by sticky headers. Use `scroll-margin`:
  ```css
  :focus { scroll-margin-top: 80px; }
  ```

### Skip links (2.4.1)
- "Skip to main content" link as first focusable element
- See [skip link pattern](references/A11Y-PATTERNS.md#skip-link)

### Target size (2.5.8 AA) — new in 2.2
- Interactive targets ≥24×24 CSS px. Exceptions: inline text, browser-controlled, non-overlapping
- Recommended: 44×44px for touch

### Dragging movements (2.5.7 AA) — new in 2.2
- Drag actions need single-pointer alternative (buttons)
- See [dragging pattern](references/A11Y-PATTERNS.md#dragging-movements)

### Timing (2.2.1, 2.2.2)
- Time limits: allow extend or turn off
- Auto-updating content (carousels, sliders): pause on focus/hover, provide pause button

### Motion (2.3)
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Understandable

### Page language (3.1.1)
- `<html lang="...">` required. Mark language changes with `<span lang="...">`

### Consistent navigation (3.2.3) + Consistent help (3.2.6 AA)
- Navigation and help mechanisms in same relative order across pages

### Form labels (3.3.2) + Error handling (3.3.1, 3.3.3)
- Every input needs `<label for="id">` or `aria-label`
- Errors: `aria-invalid="true"`, `aria-describedby="error-id"`, `role="alert"`
- Focus first error on submit
- See [form labels](references/A11Y-PATTERNS.md#form-labels) and [error handling](references/A11Y-PATTERNS.md#error-handling) patterns

### Redundant entry (3.3.7 A) — new in 2.2
- Auto-populate previously entered data. Exceptions: security re-confirmation, expired content

### Accessible authentication (3.3.8 AA) — new in 2.2
- No cognitive function test (password recall, puzzle) unless: copy-paste/autofill available, alternative method (passkey, SSO, email link), or object recognition

---

## Robust

### ARIA usage (4.1.2)
- **Prefer native elements** before ARIA roles. Native `<button>` > `<div role="button">`
- Use semantic HTML5: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`
- See [ARIA tabs pattern](references/A11Y-PATTERNS.md#aria-tabs)

### Live regions (4.1.3)
- Dynamic content: `aria-live="polite"` for status, `role="alert"` for errors
- See [live regions pattern](references/A11Y-PATTERNS.md#live-regions-and-notifications)

---

## Testing checklist

### Automated
```bash
npx lighthouse https://example.com --only-categories=accessibility
npx @axe-core/cli https://example.com
```

### Manual
- [ ] **Keyboard:** Tab through page, Enter/Space to activate, no traps
- [ ] **Screen reader:** VoiceOver (Mac), NVDA (Windows), TalkBack (Android)
- [ ] **Zoom:** Usable at 200%
- [ ] **High contrast:** Windows High Contrast Mode
- [ ] **Reduced motion:** `prefers-reduced-motion: reduce`
- [ ] **Focus order:** Logical, follows visual order
- [ ] **Target size:** ≥24×24px interactive elements
- See [screen reader commands](references/A11Y-PATTERNS.md#screen-reader-commands)

---

## Common issues by impact

### Critical (fix immediately)
1. Missing form labels
2. Missing image alt text
3. Insufficient color contrast
4. Keyboard traps
5. No focus indicators

### Serious (fix before launch)
1. Missing page language
2. Missing heading structure
3. Non-descriptive link text
4. Auto-playing media
5. Missing skip links

### Moderate (fix soon)
1. Missing ARIA labels on icons
2. Inconsistent navigation
3. Missing error identification
4. Timing without controls
5. Missing landmark regions

## References

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [Deque axe Rules](https://dequeuniversity.com/rules/axe/)
- [Web Quality Audit](../web-quality-audit/SKILL.md)
- [WCAG criteria reference](references/WCAG.md)
- [Accessibility code patterns](references/A11Y-PATTERNS.md)
