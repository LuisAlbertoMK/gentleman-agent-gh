---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, responsive, container query, flexbox, grid"
license: MIT
metadata:
  tags: [frontend, ui, design, responsive, layout]
  author: gentleman-vMK (adapted from ibelick/ui-skills)
  version: "2.1"
  changelog: "2.1: Karpathy re-compressed (3.7→3.0KB) · 2.0: prior pass (7.0→3.9KB)"
---
<!-- karpathy-compressed: 2026-07-09 -->
# Baseline UI — Anti-slop v2.1

## Stack
Use existing CSS/Tailwind defaults · `cn()` (clsx+tailwind-merge) for React classes · No new CSS approach unless project uses it.

## Layout
`h-dvh` not `h-screen` · Respect `safe-area-inset` · Fixed `z-index` scale · `size-*` over `w-*`+`h-*` for squares.

## Responsive
- **Components**: container queries (`container-type: inline-size`) · **Page**: media queries only
- `container-type: size` ❌ without `block-size`
- `repeat(auto-fit, minmax(280px, 1fr))` for cards · `cqi` for fluid type · Named containers when nested · Subgrid for sibling alignment · `aspect-ratio` for CLS
- ❌ `grid-auto-flow: dense` on interactive (breaks tab order)

**Decision tree**: 1D→Flexbox · 2D→Grid · Parent tracks→Subgrid · Unknown count→`repeat(auto-fit, minmax())` · Context adapt→Container queries.

## Typography
`text-balance` headings · `text-pretty` body · `tabular-nums` data · Fluid type: `clamp(1rem, 1.5cqi+0.5rem, 1.5rem)` · CQ units for components, `vw` hero type only · No `letter-spacing` unless requested.

## Animation
- **Purpose-only**: state change, feedback, attention, continuity. Never decorative.
- **Props**: only `transform` + `opacity`. Never `width`, `height`, `top`, `left`, `margin`, `padding`.
- **Easing tokens**: `--ease-out: cubic-bezier(0,0,0.2,1)` · `--ease-in: cubic-bezier(0.4,0,1,1)` · `--ease-standard: cubic-bezier(0.4,0,0.2,1)`
- **Duration tokens**: fast 120ms, base 200ms, slow 300ms. **Never >500ms**. Motion budget: initial viewport <800ms total.
- **Scroll reveals**: CSS Scroll-Driven Animations (`animation-timeline: view()`) — off main thread, 0 INP. Pause loops off-screen via `content-visibility: auto`.
- **Reduced motion**:
```css
@media (prefers-reduced-motion: reduce) { *,*::before,*::after { animation-duration:0.01ms!important; transition-duration:0.01ms!important; } }
```
- CSS transitions for state, WAAPI imperative, View Transitions pages, `@starting-style` entering DOM.

## Design Tokens
- **OKLCH**: `oklch(55% 0.18 255)` — perceptually uniform, replaces HSL
- **8pt spacing**: 8/16/24/32/48/64 (4px icons ok)
- **3-tier**: Primitive→Semantic→Component
- `light-dark()` for dark mode: `color: light-dark(#1a1a1a, #f5f5f5)`
- **4.5:1 contrast** on all text tokens across all themes.

## Design
No gradients/multicolor unless requested · No glow as primary affordance · Empty states: 1 clear action · Accent limit: 1 per view.

## Interaction
Errors next to action · Accessible primitives for keyboard/focus · `aria-label` icon-only buttons · No blocking paste · No rebuilding keyboard behavior.

## Review Output
When invoked as `/baseline-ui <file>`: 1. Violation (exact snippet) 2. Why it matters 3. Fix (code)

## Refs
ui-engine · accessibility · performance · web-quality-audit
