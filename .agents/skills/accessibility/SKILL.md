---
name: accessibility
description: Audit and improve web accessibility following WCAG 2.2 guidelines. Use when asked to "improve accessibility", "a11y audit", "WCAG compliance", "screen reader support", "keyboard navigation", or "make accessible".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.2"
---

# Accessibility (a11y)

Audit checklist basado en WCAG 2.2. Ejemplos completos en [`references/`](references/).

## POUR + Levels
**P**erceivable · **O**perable · **U**nderstandable · **R**obust
Levels: A (min), AA (standard), AAA (enhanced)

---

## Perceivable
**1.1.1 Text alternatives**: `<img>` needs `alt`. Decorative → `alt="" role="presentation"`. Icon buttons → `aria-label`. Complex → `aria-describedby`.

**1.4.3/1.4.6 Color contrast**: Normal text ≥4.5:1 (AA) / 7:1 (AAA). Large (≥18px/≥14px bold) ≥3:1 (AA) / 4.5:1 (AAA). UI ≥3:1. Focus ≥3:1 vs bg (1.4.11). Don't rely on color alone — add icon/text (1.4.1).

**1.2 Media**: Video → captions (1.2.2) + audio description (1.2.3/1.2.5). Audio → transcript. Live → captions (1.2.4 AA).

---

## Operable
**2.1.1 Keyboard**: Prefer native `<button>`, `<a href>`, form controls. `<div onclick>` → `role="button" tabindex="0"` + keydown. No keyboard traps (2.1.2).

**2.4.7 Focus**: Never `outline:none` without `:focus-visible`. Sticky headers → `scroll-margin-top`.

**2.4.1 Skip links**: First focusable element, targets `#main-content`.

**2.5.8 AA Target size** (new in 2.2): ≥24×24 CSS px. Recommended 44×44 for touch.

**2.5.7 AA Dragging** (new in 2.2): Single-pointer alternative (buttons).

**2.2 Timing**: Time limits → allow extend/off. Auto-updating content → pause on hover/focus + button.

**2.3 Motion**:
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
**3.1.1 Language**: `<html lang="...">`. Mark changes with `<span lang="...">`.

**3.2.3/3.2.6 AA**: Navigation + help in same relative order across pages.

**3.3.2/3.3.1/3.3.3 Forms**: Every input → `<label for="id">` or `aria-label`. Errors → `aria-invalid="true" aria-describedby="error-id" role="alert"`. Focus first error on submit.

**3.3.7 A Redundant entry** (new in 2.2): Auto-populate previously entered data.

**3.3.8 AA Auth** (new in 2.2): No cognitive function test unless copy-paste/autofill available, alternative method (passkey, SSO, email link), or object recognition.

---

## Robust
**4.1.2 ARIA**: Prefer native elements. Semantic HTML5: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`.

**4.1.3 Live regions**: Dynamic content → `aria-live="polite"`. Errors → `role="alert"`.

---

## Testing
**Automated**: `npx lighthouse <url> --only-categories=accessibility` · `npx @axe-core/cli <url>`
**Manual**: Keyboard tab · Screen reader (VoiceOver/NVDA/TalkBack) · 200% zoom · High contrast · Reduced motion · Focus order · ≥24×24px targets

## Common issues
**Critical**: Missing form labels / alt / contrast · Keyboard traps · No focus indicators
**Serious**: Missing page lang / headings / skip links · Non-descriptive link text
**Moderate**: Missing ARIA on icons · Inconsistent nav · Missing error ID · Timing controls

## References
- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [Deque axe Rules](https://dequeuniversity.com/rules/axe/)
- [WCAG criteria reference](references/WCAG.md)
- [Accessibility code patterns](references/A11Y-PATTERNS.md)
