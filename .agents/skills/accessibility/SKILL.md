---
name: accessibility
description: Audit and improve web accessibility following WCAG 2.2 guidelines.
triggers: "a11y, accessibility, WCAG, screen reader, keyboard navigation"
license: MIT
metadata:
  tags:
    - accessibility
  author: web-quality-skills
  version: "1.2"
---
# Accessibility — WCAG 2.2 audit checklist
## POUR: Perceivable | Operable | Understandable | Robust. Levels: A/AA/AAA
## Perceivable
1.1.1 Text: img needs alt. Decorative -> alt="" role="presentation". Icon -> aria-label. Complex -> aria-describedby.
1.4.3/1.4.6 Contrast: Normal >=4.5:1(AA)/7:1(AAA). Large >=3:1(AA)/4.5:1(AAA). UI >=3:1. Focus >=3:1. Not color alone.
1.2 Media: Video->captions+description. Audio->transcript. Live->captions(1.2.4 AA).
## Operable
2.1.1 Keyboard: Prefer native button/a/form. div onclick->role="button" tabindex="0"+keydown. No traps.
2.4.7 Focus: Never outline:none w/o :focus-visible. Sticky headers->scroll-margin-top.
2.4.1 Skip links: First focusable->#main-content.
2.5.8 AA Targets(new 2.2): >=24x24 CSS px. Recommend 44x44 touch.
2.5.7 AA Dragging(new 2.2): Single-pointer alternative.
2.2 Timing: Time limits->extend/off. Auto-updating->pause.
2.3 Motion: @media (prefers-reduced-motion: reduce) { *,*::before,*::after { animation-duration:0.01ms!important; transition-duration:0.01ms!important; } }
## Understandable
3.1.1 Language: html lang="...". Changes->span lang="...".
3.2.3/3.2.6 AA: Nav+help same order across pages.
3.3.2/3.3.1/3.3.3 Forms: Each input->label/aria-label. Errors->aria-invalid+aria-describedby+role="alert". Focus first error.
3.3.7 A Redundant entry(new 2.2): Auto-populate previous data.
3.3.8 AA Auth(new 2.2): No cognitive test unless copy-paste/autofill/SSO available.
## Robust
4.1.2 ARIA: Prefer native. Semantic HTML5: header/nav/main/section/article.
4.1.3 Live regions: Dynamic->aria-live="polite". Errors->role="alert".
## Testing
Automated: npx lighthouse --only-categories=accessibility | npx @axe-core/cli
Manual: Keyboard tab | Screen reader | 200% zoom | High contrast | Reduced motion | Focus order | >=24x24 targets
## Common Issues
Critical: Missing labels/alt/contrast | Keyboard traps | No focus indicators
Serious: Missing lang/headings/skip links | Non-descriptive links
Moderate: Missing ARIA on icons | Inconsistent nav | Missing error ID | Timing controls
## Refs: WCAG 2.2 | WAI-ARIA | Deque axe | references/WCAG.md | references/A11Y-PATTERNS.md