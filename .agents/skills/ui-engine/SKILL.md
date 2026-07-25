---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
license: MIT
metadata:
  tags: [frontend, ui, css, architecture]
  author: gentleman-vMK
  version: "8.0"
  changelog: "8.0: Added §5 Component Patterns. 7.1: Breaker fixes"
---
# UI Engine

## Decision Tree
`1D→Flex | 2D→Grid | Child inherits tracks→Subgrid | Parent from child→:has() | Unknown→auto-fit,minmax(280px,1fr) | Component CQ(container-type:inline-size) | Page MQ`

## §1 Layout
```css
.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}
.ga{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}
.pg{display:grid;grid-template-areas:"hd hd""sd mn""ft ft";grid-template-columns:250px 1fr}
@layer base,components,utilities,overrides;
```
Flex: `flex:1` equal | `flex:1 1 250px` +basis | `auto` push | `margin:auto` center | `shrink:0` prevent
Grid: `span 2` | `area:hd` | `place-items:center`. Logical: `inline-size`. Max nesting:3.

## §2 Responsive
MQ=page. CQ=components.
```css
.card-wrapper{container-type:inline-size;container-name:card-cq}
@container card-cq(min-width:400px){.card-inner{display:grid;grid-template-columns:240px 1fr}}
```
`auto-fit`+`minmax(280px,1fr)` | `inline-size` ✅ | `size` ❌

## §3 Design Tokens
`PRIM→SEM→COMP: --blue-500→--primary→--btn-bg`
```css
--pri:oklch(55% .18 255);--sf:oklch(99% 0 0);--tx:oklch(20% .02 260)
--s1:4px;--s2:8px;--s3:16px;--s4:24px;--s5:32px;--s6:48px;--s7:64px;--s8:96px
--xs:clamp(.75rem,1.5vw,.8rem);--base:clamp(1rem,2.5vw,1.125rem);--xl:clamp(1.25rem,3.5vw,1.5rem)
:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15% .02 260);--tx:oklch(90% .02 260)}
```
OKLCH>HSL: perceptual, dark mode, wide gamut, contrast≥4.5:1. `text-wrap:balance|pretty`.
Fluid: `vw` page-level, `cqi` only in containers with `container-type:inline-size`.

## §4 Animation
**4 purposes**: State·Feedback·Attention·Spatial. Not 1?→Cut. Only `transform`/`opacity`.
```css
--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)
.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}.card:hover{transform:scale(1.02)}
@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}
```
120ms hover/focus | 200ms dropdown | 300ms modal | MAX 500ms. Budget: <200ms/element.

## §5 Component Patterns
Evolution: HOC→Render Props→Hooks→Headless. Use hooks, render props for DnD/animation libs.
```jsx
<Tab.Group><Tab.List><Tab>...</Tab.List><Tab.Panels>...</Tab.Panels></Tab.Group>
const useLocalStorage=(key,init)=>{const[v,set]=useState(()=>...)...}
```
State 2026: URL→Server Component→TanStack Query→useState→Zustand(default)→Redux(rarely)
RSC: no useState/useEffect. `'use client'` at leaf nodes only.

## Anti-Patterns
Flexbox2D·Grid1D·!important vs @layer·flex:1 w/o min-inline-size:0·container-type:size w/o block-size·grid-auto-flow:dense·MQ for components·Decorative animation·>500ms·transition:all·HSL/RGB·Fixed font-size·cqi outside container·Prop drilling >3L·DerivedStateInUseEffect·Context high-freq·HOCs new code·Redux default

## Loading Order
ui-engine → baseline-ui → accessibility → performance. No circular re-chaining.
