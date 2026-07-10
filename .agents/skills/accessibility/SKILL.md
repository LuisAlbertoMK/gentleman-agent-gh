---
name: accessibility
description: "WCAG 2.2 + EAA 2025 — audit and improve web accessibility."
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation, EAA, European Accessibility Act, contrast, focus, touch target"
license: MIT
metadata:
  tags: [accessibility]
  author: web-quality-skills + gentleman-vMK
  version: "2.0"
  changelog: "2.0: EAA 2025, touch 44×44px, focus 2px, theme-switch contrast, Karpathy compressed (5.5→3.0KB)"
---
<!-- karpathy-compressed: 2026-07-09 -->
## POUR — Perceivable | Operable | Understandable | Robust
**Perceivable**: 1.1.1 img→alt (deco→`alt=""`, icon→`aria-label`, complex→`aria-describedby`) · 1.4.3/1.4.6 Contrast: normal 4.5:1(AA)/7:1(AAA), large 3:1(AA)/4.5:1(AAA), UI/focus 3:1 · 1.2 Media: captions+desc
**Operable**: 2.1.1 Keyboard: prefer native · **2.4.13 Focus**: min 2px solid `outline`+`outline-offset:2px` on `:focus-visible`, never `outline:none` · 2.4.1 Skip links → `#main-content` · **2.5.8 AA Targets**: ≥24×24px, **enhanced 44×44px** touch-first · 2.5.7 Dragging: single-pointer alt · 2.3 Motion: `@media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:0.01ms!important;transition-duration:0.01ms!important}}`
**Understandable**: 3.1.1 `html lang` · 3.3 Forms: each input→label/aria-label, errors→`aria-invalid`+`aria-describedby`+`role="alert"` · 3.3.8 Auth: no cognitive test unless copy-paste/autofill/SSO
**Robust**: 4.1.2 Prefer native semantic HTML · 4.1.3 Dynamic→`aria-live="polite"`, errors→`role="alert"`
## EAA 2025 (June 2025)
- All EU-market web products: WCAG 2.2 AA minimum
- **Every theme** independently tested for contrast
- **Focus visible** in ALL themes · **Reduced motion** mandatory
```css
:focus-visible { outline: 2px solid var(--clr-focus, Highlight); outline-offset: 2px; }
```
## Touch Targets
| Context | Minimum | Enhanced (rec) |
|---|---|---|
| WCAG 2.5.8 AA | 24×24px | — |
| Touch-first | — | **44×44px** |
`min-width`+`min-height` (not padding) · 44px default, 24px fallback for dense tables ONLY
## Theme-Switching Contrast: Hero buttons on gradients → `.hero .btn` override (`--clr-accent` drops below 3:1 on dark). Footer spans on dark bg → `--clr-white` or test each theme. Verify `getComputedStyle` contrast ≥4.5:1 against bg AND text per theme.
## Grid A11y: NEVER `grid-auto-flow: dense` on interactive (breaks DOM tab flow). Preserve source order · TEST keyboard tab through every responsive variant.
## REFS: [WCAG 2.2](https://www.w3.org/TR/WCAG22/) · [EAA](https://digital-strategy.ec.europa.eu/en/policies/european-accessibility-act) · [WAI-ARIA](https://www.w3.org/TR/wai-aria/) · [axe](https://www.deque.com/axe/) · baseline-ui · web-quality-audit · ui-engine
