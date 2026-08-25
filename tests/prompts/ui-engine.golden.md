# ui-engine golden prompt

## Skill
ui-engine (UI systems: layout, responsive, animation, design tokens, CSS)

## Trigger
ui, layout, responsive, grid, flexbox, container query

## Input
Refactor the Button component from fixed px layout to a responsive flex container with container queries for dark mode, using Tailwind and cn().

## Expected Output
UI-IMPL:Button.jsx--2026-08-21 PATTERN:[flex]container+gap+cqi VERIFY:[a11y|contrast|reduced-motion|CQ]->pass

## Assertion
- Response matches UI-IMPL:<component>--<date> contract
- Catches: hardcoded px width, absolute positioning, missing container query, missing reduced-motion
- Within token_budget 2200
