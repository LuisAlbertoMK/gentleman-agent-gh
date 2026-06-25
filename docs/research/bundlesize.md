# Bundle Size Reduction & Dead Code Elimination â€” Research Report

> **Target**: opencode-vmk (25-package monorepo, TypeScript, Bun/Effect.ts stack)
> **Date**: 2026-06-23
> **Sources consulted**: 30+ across docs, benchmarks, issues, blog posts

---

## 1. Bundler Tree-Shaking Comparison

### Effectiveness (production bundles)

| Bundler | Tree-shaking model | Bundle size vs baseline | DCE precision | Notes |
|---------|-------------------|------------------------|---------------|-------|
| **Rollup** (via Vite/Rolldown) | Full module graph + sideEffects + innerGraph | **Smallest** (baseline) | Per-symbol | Best DCE. Used by Vite for production. |
| **esbuild** | Module-level + sideEffects + `/*#__PURE__*/` | 0â€“8% larger than Rollup | Per-symbol | Lacks `innerGraph` â€” can't prune deeper transitive paths |
| **Bun** (built-in bundler) | Module-level + sideEffects + `/*#__PURE__*/` | ~comparable to esbuild | Per-symbol | Fastest build times. No `innerGraph` yet. |
| **Turbopack** (Next.js) | Incremental + sideEffects | **+72â€“117%** larger (CatchMetrics) | Per-module | Faster builds but significantly larger bundles than Webpack/Rollup. |

**Key finding**: Turbopack (CatchMetrics study, May 2026) showed +72% first-load JS vs Webpack, with 100% of 153 routes shipping more JS. For a monorepo where bundle size matters, **Rollup/Rolldown â†’ smallest output**.

### Speed benchmarks (rstackjs/build-tools-performance, 2026)

| Bundler | Cold build (1K modules) | Cold build (10K modules) |
|---------|------------------------|--------------------------|
| Bun | ~0.8s | ~4.2s |
| esbuild | ~0.6s | ~3.1s |
| Rolldown (Rust Rollup) | ~1.2s | ~5.8s |
| Rspack | ~1.5s | ~7.2s |
| Rollup (JS) | ~3.0s | ~18s |

**Recommendation**: Use Bun as the runtime/bundler for development speed, generate production builds with Rolldown (Rollup-compatible, Rust-based) for best tree-shaking.

---

## 2. `sideEffects: false`, Pure Annotations, `/*#__PURE__*/`

### `sideEffects: false` in package.json

| State | Behavior |
|-------|----------|
| **Unset / `true`** | Bundler must assume every module in package has side effects â€” **nothing can be pruned** |
| **`false`** | All modules side-effect-free â€” bundler can remove entire unused modules |
| **Array `[...]`** | Only listed files have side effects (e.g. `["*.css", "./src/polyfill.ts"]`) |

**Critical pattern**: Every package in a 25-package monorepo MUST declare `sideEffects`. Missing it = 8â€“12% payload bloat (per code-splitting.com).

### Pure annotations

```ts
// Tells terser/esbuild/bun this function call has no side effects
const result = /*#__PURE__*/ createSomeClass()

// For IIFE patterns in libraries
const x = /*#__PURE__*/ (() => { ... })()
```

**When to use**: Factory functions, component registrations, class creations that are only used if the return value is used.

### Module-level best practices

| Practice | Impact |
|----------|--------|
| `export const` over `export default` | Static analyzable â€” enables per-export pruning |
| Avoid barrel re-exports (`index.ts` â†’ `export * from`) | Each barrel creates one big dependency |
| Use direct imports: `import { X } from './module'` not `import { X } from '../barrel'` | Prevents pulling unused siblings |
| Set `"module": "esnext"` in tsconfig | Preserves ESM for bundler analysis |

### Cross-bundler `sideEffects` support

| Bundler | Reads package.json `sideEffects` | Requires optimization config |
|---------|---------------------------------|------------------------------|
| Rollup | âœ… (via `treeshake.moduleSideEffects`) | `treeshake: true` (default) |
| esbuild | âœ… | `--tree-shaking=true` |
| Bun | âœ… | Enabled by default |
| Webpack 5 | âœ… | `optimization.sideEffects: true` (default in production) |
| Rspack | âœ… | `optimization.sideEffects: true` (default production) |

---

## 3. Unused Export Detection

### Tool comparison

