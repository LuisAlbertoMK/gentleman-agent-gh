---
name: accessibility
description: "WCAG 2.2 + EAA 2025 — audit and improve web accessibility."
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation, EAA, European Accessibility Act, contrast, focus, touch target"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
WCAG 2.2 + EAA 2025 — audit and improve web accessibility.


## POUR — Perceivable | Operable | Understandable | Robust
**Perceivable**: 1.1.1 img→alt (deco→lt="", icon→ria-label, complex→ria-describedby) · 1.4.3/1.4.6 Contrast: normal 4.5:1(AA)/7:1(AAA), large 3:1(AA)/4.5:1(AAA), UI/focus 3:1 · 1.2 Media: captions+desc
**Operable**: 2.1.1 Keyboard: prefer native · **2.4.13 Focus**: min 2px solid outline+outline-offset:2px on :focus-visible, never outline:none · 2.4.1 Skip links → #main-content · **2.5.8 AA Targets**: ≥24×24px, **enhanced 44×44px** touch-first · 2.5.7 Dragging: single-pointer alt · 2.3 Motion: @media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:0.01ms!important;transition-duration:0.01ms!important}}
**Understandable**: 3.1.1 html lang · 3.3 Forms: each input→label/aria-label, errors→ria-invalid+ria-describedby+ole="alert" · 3.3.8 Auth: no cognitive test unless copy-paste/autofill/SSO
**Robust**: 4.1.2 Prefer native semantic HTML · 4.1.3 Dynamic→ria-live="polite", errors→ole="alert"
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
## REFS: [WCAG 2.2](https://www.w3.org/TR/WCAG22/) · [EAA](https://digital-strategy.ec.europa.eu/en/policies/european-accessibility-act) · [WAI-ARIA](https://www.w3.org/TR/wai-aria/) · [axe](https://www.deque.com/axe/) · baseline-ui · web-quality-audit · ui-engine

---

## Actionable Examples (4-5)

### 1. axe-core Automated Audit (CI + Local)
`ash
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
`ash
# NVDA (Windows) - Test checklist
1. Install NVDA + speech viewer (Tools → Speech Viewer)
2. Navigate: Tab / Shift+Tab / Arrow keys / H (headings) / K (links)
3. Verify: landmarks announced, form labels read, errors in ole="alert", dynamic updates via ria-live

# VoiceOver (macOS/iOS)
# Cmd+F5 to start → Control+Option+Arrow to navigate
# rotor (Control+Option+U) for landmarks/headings/links
`

### 4. Focus Trap Modal (Reusable Pattern)
`	ypescript
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

## Testing Patterns (3)

### 1. Color Contrast — Automated + Manual
- **Automated**: axe-core color-contrast rule + custom per-theme script above
- **Manual**: Verify getComputedStyle contrast in **every theme** (light/dark/high-contrast) for: text, UI borders, focus rings, disabled states
- **Threshold**: AA = 4.5:1 (normal), 3:1 (large/UI); AAA = 7:1 / 4.5:1

### 2. ARIA & Semantic Structure — Lint + Screen Reader
- **Lint**: slint-plugin-jsx-a11y + xe-core (rules: ria-*, ole, scope, landmark)
- **Screen reader**: NVDA/VoiceOver walk-through — verify landmark announcements, form label association, live region behavior
- **Check**: No duplicate IDs, ria-describedby points to existing element, ria-live not overused

### 3. Keyboard Navigation — Tab Flow + Focus Visible
- **Automated**: Playwright page.keyboard.press('Tab') loop → screenshot each focus state
- **Manual**: Tab through entire page — every interactive reachable, focus order matches visual, :focus-visible ring visible (2px solid + 2px offset)
- **Regression**: Test every responsive breakpoint (mobile/tablet/desktop) — grid reorder must not break tab order

---

## Edge Cases (4)

### 1. When NOT to Use ARIA
- **Native HTML exists**: <button> not <div role="button">, <nav> not <div role="navigation">
- **Over-engineering**: Simple links/buttons need no ARIA — native semantics win
- **Rule**: ARIA is a **last resort** when native cannot express the pattern (e.g., complex tree, custom slider)

### 2. Cognitive Disabilities (WCAG 2.2 3.3.8 + 2.3.3)
- **Auth**: No puzzle CAPTCHAs — allow copy-paste, autofill, WebAuthn/passkeys, magic links
- **Timeouts**: Extendable (ria-live warning + extend button) — no auto-logout without notice
- **Language**: Simple, consistent terminology; avoid jargon; provide glossary for complex flows

### 3. Dynamic Content & Live Regions
- **Polite vs Assertive**: ria-live="polite" for updates (toast, cart count); ole="alert" (assertive) for errors only
- **Atomic updates**: Wrap changed region in ria-atomic="true" to prevent full re-read
- **Race conditions**: Debounce rapid updates — batch into single announcement

### 4. Internationalization & RTL
- **lang attribute**: html lang="es-AR" + per-section lang changes
- **RTL focus order**: Logical (DOM) order must match visual RTL — test keyboard tab in RTL mode
- **Number/date formats**: Screen readers announce per locale — test with NVDA Spanish, VoiceOver Arabic
- **Font scaling**: Support em + @media (prefers-reduced-motion) — no fixed px on text containers

---

## Anti-Patterns (2) — STOP Doing These

### ❌ 1. outline: none / outline: 0 Without Focus-Visible Replacement
`css
/* NEVER */
button:focus { outline: none; }

/* ALWAYS — visible focus for keyboard users */
button:focus-visible { outline: 2px solid var(--clr-focus); outline-offset: 2px; }
button:focus:not(:focus-visible) { outline: none; } /* mouse click = no ring */
`

### ❌ 2. grid-auto-flow: dense on Interactive Grids
`css
/* NEVER — breaks DOM tab order (WCAG 2.4.3) */
.grid { display: grid; grid-auto-flow: dense; }

/* ALWAYS — preserve source order */
.grid { display: grid; }
/* If reordering needed: use order ONLY on non-interactive items, or restructure DOM */
`

---

## Quick Reference Card

| Check | Tool/Method | Pass Criteria |
|-------|-------------|---------------|
| Contrast (all themes) | axe + getComputedStyle script | ≥4.5:1 text, ≥3:1 UI/focus |
| Focus visible | Keyboard tab + :focus-visible CSS | 2px solid + 2px offset on all interactive |
| Touch targets | DevTools element inspector | ≥44×44px (24×24px dense only) |
| ARIA validity | eslint-plugin-jsx-a11y + axe | Zero violations |
| Screen reader | NVDA/VoiceOver walk-through | Landmarks, labels, live regions announced |
| Keyboard order | Tab through all breakpoints | DOM order = visual order |
| Reduced motion | @media (prefers-reduced-motion) | Animations disabled/near-zero |
| Language | html lang + section lang | Matches content language |
