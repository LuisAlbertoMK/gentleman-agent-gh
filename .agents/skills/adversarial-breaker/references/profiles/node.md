# Node.js / TypeScript Attack Profile

## When to Load
`.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs` files (backend or frontend with logic).

## Language-Specific Vectors

### Injection
- `eval()` / `new Function()` — dynamic code from user input?
- `child_process.exec()` / `.spawn()` / `.fork()` — shell injection via unescaped args?
- `require()` / `import()` — dynamic path from user input?
- Prototype pollution — `Object.assign()`, spread `{...obj}`, `lodash.merge`?
- Template injection (EJS, Pug, Handlebars) — unescaped user data in templates?
- NoSQL injection via MongoDB query objects (`$gt`, `$ne`, `$where`)?

### Async & Error Handling
- Unhandled promise rejection — `.catch()` missing on async call?
- `try/catch` around `await` — errors swallowed silently?
- Express/Koa error middleware — errors leak stack traces?
- `process.on('uncaughtException')` — process stays alive in bad state?
- EventEmitter memory leak — >10 listeners on same event?

### Input Validation
- `parseInt()` / `Number()` on user input — NaN, Infinity, negative?
- JSON.parse() on user-controlled string — prototype pollution via `__proto__`?
- File upload paths — path traversal via `..` in filename?
- URL parsing — SSRF via redirect following?
- `Buffer.alloc()` with user-controlled size — OOM?

### Concurrency
- Race condition on shared mutable state (singleton, cache, counter)
- Async iterator — concurrent modification during iteration?
- Database transaction — isolation level too low?
- WebSocket — message ordering assumptions?
- `Promise.all()` — one rejection takes down all?

### npm/Module Supply Chain
- `postinstall` scripts in dependencies?
- Typosquattable import paths?
- Deprecated package with known vulns?
- `resolutions` / `overrides` — forced vulnerable version?

### TypeScript-Specific
- `as` type assertion — lying to the compiler?
- `any` on function parameters — no guard at boundary?
- `!` non-null assertion — potential runtime crash?
- `@ts-ignore` / `@ts-expect-error` — silencing real issues?
- Generic constraint bypassed via `as any`?
