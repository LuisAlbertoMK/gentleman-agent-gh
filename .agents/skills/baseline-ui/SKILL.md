---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, responsive, container query, flexbox, grid, ui audit"
license: MIT
metadata:
  tags: [frontend, ui, design, responsive, layout]
  author: gentleman-vMK (adapted from ibelick/ui-skills)
  version: "3.0"
  changelog: "3.0: Added workflow, examples, cross-references. 2.3: Karpathy re-compressed"
---
<!-- karpathy-compressed: 2026-07-10 -->
# Baseline UI — Anti-slop

**Stack**: Existing CSS/Tailwind · `cn()` (clsx+tailwind-merge) React · No new approach unless project uses

## Workflow
1. **Scan**: Read target files → identify violations (❌ rules below)
2. **Classify**: Layout? Typography? Animation? Tokens? Interaction?
3. **Fix**: Apply patterns from sections below
4. **Verify**: Check contrast, responsive, motion preferences
5. **Chain**: accessibility (focus/A11y) → performance (animation budget) → ui-engine (implementation)

## Layout + Responsive
`h-dvh` not `h-screen` · `safe-area-inset` · Fixed z-index · `size-*` over `w-*`+`h-*`.
- **Components**: container queries (`container-type: inline-size`) · **Page**: media queries only
- `container-type: size` ❌ without `block-size` · `grid-auto-flow: dense` ❌ interactive
- Cards: `repeat(auto-fit, minmax(280px, 1fr))` · Fluid: `cqi` · Named containers · Subgrid · `aspect-ratio`
- **Tree**: 1D→Flexbox · 2D→Grid · Parent→Subgrid · Unknown→`auto-fit, minmax()` · Adapt→CQ

### Before/After
```css
/* ❌ Before: fixed width, no responsive */
.card { width: 300px; height: 200px; }

/* ✅ After: fluid grid, container query */
.card { container-type: inline-size; }
.card-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; }
```

## Typography
`text-balance` headings · `text-pretty` body · `tabular-nums` data · Fluid: `clamp(1rem, 1.5cqi+0.5rem, 1.5rem)` · CQ components, `vw` hero · No `letter-spacing`.

### Before/After
```css
/* ❌ Before: fixed font size */
h1 { font-size: 2rem; }

/* ✅ After: fluid, balanced */
h1 { font-size: clamp(1.5rem, 3cqi+0.5rem, 2.5rem); text-wrap: balance; }
```

## Animation
- **Purpose**: state/feedback/attention/continuity
- **Props**: `transform`+`opacity` only. Never `width/height/top/left/margin/padding`.
- **Easing**: `--ease-out: cubic-bezier(0,0,0.2,1)` · `--ease-in: cubic-bezier(0.4,0,1,1)` · `--ease-standard: cubic-bezier(0.4,0,0.2,1)`
- **Duration**: fast 120ms, base 200ms, slow 300ms. **Never >500ms**. Viewport <800ms.
- **Scroll**: CSS Scroll-Driven (`animation-timeline: view()`) 0 INP. Pause via `content-visibility: auto`.
- **Reduced motion**: `animation/transition-duration: 0.01ms !important` on `*` at `prefers-reduced-motion: reduce`.
- CSS transitions, WAAPI, View Transitions, `@starting-style`.

## Tokens
OKLCH `oklch(55% 0.18 255)` · 8pt 8/16/24/32/48/64 (4px ok) · 3-tier Primitive→Semantic→Component · `light-dark()` · **4.5:1 contrast** all text all themes.

## Design + Interaction
No gradients/multicolor · No glow primary · Empty: 1 action · Accent: 1/view.
Errors next to action · Accessible keyboard/focus · `aria-label` icons · No blocking paste.

## Review
`/baseline-ui <file>` → Violation → Why → Fix

## Cross-References
- **ui-engine** → implementation patterns, decision tree, CSS reference
- **accessibility** → focus management, contrast, ARIA, EAA compliance
- **performance** → animation budget, content-visibility, compositor
- **web-quality-audit** → full audit checklist, CI/CD integration

## Anti-Patterns
Fixed width · h-screen · grid-auto-flow:dense interactive · Fixed font-size · transition:all · >500ms animation · Missing reduced-motion · HSL/RGB tokens · No contrast check