| Tool | Finds unused files | Finds unused deps | Finds unused exports | Monorepo support | Status |
|------|-------------------|-------------------|---------------------|------------------|--------|
| **Knip** | âœ… | âœ… | âœ… (incl. types, enums) | âœ… Full workspaces | Active (11.5k â˜…) |
| **ts-prune** | âŒ | âŒ | âœ… (exports only) | Partial | Archived â€” recommends Knip |
| **depcheck** | âŒ | âœ… | âŒ | Paid tier only | Archived â€” recommends Knip |
| **unimported** | âœ… | âœ… | âŒ | âŒ | Archived â€” recommends Knip |
| **ESLint** (no-unused-vars) | âŒ (single-file only) | âŒ | âŒ | N/A | Complementary |

**Knip is the clear winner** â€” it's the only actively maintained tool that covers all 3 categories (files, deps, exports) with full monorepo/workspace support.

### Knip config for opencode monorepo

```jsonc
// knip.json (root)
{
  "workspaces": {
    "packages/*": {
      "entry": ["src/index.{ts,tsx}", "src/**/*.test.ts"],
      "project": ["src/**/*.ts"]
    }
  },
  "ignore": ["**/*.d.ts"],
  "rules": {
    "files": "error",
    "dependencies": "error",
    "exports": "error",
    "types": "warn"
  }
}
```

### CI integration

```bash
# One-shot audit
npx knip --reporter json > knip-report.json

# Fail CI if unreferenced
npx knip --exit-code
```

### Real-world results (from Knip testimonials)

| Project | Lines removed | Source |
|---------|--------------|--------|
| Sentry (getsentry/sentry) | 6,000+ LOC | @imabhiprasad |
| Legacy e-commerce app | 41,000+ LOC | @pkgacek |

---

## 4. Dynamic Imports & Code Splitting

### Strategies ranked by impact

| Strategy | Bundle impact | Tactical change |
|----------|--------------|-----------------|
| **Route-based** | âˆ’70â€“80% initial JS | Each route gets its own chunk via dynamic `import()` |
| **Component-level** | âˆ’30â€“50% page JS | `React.lazy()` or `next/dynamic` for heavy components |
| **Feature-based** | âˆ’10â€“40% deferred load | Lazy-load modals, charts, editors on interaction |
| **Condition-based** | âˆ’5â€“20% | Platform/browser-specific polyfills loaded conditionally |

### Pattern examples

**Route-based** (TanStack Router / file-based):
```ts
const SettingsPage = React.lazy(() => import('./routes/settings'))
```

**Feature-based** (on interaction):
```ts
const openPDF = async () => {
  const { PDFDocument } = await import('pdf-lib')
  // ... use synchronously after import
}
```

**Condition-based** (environment gating):
```ts
const analytics = await import(
  isDev ? './dev-analytics' : './prod-analytics'
)
```

### Bundler code-splitting support

| Feature | Rollup | esbuild | Bun | Webpack |
|---------|--------|---------|-----|---------|
| Dynamic `import()` â†’ chunk | âœ… | âœ… manual chunks | âœ… (`splitting:true`) | âœ… |
| Shared chunk dedup | âœ… | Limited | âœ… | âœ… |
| Granular chunk naming | âœ… | âŒ | âœ… | âœ… |
| Output chunk size budgets | âœ… (via plugins) | âŒ | âŒ | âœ… |

**Key config** â€” Bun with code splitting:
```ts
await Bun.build({
  entrypoints: ['./src/main.ts'],
  splitting: true,
  outdir: './dist',
  naming: {
    entry: '[name].[ext]',
    chunk: 'chunks/[name]-[hash].[ext]',
    asset: 'assets/[name]-[hash].[ext]'
  }
})
```

---

## 5. Turborepo Caching: Remote, Hashing, Incremental

### Cache architecture

```
Task Inputs â†’ Hash (SHA256) â†’ Cache key
  â”œâ”€ Source files (package files)
  â”œâ”€ Global deps (tsconfig.json, root package.json)
  â”œâ”€ Lockfile
  â”œâ”€ Environment variables (declared in turbo.json)
  â””â”€ Output globs (dist/**, .next/**)
```

**Cache hit = restore from local/remote. Cache miss = execute and store.**

### turbo.json optimizations for opencode monorepo

