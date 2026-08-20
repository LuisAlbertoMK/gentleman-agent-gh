# ui-engine — Reference Materials

> **Externalized from** .agents/skills/ui-engine/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains responsive/component/animation/token detail and worked examples.

## Responsive
MQ=page; CQ=comp. `container-type:inline-size`✅|`size`❌. `cqi`=container. CQ ex→Examples.

## Tokens
`--pri:oklch(55%.18 255);--sf:oklch(99%0 0);--tx:oklch(20%.02 260)`
`--s1..--s8:4..96px` · `--xs/--base/--xl: clamp()` fluid
`:root{color-scheme:light dark}[data-theme="dark"]{--sf:oklch(15%.02 260);--tx:oklch(90%.02 260)}`

## Animation
`--eo:cubic-bezier(0,0,.2,1);--ei:cubic-bezier(.4,0,1,1)`
`.card{transition:transform var(--df) var(--eo),opacity var(--df) var(--eo)}`
`@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`

## Components
HOC→RenderProps→Hooks→Headless; hooks/renderProps for DnD/anim.
State: URL→SC→TanStackQuery→useState→Zustand→Redux(rare). RSC: no useState/useEffect; `'use client'` leaves.

## Examples
Btn: `.btn{--bg:var(--pri);color:var(--sf);background:var(--bg);padding:.5em 1em;border-radius:8px;transition:transform .12s,opacity .12s}.btn:hover{transform:translateY(-1px)}` + `@supports not (color:oklch(0% 0 0)){--pri:#2563eb}`.
Nav/Card: `.nav{container-type:inline-size}` + `:has()` toggle; `.card{container-type:inline-size}` + `@container (min-width:400px){grid-template-columns:240px 1fr}`.