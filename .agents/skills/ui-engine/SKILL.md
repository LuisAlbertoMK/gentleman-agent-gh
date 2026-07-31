---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
---

## When to Use
UI system — Grid/Flexbox/@layer/:has(), container queries, c

## Decision Tree
`1D→Flex|2D→Grid|Child→Subgrid|Parent→:has()|Unknown→auto-fit,minmax(280px,1fr)|CQ(container-type:inline-size)|Page→MQ`

## Layout
`.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}`
`.ga{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}`
`.pg{display:grid;grid-template-areas:"hd hd""sd mn""ft ft";grid-template-columns:250px 1fr}`
`@layer base,components,utilities,overrides;`
Flex:`flex:1`|`1 1 250px`|`auto`push|`margin:auto`center|`shrink:0`. Grid:`span2`|`area:hd`|`place-items:center`. Max3nest.

## Responsive
MQ=page. CQ=components.
`.card-wrapper{container-type:inline-size;container-name:card-cq}`
`@container card-cq(min-width:400px){.card-inner{display:grid;grid-template-columns:240px 1fr}}`
`auto-fit+minmax(280px,1fr)`|`inline-size`✅|`size`❌

## Tokens
PRIM→SEM→COMP:`--blue-500→--primary→--btn-bg`
`--pri:oklch(55%.18 255);--sf:oklch(99%0 0);--tx:oklch(20%.02 260)`
`--s1:4px;--s2:8px;--s3:16px;--s4:24px;--s5:32px;--s6:48px;--s7:64px;--s8:96px`
`--xs:clamp(.75rem,1.5vw,.8rem);--base:clamp(1rem,2.5vw,1.125rem);--xl:clamp(1.25rem,3.5vw,1.5rem)`
`:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15%.02 260);--tx:oklch(90%.02 260)}`
OKLCH>HSL:perceptual,dark,wide-gamut,≥4.5:1. `vw`page,`cqi`in `container-type:inline-size`.

## Animation
4p:State·Feedback·Attention·Spatial. Else cut. Only `transform`/`opacity`.
`--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)`
`.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}`
`@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`
120ms hover|200ms dropdown|300ms modal|≤500ms. <200ms/element.

## Components
HOC→Render Props→Hooks→Headless. Use hooks, render props for DnD/anim.
`<Tab.Group><Tab.List>...</Tab.List><Tab.Panels>...</Tab.Panels></Tab.Group>`
State:URL→SC→TanStack Query→useState→Zustand(default)→Redux(rare). RSC:no useState/useEffect. `'use client'` leaves.

## Anti-Patterns
Flex2D·Grid1D·!important vs @layer·flex:1 w/o min-inline-size:0·container-type:size w/o block-size·grid-auto-flow:dense·MQ for components·Decorative·>500ms·transition:all·HSL/RGB·Fixed font·cqi outside container·Prop drill>3L·DerivedStateInUseEffect·Context high-freq·HOCs new·Redux default

## Loading: ui-engine→baseline-ui→accessibility→performance
