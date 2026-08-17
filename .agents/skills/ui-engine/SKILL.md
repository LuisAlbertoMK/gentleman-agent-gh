---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1026
---
## When to Use
UI: Grid/Flexbox/@layer/:has()·CQ·OKLCH·anim·patterns.
## Decision Tree
`1D→Flex|2D→Grid|Child→Subgrid|Parent→:has()|Unknown→auto-fit,minmax(280px,1fr)|CQ(container-type:inline-size)|Page→MQ`
## Layout
`.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}`
`@layer base,components,utilities,overrides;`
Flex:1|1 1 250px|auto|margin:auto|shrink:0. Grid:span2|area:hd|center. Max3nest.
## Responsive
MQ=page;CQ=comp. `container-type:inline-size`✅|`size`❌. `cqi`=container. CQ ex→Examples.
## Tokens
PRIM→SEM→COMP:`--blue-500→--primary→--btn-bg`
`--pri:oklch(55%.18 255);--sf:oklch(99%0 0);--tx:oklch(20%.02 260)`
`--s1:4px;--s2:8px;--s3:16px;--s4:24px;--s5:32px;--s6:48px;--s7:64px;--s8:96px`
`--xs:clamp(.75rem,1.5vw,.8rem);--base:clamp(1rem,2.5vw,1.125rem);--xl:clamp(1.25rem,3.5vw,1.5rem)`
`:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15%.02 260);--tx:oklch(90%.02 260)}`
OKLCH>HSL:perceptual,dark,wide,≥4.5:1. `vw`=page,`cqi`=container.
## Animation
4p:State·Feedback·Attention·Spatial;else cut;only `transform`/`opacity`.
`--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)`
`.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}`
`@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`
120/200/300ms hover/dropdown/modal;≤500ms;<200ms/elem.
## Components
HOC→RenderProps→Hooks→Headless; hooks/renderProps for DnD/anim.
`<Tab.Group><Tab.List>...</Tab.List><Tab.Panels>...</Tab.Panels></Tab.Group>`
State:URL→SC→TanStackQuery→useState→Zustand→Redux(rare). RSC:no useState/useEffect;`'use client'` leaves.
## Examples
Btn:`.btn{--bg:var(--pri);color:var(--sf);background:var(--bg);padding:.5em 1em;border-radius:8px;transition:transform .12s,opacity .12s}.btn:hover{transform:translateY(-1px)}`
`@supports not (color:oklch(0% 0 0)){:root{--pri:#2563eb}}` oklch fallback.
Nav:`.nav{container-type:inline-size}.nav-links{display:flex;gap:1rem;flex-wrap:wrap}.nav-toggle{display:none}.nav:has(.nav-toggle:checked) .nav-links{display:flex}@container (max-width:600px){.nav-toggle{display:block}.nav-links{display:none}}`
`@supports not selector(:has(a b)){.nav-toggle:checked~.nav-links{display:flex}}` :has() fallback.
`@supports not (container-type:inline-size){@media (max-width:700px){.nav-toggle{display:block}.nav-links{display:none}}}` CQ fallback.
Card:`.card{container-type:inline-size}.card-body{display:grid;grid-template-columns:1fr}@container (min-width:400px){.card-body{grid-template-columns:240px 1fr}}`
`@supports not (container-type:inline-size){.card-body{grid-template-columns:1fr}}` CQ fallback.
## Testing
- axe-core: per page, 0 serious/critical
- CQ: DevTools toggle `container-type` — breakpoints on container, not viewport
- reduced-motion: emulate ON — animations → .01ms
- Tab: focus ring visible at every stop
## A11y
color-scheme:light dark→native controls (Tokens). `:focus-visible{outline:2px solid var(--pri);outline-offset:2px}` keyboard-only, never `outline:none`. Contrast≥4.5:1→accessibility.
## Output
`UI-IMPL:<component>—<date> PATTERN:[flex|grid|cq|tokens]<used> VERIFY:[a11y|contrast|reduced-motion|CQ]→<pass/fail> FALLBACK:[@supports]→<used/not-needed>`

## Anti-Patterns
Flex2D·Grid1D·!important vs @layer·flex:1 w/o min-inline-size:0·container-type:size w/o block-size·grid-auto-flow:dense·MQ for components·Decorative·>500ms·transition:all·HSL/RGB·Fixed font·cqi outside container·Prop drill>3L·DerivedStateInUseEffect·Context high-freq·HOCs new·Redux default
## Refs: baseline-ui·accessibility·performance