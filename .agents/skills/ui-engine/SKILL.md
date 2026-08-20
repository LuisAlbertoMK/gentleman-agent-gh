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
MQ=page; CQ=comp. `container-type:inline-size`✅|`size`❌. `cqi`=container. CQ ex→Examples.

## Tokens
PRIM→SEM→COMP:`--blue-500→--primary→--btn-bg`
`--pri:oklch(55%.18 255);--sf:oklch(99%0 0);--tx:oklch(20%.02 260)`
`--s1..--s8:4..96px` · `--xs/--base/--xl: clamp()` fluid
`:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15%.02 260);--tx:oklch(90%.02 260)}`
OKLCH>HSL: perceptual, dark, wide, ≥4.5:1. `vw`=page, `cqi`=container.

## Animation
4p: State·Feedback·Attention·Spatial; else cut; only `transform`/`opacity`.
`--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)`
`.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}`
`@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`
120/200/300ms hover/dropdown/modal; ≤500ms; <200ms/elem.

## Components
HOC→RenderProps→Hooks→Headless; hooks/renderProps for DnD/anim.
State: URL→SC→TanStackQuery→useState→Zustand→Redux(rare). RSC: no useState/useEffect; `'use client'` leaves.

## Examples
Btn: `.btn{--bg:var(--pri);color:var(--sf);background:var(--bg);padding:.5em 1em;border-radius:8px;transition:transform .12s,opacity .12s}.btn:hover{transform:translateY(-1px)}` + `@supports not (color:oklch(0% 0 0)){--pri:#2563eb}`.
Nav/Card: `.nav{container-type:inline-size}` + `:has()` toggle; `.card{container-type:inline-size}` + `@container (min-width:400px){grid-template-columns:240px 1fr}`.

## A11y
`color-scheme:light dark`→native controls. `:focus-visible{outline:2px solid var(--pri);outline-offset:2px}` keyboard-only, never `outline:none`. Contrast ≥4.5:1→accessibility.

## Output
`UI-IMPL:<component>—<date> PATTERN:[flex|grid|cq|tokens]<used> VERIFY:[a11y|contrast|reduced-motion|CQ]→<pass/fail>`

## Anti-Patterns
Flex2D·Grid1D·!important vs @layer·flex:1 w/o min-inline-size:0·container-type:size w/o block-size·grid-auto-flow:dense·MQ for components·Decorative·>500ms·transition:all·HSL/RGB·Fixed font·cqi outside container·Prop drill>3L·Context high-freq

## Cross-Refs: baseline-ui | accessibility | performance