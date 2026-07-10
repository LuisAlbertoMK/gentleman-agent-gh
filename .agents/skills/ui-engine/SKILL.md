---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode"
license: MIT
metadata:
  tags: [frontend, ui, css, architecture]
  author: gentleman-vMK
  version: "6.0"
  changelog: "6.0: Karpathy (4.0→3.0KB) · 1.0: Merged from 4 skills"
---
# UI Engine
## §1 Layout
`1D→Flex | 2D→Grid | Siblings→Subgrid | Parent→:has()`
```css
.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}
.ga{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}
.pg{display:grid;grid-template-areas:"hd hd""sd mn""ft ft";grid-template-columns:250px 1fr}
.cd{display:grid;grid-template-rows:subgrid;grid-row:span 3}.cd:has(img){grid-template-columns:200px 1fr}
@layer base,components,utilities,overrides;
```
Flex: `flex:1` equal | `auto` push | `margin:auto` center | `shrink:0` prevent
Grid: `span 2` | `area:hd` | `place-items:center` | `min(100%,400px)`. Logical: `inline-size`. Max nest:3.
❌Flexbox2D·❌Grid1D·❌!importantvs@layer·❌PhysicalRTL·❌flex:1w/omin-inline-size:0

## §2 Responsive
**MQ=page. CQ=components.**
```css
.cw{container-type:inline-size;container-name:cd}
@container cd(min-width:400px){.cd{display:grid;grid-template-columns:240px 1fr}}
.pg{display:grid;grid-template-columns:[fs]minmax(1rem,1fr)[cs]min(65ch,100%)[ce]minmax(1rem,1fr)[fe]}
```
`auto-fit`+`minmax(280px,1fr)` cards | `inline-size` ✅ | `size` ❌ (needs `block-size`)
❌container-type:sizew/oblock-size·❌grid-auto-flow:dense·❌MQcomponents·❌Fixedcolumnsw/ominmax()

## §3 Design Tokens
`PRIM→SEM→COMP: --blue-500→--primary→--btn-bg | --space-200:16px→--spacing-md→--btn-padding`
```css
--pri:oklch(55% .18 255);--pri-h:oklch(45% .16 255);--sf:oklch(99% 0 0);--tx:oklch(20% .02 260)
--s1:4px;--s2:8px;--s3:16px;--s4:24px;--s5:32px;--s6:48px;--s7:64px;--s8:96px
--xs:clamp(.75rem,1.5cqi,.8rem);--sm:clamp(.85rem,2cqi,.9rem);--base:clamp(1rem,2.5cqi,1.125rem)
--lg:clamp(1.125rem,3cqi,1.25rem);--xl:clamp(1.25rem,3.5cqi,1.5rem);--2xl:clamp(1.5rem,4cqi,2rem)
:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15% .02 260);--tx:oklch(90% .02 260)}
```
OKLCH>HSL: perceptual, dark mode, wide gamut, contrast≥4.5:1. `text-wrap:balance|pretty`.
❌HSL/RGB·❌Components→primitives·❌Arbitraryspacing·❌Fixedfont-size

## §4 Animation
**4 purposes**: State·Feedback·Attention·Spatial. Not 1?→Cut. Only `transform`/`opacity`.
```css
--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1);--es:cubic-bezier(.4,0,.2,1)
.cd{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}.cd:hover{transform:scale(1.02)}
.rv{animation:fu .5s var(--eo);animation-timeline:view();animation-range:entry 0% entry 100%}
@supports not(animation-timeline:view()){.rv{opacity:1;transform:none}}
@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}
```
120ms hover/focus | 200ms dropdown | 300ms modal | MAX 500ms. Budget: <800ms viewport total.
❌Decorative·❌Layoutanim·❌Mixingcompositor+layout·❌will-change·❌>500ms·❌transition:all
