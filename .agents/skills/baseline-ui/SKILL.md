---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, responsive, container query, flexbox, grid, ui audit"
---

## When to Use
Anti-slop UI — layout, typography, responsive, animation, to

**Stack**: Existing CSS/Tailwind·`cn()`(clsx+tailwind-merge) React·No new approach unless project uses
**Scope**: Audit&cleanup. For implementation→load **ui-engine** after.

## Workflow
1.Scan targets→violations(❌) 2.Classify 3.Fix 4.Verify:contrast/responsive/motion 5.Chain:a11y→perf

## Layout
`h-dvh`not`h-screen`·`safe-area-inset`·`size-*`over`w-*`+`h-*`·Components:CQ(`container-type:inline-size`)·Page:MQ
❌`container-type:size`w/o`block-size`·❌`grid-auto-flow:dense`interactive
Cards:`repeat(auto-fit,minmax(280px,1fr))`·Fluid:`cqi`(ONLY containers)·Subgrid·`aspect-ratio`
Tree:1D→Flex|2D→Grid|Child→Subgrid|Parent→:has()|Unknown→auto-fit,minmax()
```css
/* ❌ */.card{width:300px;height:200px}
/* ✅ */.card-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}
.card{container-type:inline-size}
```

## Typography
`text-balance`headings·`text-pretty`body·`tabular-nums`data·Fluid:page→`clamp(1rem,1.5vw+0.5rem,1.5rem)`, containers→`cqi`. No`letter-spacing`except labels
```css
/* ❌ */h1{font-size:2rem} /* ✅ */h1{font-size:clamp(1.5rem,3vw+0.5rem,2.5rem);text-wrap:balance}
```

## Animation(audit only—see ui-engine)
Props:`transform`+`opacity`✅. ❌`width/height/top/left/margin/padding`. Duration:120/200/300ms. ❌>500ms. <200ms/element.
Reduced:`animation/transition-duration:0.01ms!important`on`*`at`prefers-reduced-motion:reduce`
❌`transition:all`·✅Scroll-Driven CSS

## Tokens
❌HSL/RGB→✅OKLCH·8pt·3-tier(Prim→Sem→Comp)·`light-dark()`·≥4.5:1 all text all themes

## Design
No gradients/multicolor·No glow·Empty:1primary·Accent:1/view·Errors next to action·Keyboard/focus·`aria-label`icons·No blocking paste

## Review: `/baseline-ui <file>`→Violation→Why→Fix

## Refs
**ui-engine**(implementation)**accessibility**(focus/ARIA/EAA)**performance**(budget/CV)**web-quality-audit**(full audit)

## Anti-Patterns
Fixed width·h-screen·grid-auto-flow:dense interactive·Fixed font-size·transition:all·>500ms·No reduced-motion·HSL/RGB·No contrast·cqi outside container·letter-spacing body
