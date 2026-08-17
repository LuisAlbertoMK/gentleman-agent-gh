# ui-engine — golden prompt

**Trigger**: "responsive", "container query", "grid", "flexbox"

```
Build a responsive product card component. Use container queries (inline-size) for the inner layout,
repeat(auto-fit,minmax(280px,1fr)) for the grid, clamp() for fluid type, and OKLCH tokens.
Dark mode via light-dark(). Animation: transform/opacity only, <200ms per element, reduced-motion override.
```

**Expected**: `UI-IMPL:<component>—<date> PATTERN:<pattern> VERIFY:[a11y|contrast|reduced-motion|CQ]→<pass/fail> FALLBACK:[@supports]→<ok/fail>`
