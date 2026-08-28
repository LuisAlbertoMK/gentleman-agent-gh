---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1990
---
## When to Use
UI: Grid/Flexbox/@layer/:has()·CQ·OKLCH·anim·patterns.
## Decision Tree
`1D→Flex|2D→Grid|Child→Subgrid|Parent→:has()|Unknown→auto-fit,minmax(280px,1fr)|CQ(container-type:inline-size)|Page→MQ`
## Layout
`.flex{display:flex;flex-wrap:wrap;gap:1rem}.flex>*,.fi{flex:1 1 250px;min-inline-size:0}`
`@layer base,components,utilities,overrides;`
Flex:1|1 1 250px|auto|margin:auto|shrink:0. Grid:span2|area:hd|center. Max3nest.
## Animation
4p: State·Feedback·Attention·Spatial; else cut; only `transform`/`opacity`; 120/200/300ms hover/dropdown/modal; ≤500ms; <200ms/elem.
## Tokens
PRIM→SEM→COMP:`--blue-500→--primary→--btn-bg`
OKLCH>HSL: perceptual, dark, wide, ≥4.5:1. `vw`=page, `cqi`=container.
## A11y
`color-scheme:light dark`→native controls. `:focus-visible{outline:2px solid var(--pri);outline-offset:2px}` keyboard-only, never `outline:none`. Contrast ≥4.5:1→accessibility.
## Output
`UI-IMPL:<component>—<date> PATTERN:[flex|grid|cq|tokens]<used> VERIFY:[a11y|contrast|reduced-motion|CQ]→<pass/fail>`
## Anti-Patterns
Flex2D·Grid1D·!important vs @layer·flex:1 w/o min-inline-size:0·container-type:size w/o block-size·grid-auto-flow:dense·MQ for components·Decorative·>500ms·transition:all·HSL/RGB·Fixed font·cqi outside container·Prop drill>3L·Context high-freq
## Cross-Refs: baseline-ui | accessibility | performance
> docs/skills/ui-engine/reference.md

## Verification
- Output: response matches the ## Output contract format exactly
- token_budget: total tokens within frontmatter token_budget
- frontmatter: name, description, triggers, token_budget present and stable
- cross-refs: each referenced skill exists
- anti-patterns: none of the listed anti-patterns reintroduced