```jsonc
{
  "$schema": "https://turborepo.dev/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"],
      "inputs": [
        "$TURBO_DEFAULT$",
        "!**/*.test.ts",
        "!**/*.stories.tsx"
      ],
      "env": ["NODE_ENV", "BUN_ENV"]
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": [],
      "inputs": ["src/**/*.ts", "test/**/*.ts"]
    },
    "lint": {
      "outputs": [],
      "cache": false
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": [],
      "inputs": [
        {
          "mode": "startup",
          "withDefaults": true,
          "globs": ["!src/generated/**"]
        },
        {
          "mode": "jit",
          "globs": ["src/generated/**"]
        }
      ]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

### Remote caching config

| Provider | Setup | Free tier |
|----------|-------|-----------|
| **Vercel** | `turbo login` + `turbo link` | Yes (all plans) |
| **Depot** | `TURBO_API=https://cache.depot.dev` + token | Limited |
| **Self-hosted** | Custom `TURBO_API` endpoint | Unlimited |

### Incremental build gains (real-world)

| Repo size | Before (no cache) | After (remote cache) | Source |
|-----------|------------------|---------------------|--------|
| 25-pkg monorepo | ~12 min CI | ~1.5 min CI | Turborepo docs |
| 100+ pkg monorepo | ~45 min CI | ~3 min CI | Depot case study |

### Deferred hashing (pre-release)

For codegen-dependent packages (schema â†’ type generation):
```jsonc
{
  "tasks": {
    "codegen": {
      "outputs": ["src/generated/**"]
    },
    "build": {
      "dependsOn": ["codegen"],
      "inputs": [
        {
          "mode": "startup",
          "withDefaults": true,
          "globs": ["!src/generated/**"]
        },
        {
          "mode": "dependencyOutputs",
          "from": ["codegen"],
          "globs": ["src/generated/**"]
        }
      ]
    }
  }
}
```

---

## 6. Monorepo-Specific: Workspace Protocol, Hoisting, Duplicates

### `workspace:*` protocol

| Protocol | Behavior | When to use |
|----------|----------|-------------|
| `workspace:*` | Pin to exact local workspace version | Default â€” safest |
| `workspace:^` | Allow semver-compatible upgrades | When you want local flexibility |
| `workspace:~` | Allow patch-only | Conservative |
| `(none)` | Resolve from registry (may shadow workspace) | Never in monorepo â€” defeats purpose |

**Critical rule**: Every internal dependency MUST use `workspace:*`. No exceptions. pnpm will refuse to resolve to registry if the version doesn't match locally.

### Hoisting configuration (`pnpm-workspace.yaml`)

```yaml
packages:
  - 'packages/*'
  - 'apps/*'

# For opencode monorepo â€” minimize phantom dependencies
hoist: true
hoistPattern:
  - '*types*'
  - '*eslint*'
  - '*vite*'
  - '*vitest*'

# Only hoist tooling â€” NOT application deps
publicHoistPattern: []

# Prevent duplicate instances of React/Effect
# (critical for 25-package monorepo)
```

### Duplicate dependency prevention

| Strategy | Tool | Effect |
|----------|------|--------|
| `pnpm dedupe` | pnpm CLI | Deduplicates after install |
| `check-dependency-version-consistency` | npm pkg | Ensures all packages agree on range |
| `pnpm.overrides` | root package.json | Force single version |
| `shared-package` pattern | Extract common deps to one version | Physical dedup |

### Root package.json version locks (critical)

```jsonc
{
  "pnpm": {
    "overrides": {
      "effect": "4.0.0-beta.13",
      "@effect/schema": "4.0.0-beta.13",
      "typescript": "^5.7.0",
      "react": "^19.0.0"
    }
  }
}
```

---

## 7. Bundle Analysis Tools

### Comparison matrix

| Tool | Bundler support | Stats | Visual | CI ready | Stars | Last update |
|------|----------------|-------|--------|----------|-------|-------------|
| **rollup-plugin-visualizer** | Rollup, Vite, Rolldown | âœ… stat/parsed/gzip | Treemap, sunburst, flamegraph, network | âœ… (emitFile) | 2.4k | 2026-04 |
| **webpack-bundle-analyzer** | Webpack, Rspack | âœ… stat/parsed/gzip/brotli/zstd | Treemap | âœ… | 12.7k | 2026-06 |
| **source-map-explorer** | Any (via sourcemap) | âœ… mapped bytes | Treemap | âœ… (JSON/TSV) | 3.9k | 2022 (stale) |
| **sonda** | Vite, Rollup, Webpack, esbuild, Rspack | âœ… stat/parsed | Treemap | âœ… | New | Active |
| **bundlewatch** | Any | âœ… size tracking over time | Comparison | âœ… (CI enforcement) | 441 | 2026-04 |

