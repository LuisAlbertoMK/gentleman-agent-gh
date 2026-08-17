---
name: baseline-ui
description: "Anti-slop UI — layout, typography, responsive, animation, tokens. Use for cleanup or polish."
triggers: "ui cleanup, polish interface, fix layout, ui slop, generic ui, design review, anti-slop, ui polish, polish ui"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1029
---

## When to Use
Anti-slop audit&cleanup: layout·typography·responsive·animation·tokens
**Stack**: CSS/Tailwind·`cn()`(clsx+tw-merge)·React·Audit→**ui-engine**
**Flow**: Scan→❌→fix→verify→a11y→perf·Review:`/baseline-ui <file>`

## Layout 10 Patterns
1. **Sticky sidebar** `.pg{display:grid;grid-template-areas:"hd hd""sd mn";grid-template-columns:250px 1fr}.sd{position:sticky;top:1rem;align-self:start}`
2. **Card grid** `.grid{display:grid;gap:1.5rem;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))}`
3. **Responsive nav** `.nav{display:flex;flex-wrap:wrap;gap:1rem}.nav>a{flex-shrink:0}`
4. **Aspect media** `.media{width:100%;aspect-ratio:16/9;object-fit:cover}`❌`padding-top:56.25%`
5. **Sticky footer** `body{display:grid;grid-template-rows:auto 1fr auto;min-height:100dvh}`
6. **Fluid split** `.split{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,320px),1fr))}`
7. **CQ card** `.card{container-type:inline-size}.card-inner{display:grid;gap:1rem}@container(min-width:400px){.card-inner{grid-template-columns:240px 1fr}}`
8. **Hero** `.hero{min-height:100dvh;padding:max(1rem,env(safe-area-inset-top))}`
9. **Subgrid rows** `.rows{display:grid}.rows>*{display:grid;grid-template-rows:subgrid;grid-row:span 2}`
10. **Stack/center** `.stack{display:grid;gap:1rem}.center{place-items:center}`
Tree:1D→Flex|2D→Grid|Child→Subgrid|Parent→:has()|?→auto-fit,minmax()

## Typography
`text-balance`h·`text-pretty`body·`tabular-nums`data·Page→`clamp(1rem,1.5vw+.5rem,1.5rem)`

## Animation
`transform`+`opacity`only·❌w/h/top/left/margin/padding·120/200/300ms·❌>500·<200ms/elem
`@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`

## Tokens OKLCH→Var
| Step | Action | Example |
|---|---|---|
|1|Pick OKLCH|oklch(55% .18 255)|
|2|Primitive var|--blue-500:oklch(55% .18 255)|
|3|Semantic var|--primary:var(--blue-500)|
|4|Component var|--btn-bg:var(--primary)|
|5|Theme|:root{color-scheme:light dark}|
|6|Verify|≥4.5:1|

## Responsive Test Matrix
| Breakpoint | Simulate | Verify |
|---|---|---|
|<640|iPhone SE 320|1-col·nav collapse·44px|
|640-1024|iPad 768|2-col sticky|
|1024-1440|resize|3-col|
|>1440|max win|grid caps|
|CQ 400|DevTools|`cqi`flips|
|Reduced|emulate|.01ms|
|Dark|toggle|`light-dark()`|

## Design
No gradients/glow/multicolor·1 primary·Errors next to action·No blocking paste

## Hard Rules
- Animate `transform`+`opacity` only — NEVER w/h/top/left/margin/padding; 120/200/300ms, NEVER >500ms, <200ms/element
- ALWAYS include `@media(prefers-reduced-motion:reduce)` → `.01ms` override
- Colors: OKLCH only, 3-tier chain (primitive→semantic→component), contrast ≥4.5:1 — NEVER HSL/RGB hex
- No fixed widths: `repeat(auto-fit,minmax())` + `clamp()` + `min-height:100dvh` (never `h-screen`/fixed px)
- `cqi` ONLY inside a container (CQ `inline-size`); MQ=page, CQ=components
- Design: 1 primary color, no gradients/glow/multicolor; errors adjacent to action; never block paste
- Verify contrast, reduced-motion and dark mode (Responsive Test Matrix) before done

## Output
`UI-CLEANUP:<file>—<date> CRITICAL:[a11y|contrast]<issue>→<fix> HIGH:[layout|responsive]<issue>→<fix> MEDIUM:[tokens|anim]<issue>→<fix> VERIFY:[a11y|perf]→<pass/fail>`

## Cross-Refs: ui-engine | accessibility | performance | web-quality-audit


## Anti-Patterns
Fixed width·h-screen·dense interactive·Fixed font·transition:all·>500ms·No reduced-motion·HSL/RGB·No contrast·cqi outside container·letter-spacing body

## Examples
Trigger `/baseline-ui <file>` on a slop component (ui cleanup, fix layout, ui audit):
```bash
/baseline-ui src/components/Card.tsx
```
Expected output — findings + fixes:
- ❌ `max-w-md` fixed width → Pattern 2: `repeat(auto-fit,minmax(280px,1fr))`
- ❌ `transition:all .6s` → `transform .2s` + reduced-motion `.01ms` override
- ❌ `color:#666` → OKLCH token chain (primitive→semantic→component) at ≥4.5:1

## Testing
1. Pattern spot-check: apply 2 of the 10 Layout patterns (e.g. sticky sidebar, CQ card) to a throwaway component → verify at 320/768/1440 in DevTools responsive mode (Responsive Test Matrix).
2. Token chain: pick `oklch(55% .18 255)` → walk the 6-step Tokens table to `--btn-bg` → confirm resolution + contrast ≥4.5:1.
3. No regression: run `accessibility` audit before/after fixes → same or better contrast/focus results (Refs: accessibility).
