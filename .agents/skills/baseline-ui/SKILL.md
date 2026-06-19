---
name: baseline-ui
description: Anti-slop UI enforcement — spacing, hierarchy, typography, layout. Use when the interface needs cleanup or polish.
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review"
license: MIT
metadata:
  tags:
    - frontend
    - ui
    - design
  author: gentleman-vMK (adapted from ibelick/ui-skills)
  version: "1.0"
---

# Baseline UI — Anti-slop enforcement

Opinionated UI baseline to prevent AI-generated interface slop.

## Stack rules
- MUST use existing project's CSS/Tailwind defaults unless custom values exist
- MUST use `cn()` utility (`clsx` + `tailwind-merge`) for class logic in React projects
- NEVER introduce a new CSS approach unless project already uses it

## Layout
- MUST use `h-dvh` not `h-screen` (mobile Safari)
- MUST respect `safe-area-inset` for fixed/sticky elements
- MUST use fixed `z-index` scale (no arbitrary `z-*` values)
- SHOULD use `size-*` for square elements instead of `w-*` + `h-*`

## Typography
- MUST use `text-balance` for headings, `text-pretty` for body
- MUST use `tabular-nums` for data/tables
- SHOULD use `truncate` or `line-clamp` for dense UI
- NEVER modify `letter-spacing` unless explicitly requested

## Animation
- NEVER add animation unless explicitly requested
- MUST animate only compositor props (`transform`, `opacity`)
- NEVER animate layout props (`width`, `height`, `top`, `left`, `margin`, `padding`)
- MUST pause looping animations when off-screen
- SHOULD respect `prefers-reduced-motion`

## Design
- NEVER use gradients/multicolor unless explicitly requested
- NEVER use glow effects as primary affordances
- MUST give empty states one clear next action
- SHOULD limit accent color to one per view
- SHOULD use theme tokens before introducing new values

## Interaction
- MUST show errors next to where the action happens
- MUST use accessible component primitives for keyboard/focus behavior
- MUST add `aria-label` to icon-only buttons
- NEVER block paste on inputs
- NEVER rebuild keyboard/focus behavior by hand unless explicitly requested

## Review output
When invoked as `/baseline-ui <file>`, report:
1. Violation (quote exact line/snippet)
2. Why it matters (1 sentence)
3. Concrete fix (code-level suggestion)
