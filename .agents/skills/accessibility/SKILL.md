---
name: accessibility
description: "WCAG 2.2 + EAA 2025 — audit and improve web accessibility."
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation, EAA, European Accessibility Act, contrast, focus, touch target"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2431
---

## When to Use
WCAG 2.2 + EAA 2025 — audit and improve web accessibility.


## POUR — Perceivable | Operable | Understandable | Robust
**Perceivable**: 1.1.1 img→alt (deco→alt="", icon→aria-label, complex→aria-describedby) · 1.4.3/1.4.6 Contrast: normal 4.5:1(AA)/7:1(AAA), large 3:1(AA)/4.5:1(AAA), UI/focus 3:1 · 1.2 Media: captions+desc
**Operable**: 2.1.1 Keyboard: prefer native · **2.4.13 Focus**: min 2px solid outline+outline-offset:2px on :focus-visible, never outline:none · 2.4.1 Skip links → #main-content · **2.5.8 AA Targets**: ≥24×24px, **enhanced 44×44px** touch-first · 2.5.7 Dragging: single-pointer alt · 2.3 Motion: @media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:0.01ms!important;transition-duration:0.01ms!important}}
**Understandable**: 3.1.1 html lang · 3.3 Forms: each input→label/aria-label, errors→aria-invalid+aria-describedby+role="alert" · 3.3.8 Auth: no cognitive test unless copy-paste/autofill/SSO
**Robust**: 4.1.2 Prefer native semantic HTML · 4.1.3 Dynamic→aria-live="polite", errors→role="alert"
## EAA 2025 (June 2025)
- All EU-market web products: WCAG 2.2 AA minimum
- **Every theme** independently tested for contrast
- **Focus visible** in ALL themes · **Reduced motion** mandatory
`css
:focus-visible { outline: 2px solid var(--clr-focus, Highlight); outline-offset: 2px; }
`
## Touch Targets
| Context | Minimum | Enhanced (rec) |
|---|---|---|
| WCAG 2.5.8 AA | 24×24px | — |
| Touch-first | — | **44×44px** |
min-width+min-height (not padding) · 44px default, 24px fallback for dense tables ONLY
## Theme-Switching Contrast: Hero buttons on gradients → .hero .btn override (--clr-accent drops below 3:1 on dark). Footer spans on dark bg → --clr-white or test each theme. Verify getComputedStyle contrast ≥4.5:1 against bg AND text per theme.
## Grid A11y: NEVER grid-auto-flow: dense on interactive (breaks DOM tab flow). Preserve source order · TEST keyboard tab through every responsive variant.
## Cross-Refs: baseline-ui | web-quality-audit | ui-engine
**Standards**: WCAG 2.2 (w3.org/TR/WCAG22) · EAA (digital-strategy.ec.europa.eu) · WAI-ARIA (w3.org/TR/wai-aria) · axe (deque.com/axe)
---

## Actionable Examples (4-5)

### 1. axe-core Automated Audit (CI + Local)
`bash
# Install
npm i -D @axe-core/playwright @axe-core/cli

# Run in Playwright test
import { injectAxe, checkA11y } from '@axe-core/playwright';
await injectAxe(page);
await checkA11y(page, undefined, { detailedReport: true, verbose: true });

# CLI audit (headless)
npx axe https://example.com --save --dir ./a11y-results
`

### 2. Color Contrast Verification (Per-Theme)
`javascript
// Contrast check utility (WCAG 2.2 1.4.3/1.4.6)
function getContrastRatio(fg, bg) {
  const lum = c => { const s = c/255; return s <= 0.03928 ? s/12.92 : Math.pow((s+0.055)/1.055, 2.4); };
  const L1 = 0.2126*lum(fg.r) + 0.7152*lum(fg.g) + 0.0722*lum(fg.b);
  const L2 = 0.2126*lum(bg.r) + 0.7152*lum(bg.g) + 0.0722*lum(bg.b);
  return (Math.max(L1,L2)+0.05)/(Math.min(L1,L2)+0.05);
}

// Usage per theme
const styles = getComputedStyle(document.querySelector('.hero .btn'));
const fg = parseColor(styles.color);
const bg = parseColor(styles.backgroundColor);
console.log(getContrastRatio(fg, bg)); // Must be ≥4.5:1 (AA) / ≥7:1 (AAA)
`

### 3. Screen Reader Testing Protocol (NVDA/VoiceOver)
`bash
# NVDA (Windows) - Test checklist
1. Install NVDA + speech viewer (Tools → Speech Viewer)
2. Navigate: Tab / Shift+Tab / Arrow keys / H (headings) / K (links)
3. Verify: landmarks announced, form labels read, errors in role="alert", dynamic updates via aria-live

# VoiceOver (macOS/iOS)
# Cmd+F5 to start → Control+Option+Arrow to navigate
# rotor (Control+Option+U) for landmarks/headings/links
`

### 4. Focus Trap Modal (Reusable Pattern)
`typescript
// focus-trap.ts — minimal, no deps
export function trapFocus(element: HTMLElement): () => void {
  const focusables = element.querySelectorAll<HTMLElement>(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusables[0];
  const last = focusables[focusables.length - 1];
  
  function handler(e: KeyboardEvent) {
    if (e.key !== 'Tab') return;
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
  element.addEventListener('keydown', handler);
  first?.focus();
  return () => element.removeEventListener('keydown', handler);
}
`

### 5. Skip Link + Landmark Pattern
`html
<!-- First focusable element -->
<a href="#main-content" class="skip-link">Skip to main content</a>

<!-- Landmarks (native preferred) -->
<header role="banner">…</header>
<nav role="navigation" aria-label="Primary">…</nav>
<main id="main-content" role="main">…</main>
<aside role="complementary" aria-label="Sidebar">…</aside>
<footer role="contentinfo">…</footer>

<style>
.skip-link { position: absolute; top: -100%; left: 0; padding: 0.5rem 1rem; background: var(--clr-focus); }
.skip-link:focus { top: 0; z-index: 9999; }
</style>
`

---
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/accessibility/reference.md

---