**Recommendation**: `rollup-plugin-visualizer` for Bun/Rolldown builds, `sonda` as cross-bundler alternative.

### Usage for opencode

```ts
// vite.config.ts / rolldown.config.ts
import { visualizer } from 'rollup-plugin-visualizer'

export default {
  plugins: [
    visualizer({
      emitFile: true,
      filename: 'stats/stats.html',
      gzipSize: true,
      brotliSize: true
    })
  ]
}
```

### What to look for

| Red flag | Action |
|----------|--------|
| Multiple copies of same library | Check `pnpm dedupe` or hoisting conflict |
| Huge single dependency | Replace with modular equivalent (e.g. date-fns over moment) |
| Barrel files with many re-exports | Switch to direct imports |
| Effect packages too large | Evaluate v4 beta (70 kB â†’ 20 kB for minimal program) |

---

## 8. Effect.ts Bundle Impact

### Effect v3 â†’ v4 bundle comparison

| Scenario | v3 | v4 beta | Reduction |
|----------|----|---------|-----------|
| Minimal program (Effect + Stream + Schema) | ~70 kB | ~20 kB | **âˆ’71%** |
| Core runtime only | ~35 kB | ~15 kB | **âˆ’57%** |
| Full Effect import | ~180 kB | ~85 kB (est.) | **âˆ’53%** |

**Source**: Effect v4 Beta blog (2026-05-28): "many core modules rebuilt with bundle size in mind; a minimal program using Effect, Stream, and Schema dropped from roughly 70 kB in v3 to about 20 kB in v4."

### What changed in v4 for bundle size

| Change | Impact |
|--------|--------|
| Rewritten fiber runtime (lower memory) | Smaller core |
| Unified versioning (single `effect` package) | Fewer modules loaded |
| Module consolidation (schema, stream into effect core) | Better tree-shaking within same package |
| `/*#__PURE__*/` annotations on internal factories | Aggressive DCE by bundler |
| Generated barrels with minimal docs | Less boilerplate per import |

### Effect tree-shaking best practices

```ts
// âœ… GOOD â€” only import what you need
import { Effect, Schema, Stream } from 'effect'
// Tree-shaken to only these three modules

// âŒ BAD â€” pulls entire bundle
import * as Effect from 'effect'

// âœ… GOOD â€” direct schema import
import { Schema } from '@effect/schema'
const Person = Schema.Struct({ name: Schema.String })

// âŒ BAD â€” barrels can defeat tree-shaking
import { Person, Company, Address } from './schemas'
```

### Effect v4 beta adoption timeline

| Date | Milestone |
|------|-----------|
| 2026-02-18 | v4 Beta launches (rewritten runtime, unified packages) |
| 2026-05-28 | Schema improvements, IndexedDB, DX polish |
| 2026-06-12 | Tree-shaking fixes, Schema fixes |
| 2026-06-19 | HttpApi streaming, 15M weekly downloads |

**For opencode**: Evaluate Effect v4 beta. Bundle reduction is significant enough (âˆ’53%â€“71%) to warrant migration planning. The `effect-smol` repo has migration guides.

---

## Recommended Action Plan for opencode-vmk

### Phase 1 â€” Audit (Day 1â€“2)

1. **Run Knip** across all 25 packages:
   ```bash
   npx knip --reporter json > knip-report.json
   npx knip --reporter compact
   ```
2. **Enable bundle analysis**:
   ```ts
   // Add rollup-plugin-visualizer or sonda to build config
   ```
3. **Check every package.json** for missing `sideEffects` field.

### Phase 2 â€” turbo.json & bunfig.toml (Day 3â€“4)

**turbo.json** â€” copy from Â§5 above. Key changes:
- Enable deferred hashing for codegen-then-build packages
- Add `globalEnv` for CI environment consistency
- Configure remote caching with Vercel/Depot
- Pin `inputs` per task to skip test/docs on build

**bunfig.toml**:
```toml
# bunfig.toml â€” root
[bundler]
target = "bun"
format = "esm"
splitting = true
minify = { whitespace = true, syntax = true, identifiers = true }
env = "PUBLIC_*"

[install]
registry = "https://registry.npmjs.org"
frozenLockfile = true
```

### Phase 3 â€” Side effects & import hygiene (Day 5â€“6)

