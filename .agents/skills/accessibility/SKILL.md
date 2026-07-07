---
name: accessibility
description: "Audit and improve web accessibility following WCAG 2.2 guidelines."
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation"
license: MIT
metadata:
  tags: [accessibility]
  author: web-quality-skills
  version: "1.2"
---
## POUR: Perceivable | Operable | Understandable | Robust
**Perceivable**: 1.1.1 img→alt (deco→`alt="" role="presentation"`, icon→`aria-label`, complex→`aria-describedby`) · 1.4.3/1.4.6 Contrast: normal ≥4.5:1(AA)/7:1(AAA), large ≥3:1(AA)/4.5:1(AAA), UI/focus ≥3:1 · 1.2 Media: video→captions+desc, audio→transcript, live→captions(AA)
**Operable**: 2.1.1 Keyboard: prefer native, `div onclick`→`role="button" tabindex="0"`+keydown · 2.4.7 Focus: never `outline:none` w/o `:focus-visible` · 2.4.1 Skip links: first focusable→`#main-content` · 2.5.8 AA Targets: ≥24×24px, rec 44×44 touch · 2.5.7 AA Dragging: single-pointer alt · 2.2 Timing: extend/off, auto→pause · 2.3 Motion: `@media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:0.01ms!important;transition-duration:0.01ms!important}}`
**Understandable**: 3.1.1 `html lang="..."` · 3.2.3/3.2.6 Nav+help same order · 3.3.2/3.3.1/3.3.3 Forms: each input→label/`aria-label`, errors→`aria-invalid`+`aria-describedby`+`role="alert"`, focus first · 3.3.7 Redundant entry: auto-populate · 3.3.8 Auth: no cognitive test unless copy-paste/autofill/SSO
**Robust**: 4.1.2 Prefer native, semantic HTML5 · 4.1.3 Dynamic→`aria-live="polite"`, errors→`role="alert"`
## TESTING: `npx lighthouse --only-categories=accessibility` · `npx @axe-core/cli` · Keyboard tab · Screen reader · 200% zoom · High contrast · Reduced motion · Focus order · ≥24×24 targets
## COMMON ISSUES: Critical→labels/alt/contrast/keyboard traps/no focus || Serious→lang/headings/skip links/non-descriptive links || Moderate→ARIA on icons/inconsistent nav/missing error ID/timing
## REFS: WCAG 2.2 | WAI-ARIA | Deque axe
