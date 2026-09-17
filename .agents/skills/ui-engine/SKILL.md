---
name: ui-engine
description: "UI system — Grid/Flexbox/@layer/:has(), container queries, compositor-only animation, OKLCH tokens, component patterns"
triggers: "ui, layout, responsive, animation, design tokens, css, grid, flexbox, container query, dark mode, component layout, page layout, component patterns, hooks, compound components, state management"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## Decision Tree
1D→Flex | 2D→Grid | Child→Subgrid | Parent→:has() | Unknown→auto-fit,minmax(280px,1fr) | CQ(container-type:inline-size) | Page→MQ

## Layout
`@layer base,components,utilities,overrides;` Flex:1|1 1 250px|auto|shrink:0. Grid:span2|area:hd|center. Max3nest.

## Animation
4p: State·Feedback·Attention·Spatial; else cut. Only `transform`/`opacity`; 120/200/300ms; ≤500ms; <200ms/elem.

## Tokens
PRIM→SEM→COMP: `--blue-500→--primary→--btn-bg`. OKLCH>HSL: perceptual, ≥4.5:1. `vw`=page, `cqi`=container.

## A11y
`color-scheme:light dark`→native controls. `:focus-visible{outline:2px solid var(--pri);outline-offset:2px}`. Never `outline:none`. Contrast≥4.5:1.

## Output
`UI-IMPL:<component>—<date> PATTERN:[flex|grid|cq|tokens]<used> VERIFY:[a11y|contrast|reduced-motion|CQ]→<pass/fail>`

## Anti-Patterns
Flex2D · Grid1D · !important vs @layer · flex:1 w/o min-inline-size:0 · MQ for components · >500ms · transition:all · HSL/RGB · cqi outside container

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Grid cuando Flexbox basta" | 1D layout con Grid | Decision Tree: 1D→Flex 2D→Grid |
| "Animar layout properties" | transition:all / width/height | Transform+opacity only + reduced-motion |
| "Tokens ad-hoc" | hex/HSL sin chain | PRIM→SEM→COMP OKLCH + ≥4.5:1 |

## Verification
- Output matches ## Output contract + file:line citation; cross-ref-check.ps1 → SKILL.md OK
- Frontmatter (name/description/triggers/token_budget) stable; cross-refs exist; no anti-patterns
- token_budget: total tokens within frontmatter token_budget
- anti-patterns: none of the listed anti-patterns reintroduced

→ docs/skills/ui-engine/reference.md · Cross-Refs: baseline-ui | accessibility | performance | web-quality-audit | seo | visual-testing | vision-analyze