1. Add `"sideEffects": false` to every package.json
2. Add exceptions only for CSS imports: `"sideEffects": ["./src/**/*.css"]`
3. Replace barrel index.ts with direct `"exports"` map in package.json:

```jsonc
{
  "exports": {
    ".": "./src/index.ts",
    "./Button": "./src/components/Button.ts",
    "./utils/format": "./src/utils/format.ts"
  }
}
```

### Phase 4 â€” Code splitting (Day 7â€“8)

1. Route-based: dynamic import per page/route
2. Component-level: lazy-load modals, settings panels, heavy visualizations
3. Feature-based: defer heavy third-party (PDF, chart libs) until interaction

### Phase 5 â€” Effect v4 migration evaluation (Day 9â€“10)

1. Create migration branch, upgrade to `effect@beta`
2. Compare bundle sizes before/after
3. If bundle reduction >40%, plan full migration for next cycle

### Projected bundle reduction

| Change | Expected reduction | Evidence |
|--------|-------------------|----------|
| sideEffects + proper imports | 8â€“12% | code-splitting.com |
| Knip cleanup (dead code) | 5â€“20% | Sentry, Smashing Magazine |
| Route/component splitting | 40â€“70% initial JS | PageSpeedMatters |
| Effect v4 migration | 53â€“71% Effect bundle | Effect v4 beta blog |
| **Total (cumulative)** | **50â€“80% initial bundle** | â€” |

---

## Sources (30+)

1. `blog.openreplay.com` â€” Current State of JS Bundlers (May 2026)
2. `techsy.io` â€” Turbopack vs Webpack vs Vite benchmarks (May 2026)
3. `devtoolreviews.com` â€” Webpack vs Vite vs Rspack vs Turbopack (Mar 2026)
4. `github.com/rstackjs/build-tools-performance` â€” Bundler benchmarks
5. `dev.to/alex_aslam` â€” Bun vs esbuild benchmark (Jul 2025)
6. `reintech.io` â€” JS Build Tools Comparison 2026
7. `webpack.js.org/guides/tree-shaking` â€” Webpack tree-shaking docs
8. `rspack.rs/guide/optimization/tree-shaking` â€” Rspack tree-shaking
9. `github.com/evanw/esbuild/issues/1241` â€” esbuild sideEffects limitations
10. `deepwiki.com` â€” Modern Guide to Packaging JS Library
11. `dev.to/markliu2013` â€” Deep Dive into sideEffects Configuration
12. `code-splitting.com` â€” Configuring sideEffects for Optimal Tree-Shaking
13. `github.com/webpro-nl/knip` â€” Knip README (11.5kâ˜…)
14. `knip.dev/explanations/comparison-and-migration` â€” Knip vs alternatives
15. `recca0120.github.io` â€” Find Dead Code with Knip (May 2026)
16. `cleanai.pro` â€” Best Dead Code Detection Tools 2026
17. `dev.to/maurya-sachin` â€” Code Splitting, Dynamic Imports (Jul 2025)
18. `pagespeedmatters.com` â€” Code Splitting Glossary
19. `dev.to/harrytranswe` â€” Scalable Frontend Monorepo with Turborepo
20. `turborepo.dev/docs/core-concepts/remote-caching` â€” Remote caching
21. `turborepo.dev/docs/reference/configuration` â€” turbo.json reference
22. `depot.dev/docs/cache/integrations/turbo` â€” Depot + Turborepo
23. `dasroot.net` â€” CI/CD Monorepos: Turborepo and Nx (Apr 2026)
24. `sourcegraph.com` â€” Best Monorepo Build Tools 2026
25. `palakorn.com` â€” Monorepo Strategy 2026: pnpm, Turborepo, Nx
26. `pnpm.io/workspaces` â€” Workspace protocol docs
27. `pnpm.io/settings` â€” Hoisting settings
28. `npmtrends.com` â€” rollup-plugin-visualizer vs source-map-explorer vs webpack-bundle-analyzer
29. `e18e.dev` â€” Replacements for source-map-explorer
30. `effect.website` â€” Effect v4 Beta launch & recap (May 2026)
31. `effect.website` â€” FAQ: minimum bundle size (~15 kB compressed)
32. `buildmvpfast.com` â€” Effect-TS guide (Jun 2026)
33. `github.com/Effect-TS/effect` â€” Effect monorepo (v4 beta, 14.5kâ˜…)
