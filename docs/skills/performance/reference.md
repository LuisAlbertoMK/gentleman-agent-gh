# performance — Reference Materials

> **Externalized from** .agents/skills/performance/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples (4-5)

### 1. LCP Image Preload + Priority
```html
<link rel="preload" as="image" href="/hero.avif" type="image/avif" fetchpriority="high">
<img src="/hero.avif" alt="Hero" width="1200" height="600" fetchpriority="high" loading="eager">
```
Preloads hero at highest priority, avoids layout shift via explicit dimensions.

### 2. INP Optimization with scheduler.yield()
```js
button.addEventListener('click', async () => {
  showSpinner();              // <50ms: immediate visual feedback
  await scheduler.yield();    // yield to main thread
  await heavyComputation();   // <100ms: processing phase
  await scheduler.yield();    // yield before paint
  updateUI();                 // <50ms: presentation
});
```
Three yield points keep each phase under INP budget.

### 3. Compositor-Only Animation
```css
.card { will-change: transform, opacity; transition: transform 0.3s, opacity 0.3s; }
.card:hover { transform: translateY(-4px) scale(1.02); opacity: 0.9; }
```
GPU-composited, zero layout/paint. `will-change` hints browser.

### 4. Scroll-Driven Reveal (0KB JS)
```css
@keyframes fade-up { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: none; } }
.section { animation: fade-up 0.6s ease-out both; animation-timeline: view(); animation-range: entry 10% entry 90%; }
```
Native scroll animation, no IntersectionObserver, no JS.

### 5. Virtualized List with content-visibility
```css
.list-item { content-visibility: auto; contain-intrinsic-size: 0 100px; }
```
```js
// Only 20 items rendered in DOM at once, rest skipped by browser
const items = data.map((d, i) => <div class="list-item" key={d.id} style={{transform: `translateY(${i * 100}px)`}}>{d.content}</div>);
```
Browser skips paint/layout for off-screen items automatically.

## Testing Patterns (3)

### 1. CWV Budget Gate (CI)
```bash
# lhci autorun --collect.staticDistDir=dist --upload.target=temporary-public-storage
# Asserts: LCP<2500, INP<200, CLS<0.1, TBT<200
```
Fails build if any Core Web Vital exceeds threshold.

### 2. INP Synthetic Test (Playwright)
```js
// tests/perf/inp.spec.js
test('INP < 200ms on heavy interaction', async ({ page }) => {
  await page.goto('/dashboard');
  const inp = await page.evaluate(() => new Promise(r => new PerformanceObserver(l => r(l.getEntries()[0].duration)).observe({type: 'first-input', buffered: true})));
  await page.click('#heavy-button');
  expect(inp).toBeLessThan(200);
});
```
Measures real INP via PerformanceObserver in headless browser.

### 3. Compositor Verification (DevTools Protocol)
```js
// Verify animation runs on compositor thread
const frames = await page.evaluate(() => new Promise(r => {
  const frames = []; requestAnimationFrame(function tick() { frames.push(performance.now()); if (frames.length < 120) requestAnimationFrame(tick); else r(frames); });
}));
const frameTimes = frames.map((t, i) => i ? t - frames[i-1] : 0).slice(1);
const jank = frameTimes.filter(d => d > 16.67).length;
expect(jank / frameTimes.length).toBeLessThan(0.05); // <5% jank
```
Detects main-thread animation by measuring frame timing variance.

## Edge Cases (4)

### 1. `content-visibility:auto` + Dynamic Height
```css
.item { content-visibility: auto; contain-intrinsic-size: 0 200px; } /* fallback */
```
If intrinsic size wrong → scrollbar jumps. Fix: measure first render, set `contain-intrinsic-size` via JS.

### 2. `scheduler.yield()` Not Available (Safari <16.4)
```js
const yieldToMain = () => scheduler?.yield?.() ?? new Promise(r => setTimeout(r, 0));
```
Polyfill with `setTimeout(0)` — slower but prevents total block.

### 3. Scroll-Driven Animations + Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  .reveal { animation: none !important; opacity: 1; transform: none; }
}
```
Must disable native scroll animations for accessibility compliance.

### 4. Font `font-display: swap` + CLS
```css
@font-face { font-family: 'Inter'; src: url(/inter.woff2) format('woff2'); font-display: swap; ascent-override: 90%; descent-override: 25%; line-gap-override: 0%; }
```
`ascent-override`/`descent-override` match fallback metrics → zero CLS on swap.

## Anti-Patterns (2)

### 1. Animating Layout Properties (Width/Height/Top/Left)
```css
/* ❌ WRONG — triggers layout + paint every frame */
@keyframes slide { from { left: 0; } to { left: 300px; } }
.box { position: absolute; animation: slide 1s; }

/* ✅ CORRECT — compositor only */
@keyframes slide { to { transform: translateX(300px); } }
.box { animation: slide 1s; }
```
Layout properties poison entire frame to main thread. Transform stays on GPU.

### 2. Blocking Main Thread Without Yields
```js
/* ❌ WRONG — single 500ms task destroys INP */
function onClick() { heavyWork(); updateUI(); sendAnalytics(); }

/* ✅ CORRECT — chunked with yields */
async function onClick() { updateUI(); await scheduler.yield(); heavyWork(); await scheduler.yield(); sendAnalytics(); }
```
No yields = input delay + processing + presentation all in one frame = INP failure.

## Output
`PERF:<page>—<date> BUDGET:[LCP|INP|CLS|TBT]<value>vs<target>→PASS/FAIL FIX:<issue>→<change> VERIFY:[lhci|test]→<pass/fail>`

## Cross-Refs: web-quality-audit | ui-engine | baseline-ui

## Externalized Sections (ADR-007 compression)
## Scroll-Driven + Visibility (0KB)
```css
.reveal { animation: fade-up 0.5s ease-out; animation-timeline: view(); animation-range: entry 0% entry 100%; }
@supports not (animation-timeline:view()) { .reveal { opacity:1; transform:none; } }
.lazy-section { content-visibility: auto; contain-intrinsic-size: 500px; }
```
Scroll: JS only GSAP-level. Visibility: skips off-screen. `contain: layout style paint` = render boundary.
---

docs/skills/performance/reference.md
---

