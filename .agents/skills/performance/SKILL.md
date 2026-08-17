---
name: performance
description: "Web performance — CWV/INP, compositor animation, scroll-driven, content-visibility."
triggers: "performance, speed up, load time, slow loading, page speed, performance audit, INP, animation performance, scroll performance, compositor"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1916
---

## When to Use
Web performance — CWV/INP, compositor animation, scroll-driven, content-visibility.

<!-- karpathy-compressed: 2026-07-10 -->

## Budget
| Resource | Budget | | Resource | Budget |
|---|---|---|---|---|
| Total | <1.5MB | | JS (gz) | <300KB |
| CSS | <100KB | | Images | <500KB |
| Fonts | <100KB | | 3rd-party | <200KB |

## Critical Path + Caching
TTFB<800ms · Brotli · HTTP/2+ · Edge · preload LCP · defer · code-split · tree-shake
`HTML: no-cache` · `Static: public,max-age=31536000,immutable` · `API: private,no-cache`

## Media + Runtime
AVIF→WebP→PNG→SVG, `<picture>` srcset, LCP `fetchpriority="high"`, lazy. Fonts: `font-display:swap`, preload .woff2, unicode-range, variable.
Batch DOM reads · debounce scroll≥100ms · rAF · virtualize >100 · View Transitions · 3rd-party: async/IObserver/Facade

## Metrics
LCP<2.5s · FCP<1.8s · TBT<200ms · CLS: explicit w/h or `aspect-ratio` · `font-display:swap`

## INP (<200ms)
| Phase | Target | How |
|---|---|---|
| Input Delay | <50ms | Reduce main thread blocking |
| Processing | <100ms | **`scheduler.yield()`** |
| Presentation | <50ms | Compositor anim, `content-visibility:auto` |

```js
async function handleHeavy() {
  updateImmediately(); await scheduler.yield();
  sendAnalytics(); await scheduler.yield();
  processRemaining();
}
```

## Compositor
| Property | Thread | OK? |
|---|---|---|
| `transform`, `opacity` | **Compositor** GPU 60fps | ✅ |
| `filter` | Compositor GPU | ⚠️ |
| `width/height/top/left` | Main Layout+Paint | ❌ |
| `margin/padding` | Main Layout+cascades | ❌ |

Animate ONLY `transform`+`opacity`. One layout prop → poisons to main thread.

## Scroll-Driven + Visibility (0KB)
```css
.reveal { animation: fade-up 0.5s ease-out; animation-timeline: view(); animation-range: entry 0% entry 100%; }
@supports not (animation-timeline:view()) { .reveal { opacity:1; transform:none; } }
.lazy-section { content-visibility: auto; contain-intrinsic-size: 500px; }
```
Scroll: JS only GSAP-level. Visibility: skips off-screen. `contain: layout style paint` = render boundary.

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

## Refs
web.dev CWV · MDN INP · ui-engine · baseline-ui