---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, responsive, container query, flexbox, grid, ui audit"
license: MIT
metadata:
  tags: [frontend, ui, design, responsive, layout]
  author: gentleman-vMK (adapted from ibelick/ui-skills)
  version: "3.1"
  changelog: "3.1: Breaker fixes — cqi→vw for page-level, content-visibility corrected, React-only disclaimer, letter-spacing exception. 3.0: Added workflow, examples"
---
<!-- karpathy-compressed: 2026-07-10 -->
# Baseline UI — Anti-slop

**Stack**: Existing CSS/Tailwind · `cn()` (clsx+tailwind-merge) React · No new approach unless project uses
**Scope**: Audit & cleanup patterns. For implementation reference, load **ui-engine** after this skill.

## Workflow
1. **Scan**: Read target files → identify violations (❌ rules below)
2. **Classify**: Layout? Typography? Animation? Tokens? Interaction?
3. **Fix**: Apply patterns from sections below
4. **Verify**: Check contrast, responsive, motion preferences
5. **Chain**: accessibility (focus/A11y) → performance (animation budget)

## Layout + Responsive
`h-dvh` not `h-screen` · `safe-area-inset` · Fixed z-index · `size-*` over `w-*`+`h-*`.
- **Components**: container queries (`container-type: inline-size`) · **Page**: media queries only
- `container-type: size` ❌ without `block-size` · `grid-auto-flow: dense` ❌ interactive
- Cards: `repeat(auto-fit, minmax(280px, 1fr))` · Fluid: `cqi` (ONLY inside containers) · Named containers · Subgrid · `aspect-ratio`
- **Tree**: 1D→Flexbox · 2D→Grid · Child inherits parent tracks→Subgrid · Parent→:has() · Unknown→`auto-fit, minmax()` · Adapt→CQ

### Before/After
```css
/* ❌ Before: fixed width, no responsive */
.card { width: 300px; height: 200px; }

/* ✅ After: fluid grid, container query */
.card { container-type: inline-size; }
.card-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; }
```

## Typography
`text-balance` headings · `text-pretty` body · `tabular-nums` data · Fluid: page-level use `vw` (e.g. `clamp(1rem, 1.5vw+0.5rem, 1.5rem)`), containers use `cqi` · CQ components · No `letter-spacing` except uppercase labels/small-caps/tracking adjustments.

### Before/After
```css
/* ❌ Before: fixed font size */
h1 { font-size: 2rem; }

/* ✅ After: fluid, balanced */
h1 { font-size: clamp(1.5rem, 3vw+0.5rem, 2.5rem); text-wrap: balance; }
```

## Animation
- **Purpose**: state/feedback/attention/continuity
- **Props**: `transform`+`opacity` only. Never `width/height/top/left/margin/padding`.
- **Easing**: `--ease-out: cubic-bezier(0,0,0.2,1)` · `--ease-in: cubic-bezier(0.4,0,1,1)` · `--ease-standard: cubic-bezier(0.4,0,0.2,1)`
- **Duration**: fast 120ms, base 200ms, slow 300ms. **Never >500ms**. Per-element total <200ms.
- **Scroll**: CSS Scroll-Driven (`animation-timeline: view()`) 0 INP.
- **Reduced motion**: `animation/transition-duration: 0.01ms !important` on `*` at `prefers-reduced-motion: reduce`.
- CSS transitions, WAAPI, View Transitions, `@starting-style`.

### Before/After
```css
/* ❌ Before: animating layout properties */
.card { transition: width 0.3s ease; }
.card:hover { width: 320px; }

/* ✅ After: compositor-only */
.card { transition: transform 0.2s var(--ease-out); }
.card:hover { transform: scale(1.02); }
```

## Tokens
OKLCH `oklch(55% 0.18 255)` · 8pt 8/16/24/32/48/64 (4px ok) · 3-tier Primitive→Semantic→Component · `light-dark()` · **4.5:1 contrast** all text all themes.

## Design + Interaction
No gradients/multicolor · No glow primary · Empty state: 1 primary action · Accent color: 1 per view.
Errors next to action · Accessible keyboard/focus · `aria-label` icons · No blocking paste.

## Review
`/baseline-ui <file>` → Violation → Why → Fix

## Cross-References
- **ui-engine** → implementation patterns, decision tree, CSS reference (load FIRST)
- **accessibility** → focus management, contrast, ARIA, EAA compliance
- **performance** → animation budget, content-visibility, compositor
- **web-quality-audit** → full audit checklist, CI/CD integration

## Anti-Patterns
Fixed width · h-screen · grid-auto-flow:dense interactive · Fixed font-size · transition:all · >500ms animation · Missing reduced-motion · HSL/RGB tokens · No contrast check · cqi outside container · letter-spacing on body text
