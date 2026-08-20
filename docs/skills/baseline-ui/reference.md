# baseline-ui — Reference Materials

> **Externalized from** .agents/skills/baseline-ui/SKILL.md to keep the skill under the 2KB token budget (ADR-007). Contains the layout pattern library.

## Animation
`transform`+`opacity`only·❌w/h/top/left/margin/padding·120/200/300ms·❌>500·<200ms/elem. `@media(prefers-reduced-motion:reduce){*{animation-duration:.01ms!important;transition-duration:.01ms!important}}`

## Layout 10 Patterns
1. Sticky sidebar `.pg{display:grid;grid-template-areas:"hd hd""sd mn";grid-template-columns:250px 1fr}.sd{position:sticky;top:1rem;align-self:start}`
2. Card grid `.grid{display:grid;gap:1.5rem;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))}`
3. Responsive nav `.nav{display:flex;flex-wrap:wrap;gap:1rem}.nav>a{flex-shrink:0}`
4. Aspect media `.media{width:100%;aspect-ratio:16/9;object-fit:cover}`❌`padding-top:56.25%`
5. Sticky footer `body{display:grid;grid-template-rows:auto 1fr auto;min-height:100dvh}`
6. Fluid split `.split{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,320px),1fr))}`
7. CQ card `.card{container-type:inline-size}.card-inner{display:grid;gap:1rem}@container(min-width:400px){.card-inner{grid-template-columns:240px 1fr}}`
8. Subgrid `.rows{display:grid}.rows>*{display:grid;grid-template-rows:subgrid;grid-row:span 2}`
9. Stack/center `.stack{display:grid;gap:1rem}.center{place-items:center}`