---
name: ui-engine
description: "Complete UI system — layout (Grid/Flexbox/@layer/:has()), responsive (MQ/CQ), animation (compositor-only, scroll-driven, View Transitions), design tokens (8pt system, fluid type, dark mode)"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, easing, scroll animation"
license: MIT
metadata:
  tags: [frontend, ui, css, architecture]
  author: gentleman-vMK
  version: "5.0"
  changelog: "5.0: Karpathy compressed (5.2→4.0KB) · 1.0: Merged from 4 skills"
---
<!-- karpathy-compressed: 2026-07-10 -->

# UI Engine

## §1 Layout
```
1D → Flexbox | 2D → Grid | Siblings → Subgrid | Parent-aware → :has()
```

```css
.flex-row { display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; }
.flex-item { flex: 1 1 250px; min-inline-size: 0; }
.grid-auto { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; }
.page { display: grid; grid-template-areas: "header header" "sidebar main" "footer footer"; grid-template-columns: 250px 1fr; }
.card { display: grid; grid-template-rows: subgrid; grid-row: span 3; }
.card:has(img) { grid-template-columns: 200px 1fr; }
@layer base, components, utilities, overrides;
```
Flex: `flex:1` equal | `margin-inline-start:auto` push | `margin:auto` center | `flex-shrink:0` prevent
Grid: `grid-column:span 2` | `grid-area:header` | `place-items:center` | `width:min(100%,400px)`
Logical: `width→inline-size` | `margin-left→margin-inline-start`. Max nesting: 3.
❌ Flexbox 2D · ❌ Grid 1D · ❌ `!important` vs `@layer` · ❌ Physical RTL · ❌ `flex:1` w/o `min-inline-size:0`

---

## §2 Responsive
**MQ = page layout. CQ = components.**

```css
.card-wrapper { container-type: inline-size; container-name: card; }
@container card (min-width: 400px) { .card { display: grid; grid-template-columns: 240px 1fr; } }
.page { display: grid; grid-template-columns: [full-start] minmax(1rem,1fr) [content-start] min(65ch,100%) [content-end] minmax(1rem,1fr) [full-end]; }
@container style(--theme: compact) { .card { padding: 0.5rem; } }
```
`auto-fit`+`minmax(280px,1fr)` cards | `auto-fill` galleries | `auto-fit`+`minmax(min(100%,300px),1fr)` safe responsive
`inline-size` ✅ | `size` ❌ (needs `block-size`) | `normal` style queries only
❌ `container-type: size` w/o `block-size` · ❌ `grid-auto-flow: dense` interactive · ❌ MQ components · ❌ Fixed columns w/o `minmax()`

---

## §3 Design Tokens
```
PRIMITIVE → SEMANTIC → COMPONENT
--clr-blue-500 → --clr-primary → --btn-bg
--space-200: 16px → --spacing-md → --btn-padding
```

```css
--clr-primary: oklch(55% 0.18 255);    --clr-primary-hover: oklch(45% 0.16 255);
--clr-surface: oklch(99% 0 0);          --clr-text: oklch(20% 0.02 260);
--space-05: 4px;  --space-1: 8px;   --space-2: 16px;  --space-3: 24px;
--space-4: 32px;  --space-5: 48px;  --space-6: 64px;  --space-7: 96px;
--text-xs: clamp(0.75rem, 1.5cqi, 0.8rem);    --text-sm: clamp(0.85rem, 2cqi, 0.9rem);
--text-base: clamp(1rem, 2.5cqi, 1.125rem);   --text-lg: clamp(1.125rem, 3cqi, 1.25rem);
--text-xl: clamp(1.25rem, 3.5cqi, 1.5rem);    --text-2xl: clamp(1.5rem, 4cqi, 2rem);
:root { color-scheme: light dark; }
.light { color: light-dark(#1a1a1a, #f5f5f5); }
[data-theme="dark"] { --clr-surface: oklch(15% 0.02 260); --clr-text: oklch(90% 0.02 260); }
```
OKLCH > HSL: perceptual uniformity, dark mode, wide gamut, contrast ≥4.5:1.
Lh 1.6 body / 1.2 headings. `text-wrap: balance` headings, `text-wrap: pretty` body.
❌ HSL/RGB · ❌ Components→primitives · ❌ Arbitrary spacing · ❌ Fixed font-size

---

## §4 Animation
**4 purposes**: State change · Feedback · Attention · Spatial continuity. Not 1? → Cut.
Only `transform`/`opacity` compositor (GPU). `width`/`height`/`top`/`left`/`margin`/`padding` = **NEVER**.

```css
--ease-out: cubic-bezier(0,0,0.2,1);      /* enter */
--ease-in: cubic-bezier(0.4,0,1,1);        /* exit */
--ease-standard: cubic-bezier(0.4,0,0.2,1);/* between */
.card { transition: transform var(--dur-fast) var(--ease-out), opacity var(--dur-fast) var(--ease-out); }
.card:hover { transform: scale(1.02); }
.reveal { animation: fade-up 0.5s var(--ease-out); animation-timeline: view(); animation-range: entry 0% entry 100%; }
@supports not (animation-timeline:view()) { .reveal { opacity:1; transform:none; } }
@media (prefers-reduced-motion: reduce) {
  *,*::before,*::after { animation-duration:0.01ms!important; transition-duration:0.01ms!important; }
}
```
fast:120ms(hover,focus) | base:200ms(dropdown) | slow:300ms(modal) | MAX:500ms
Motion budget: Initial viewport **<800ms total**.
Micro: Hover 120ms `scale(1.02)` | Press 80ms `scale(0.98)` | Modal 250ms out→150ms in
❌ Decorative motion · ❌ Layout anim · ❌ Mixing compositor+layout · ❌ `will-change` everywhere · ❌ >500ms · ❌ `transition: all`
