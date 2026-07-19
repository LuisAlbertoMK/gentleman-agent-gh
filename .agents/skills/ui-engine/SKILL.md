---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
license: MIT
metadata:
  tags: [frontend, ui, css, architecture]
  author: gentleman-vMK
  version: "8.0"
  changelog: "8.0: Added §5 Component Patterns (compound, hooks, state management, RSC). 7.1: Breaker fixes"
---
# UI Engine

## Decision Tree
```
Layout problem? →
  1D row/column? → Flexbox
  2D grid? → Grid
  Align children to parent tracks? → Subgrid (child inherits parent's grid tracks)
  Parent styling based on child? → :has()
  Unknown? → auto-fit, minmax(280px,1fr)
  Component responsive? → Container Query (container-type: inline-size)
  Page responsive? → Media Query
```

## §1 Layout
`1D→Flex | 2D→Grid | Child inherits parent tracks→Subgrid | Parent→:has()`
```css
.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}
.ga{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}
.pg{display:grid;grid-template-areas:"hd hd""sd mn""ft ft";grid-template-columns:250px 1fr}
@layer base,components,utilities,overrides;
```
Flex: `flex:1` (= `1 1 0%`) equal distribution | `flex:1 1 250px` equal with 250px basis | `auto` push | `margin:auto` center | `shrink:0` prevent
Grid: `span 2` | `area:hd` | `place-items:center`. Logical: `inline-size`. Max CSS nesting depth:3.
❌Flexbox2D·❌Grid1D·❌!importantvs@layer·❌flex:1w/omin-inline-size:0

## §2 Responsive
**MQ=page. CQ=components.**
```css
.card-wrapper{container-type:inline-size;container-name:card-cq}
@container card-cq(min-width:400px){.card-inner{display:grid;grid-template-columns:240px 1fr}}
```
`auto-fit`+`minmax(280px,1fr)` cards | `inline-size` ✅ | `size` ❌
❌container-type:sizew/oblock-size·❌grid-auto-flow:dense·❌MQcomponents

## §3 Design Tokens
`PRIM→SEM→COMP: --blue-500→--primary→--btn-bg`
```css
--pri:oklch(55% .18 255);--sf:oklch(99% 0 0);--tx:oklch(20% .02 260)
--s1:4px;--s2:8px;--s3:16px;--s4:24px;--s5:32px;--s6:48px;--s7:64px;--s8:96px
--xs:clamp(.75rem,1.5vw,.8rem);--base:clamp(1rem,2.5vw,1.125rem);--xl:clamp(1.25rem,3.5vw,1.5rem)
:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15% .02 260);--tx:oklch(90% .02 260)}
```
OKLCH>HSL: perceptual, dark mode, wide gamut, contrast≥4.5:1. `text-wrap:balance|pretty`.
Fluid type: use `vw` for page-level, `cqi` only inside containers with `container-type: inline-size`.
❌HSL/RGB·❌Components→primitives·❌Fixedfont-size·❌cqioutsidecontainer

## §4 Animation
**4 purposes**: State·Feedback·Attention·Spatial. Not 1?→Cut. Only `transform`/`opacity`.
```css
--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)
.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}.card:hover{transform:scale(1.02)}
@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}
```
120ms hover/focus | 200ms dropdown | 300ms modal | MAX 500ms per animation. Per-element budget: <200ms total per element.
❌Decorative·❌Layoutanim·❌will-change·❌>500ms·❌transition:all

## §5 Component Patterns
**Evolution**: HOC→Render Props→Hooks→Headless. Use hooks (dominant), render props only for DnD/animation libs.
```jsx
// Compound: shared state via Context
<Tab.Group><Tab.List><Tab>...</Tab.List><Tab.Panels>...</Tab.Panels></Tab.Group>

// Custom hook: logic sharing
const useLocalStorage = (key, init) => { const [v,set]=useState(()=>...)... }

// Controlled vs Uncontrolled: default uncontrolled, controlled when parent needs state
const [open,setOpen] =useState(false) // uncontrolled
const {open,onClose}=props // controlled
```
**State 2026**: URL→Server Component→TanStack Query→useState→Zustand(default)→Redux(rarely)
**RSC**: Server Components = no useState/useEffect. `'use client'` at leaf nodes only.
❌PropDrill>3L·❌DerivedStateInUseEffect·❌ContextForHighFreq·❌HOCsInNewCode·❌ReduxAsDefault

## Workflow
1. **Identify**: 1D/2D? Component/page? Known layout → skip
2. **Choose**: Decision tree → pick technique
3. **Implement**: Use patterns from §1-§5
4. **Tokens**: Check cascade PRIM→SEM→COMP
5. **Responsive**: CQ for components (container-type: inline-size), MQ for page
6. **Animate**: 4 purposes check → compositor-only → per-element budget
7. **Components**: Pattern from §5 (hooks > render props > HOCs)
8. **Verify**: `prefers-reduced-motion`, contrast≥4.5:1, CSS nesting depth ≤3

## Component Examples
**Card grid**: `.ga{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem}`
**Sidebar layout**: `.pg{grid-template-areas:"hd hd""sd mn""ft ft";grid-template-columns:250px 1fr}`
**Fluid card**: `.card-wrapper{container-type:inline-size}@container(min-width:400px){.card-inner{display:grid;grid-template-columns:240px 1fr}}`
**Stack**: `.stack{display:flex;flex-direction:column;gap:1rem}`

## Loading Order
When loading multiple UI skills: **ui-engine** (reference patterns) → **baseline-ui** (audit/anti-slop) → **accessibility** (focus/A11y) → **performance** (budget). Do not re-chain circularly.

## Integration
- **baseline-ui** → audit workflow, anti-slop patterns (load AFTER ui-engine)
- **accessibility** → focus management, contrast, ARIA
- **performance** → compositor-only, content-visibility
- **web-quality-audit** → full audit checklist

## Anti-Patterns
Flexbox2D · Grid1D · !important vs @layer · flex:1 w/o min-inline-size:0 · container-type:size w/o block-size · grid-auto-flow:dense interactive · MQ for components · Decorative animation · >500ms duration · transition:all · HSL/RGB tokens · Fixed font-size · cqi outside container · Prop drilling >3L · Derived state in useEffect · Context for high-frequency updates · HOCs in new code · Redux as default
