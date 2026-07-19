# DEV MASTERY 2026
**Análisis profundo · Julio 16, 2026 · Fuentes: GitHub, arXiv, NVIDIA, LogRocket, Zylos Research, Sourcegraph**

---

## 0. PREREQUISITES — ¿QUÉ NECESITAS PARA CADA SECCIÓN?

> **Regla general**: §1 y §4–§13 son 100% software — corren en cualquier máquina moderna.
> Solo §2 (optimización GPU) tiene dependencias de hardware específico.

### Tiers de hardware

| Tier | CPU | RAM | GPU | Qué sections aplican |
|---|---|---|---|---|
| **Mínimo** | x86-64 / ARM64, 2+ cores | 4 GB | Ninguna | §1, §3 (dev), §4–§13 completos |
| **Dev cómodo** | 4+ cores, cualquier gen moderna | 8–16 GB | Ninguna / integrada | Todo lo anterior + LLM local 3B–7B INT4 |
| **Mid-range** | 6–8 cores | 16–32 GB | RTX 3060 12GB+ (opcional) | Todo anterior + modelos 13B INT4, offload parcial |
| **Enterprise** | 16+ cores / multi-socket | 128 GB+ | A100 / H100 / B200 | §2 completo (FP8, FA-4, vLLM, TRT-LLM) |

### LLM local por RAM disponible

```
4 GB RAM   → Phi-3 Mini 3.8B INT4 (~2.3 GB) · Gemma 2B INT4 (~1.5 GB)
8 GB RAM   → Mistral 7B INT4 (~4.1 GB) · LLaMA 3.1 8B INT4 (~4.9 GB)
16 GB RAM  → LLaMA 3.1 13B INT4 (~7.8 GB) · Mistral 7B FP16 (~14 GB)
32 GB RAM  → LLaMA 3.1 34B INT4 (~20 GB) · corre cómodo con OS activo
64 GB RAM  → LLaMA 3.1 70B INT4 (~42 GB)

Motor recomendado sin GPU: llama.cpp u Ollama — CPU puro, cualquier OS
```

### §2 — qué aplica según tu GPU real

| GPU | FlashAttention | Quantización disponible | Framework |
|---|---|---|---|
| Sin GPU | N/A | INT4 en CPU vía llama.cpp | llama.cpp / Ollama |
| RTX 3060 12GB | FA-2 | INT4, INT8 | llama.cpp, Ollama |
| RTX 4090 24GB | FA-2 | FP8, INT8, INT4 | vLLM, llama.cpp |
| A100 80GB | FA-2 / FA-3 | FP8, INT8, INT4 | vLLM, TRT-LLM |
| H100 80GB | **FA-3** (default) | FP8, INT8 | vLLM, TRT-LLM, SGLang |
| B200 / B300 | **FA-4** (default) | FP8 nativo | vLLM v0.20+, TRT-LLM |

### Qué NO requiere nada especial (todo en software)

```
✅ Marco 4D de archivos (§1)          → cualquier editor + terminal
✅ Lenguajes Rust / Zig / Go (§3)     → compilador gratuito, 4GB RAM
✅ .learnings/ auto-aprendizaje (§4)  → archivos de texto plano
✅ Error handling + testing (§5–§6)   → CI gratuito (GitHub Actions)
✅ Investigación Plan A vs B (§7)     → proceso, sin hardware
✅ Monorepo + Nx/Turbo (§8)           → Node.js instalado
✅ SEO / Core Web Vitals (§9)         → Lighthouse en Chrome, gratis
✅ Calidad de código + linting (§10)  → extensiones de editor
✅ Gap analysis (§11)                 → proceso + herramientas gratuitas
✅ Reducción de tokens (§13)          → configuración de API / prompts
```

---

## 1. ESTRATEGIAS DE LECTURA / ESCRITURA / EDICIÓN DE ARCHIVOS PARA IA

### Marco 4D (Apply-To-Any-Model)

| Operación | Estrategia | Impacto |
|---|---|---|
| **WRITE** | Scratchpad + persist fuera del contexto (`.learnings/`, KV store, Redis) | Evita recomputación |
| **SELECT** | Semantic search + relevance scoring antes de inyectar | Corta ruido 60–80% |
| **COMPRESS** | Sliding window + resumen denso; reducción del 68% manteniendo 91% info crítica | Menos tokens, mejor atención |
| **ISOLATE** | Separar contexto por tarea/agente; no mezclar hilos en una sola ventana | Evita contaminación cruzada |

### Operaciones de archivo (reglas universales)

- **Lectura**: `view_range` con líneas mínimas — nunca carga total en archivos >50 líneas
- **Edición**: `str_replace` del fragmento más pequeño único — no reescribir el archivo completo
- **Creación**: flujo `outline → section → review → output` para archivos largos
- **Flujo canonico**: `1) view_range confirmar contexto → 2) str_replace fragmento mínimo`
- **Anti-patrón crítico**: releer el archivo completo tras editar = desperdicio puro

### Patrones de contexto para producción

```
Scratchpad Pattern:
  agent.state → working_notes.json → retrieve on demand

RAG Pipeline:
  query → embed → vector_search → top-K chunks → augment prompt → LLM

Prefix Caching:
  requests con mismo prefijo → mismo pod → reutiliza KV cache calculado
  resultado: 40–70% reducción de latencia en prompts compartidos
```

### Context rot & budget gate

- Ventana Sonnet/Opus 4.x: 200k tokens → alertar en >120k (~60%)
- "Lost in the middle": LLMs ignoran info en el centro → colocar lo crítico al inicio O al final
- Context dilution: más tokens ≠ mejor respuesta; calidad degrada con ruido

---

## 2. OPTIMIZACIÓN DE RECURSOS (RAM / CPU / VRAM / GPU)

### Stack de técnicas LLM (orden de impacto)

| Técnica | Reducción VRAM | Latencia | Notas |
|---|---|---|---|
| **Quantización FP8** | ~50% vs BF16 | ↓ en H100/H200 | Pérdida de calidad negligible |
| **INT8 (AWQ)** | ~50% vs FP16 | ↓ en A100 | Sweet spot producción |
| **INT4** | ~75% | ↓↓ | Solo cuando hay restricción dura de VRAM |
| **FlashAttention** (FA-2/FA-3/FA-4) | Evita matrix NxN en HBM | 5–20x menos I/O en HBM | FA-2: default A100/RTX30-40 · FA-3: default H100/H200 · FA-4: solo Blackwell B200/B300 (SM100) |
| **PagedAttention** | Elimina fragmentación KV | +throughput | OS-inspired memory paging |
| **GQA** (Grouped Query) | 8x reducción KV cache | ↓ | Llama 3: 8 KV heads / 64 query heads |
| **Speculative Decoding** | Sin cambio VRAM | 2–3x tokens/seg | Draft model → verify con main |
| **KV Quant (FP8 keys / INT4 vals)** | Hasta 75% KV size | Neutral | HCAttention: 25% footprint, accuracy intacta |

### CPU / RAM

```
Modelo de capacidad producción:
  Total VRAM = VRAM_single_inference × concurrent_users × 1.1

Offloading:
  KV values (FP16) → CPU RAM como fallback tier-2
  Libera VRAM sin perder precision en paths críticos
```

### Frameworks de serving (2026)

| Framework | Mejor para |
|---|---|
| **vLLM** | Multi-modelo, auto-routing, PagedAttention nativo |
| **TensorRT-LLM** | NVIDIA GPUs, throughput máximo, INT8/FP8 nativo |
| **SGLang** | RadixAttention (reuse KV por prefijo), alta concurrencia |
| **llama.cpp** | Local / edge, CPU offload, cualquier hardware |

---

## 3. TOP 3 LENGUAJES DE ALTO RENDIMIENTO (2026)

> **Regla 80/15/5**: Go para el 80% de servicios; Rust para el 15% crítico; Zig para el 5% especializado.

### 🥇 Rust 1.97 — Máximo rendimiento + seguridad

**Fortalezas**
- Zero-cost abstractions, sin GC, memory safety en compile-time
- Latencia tail 5x mejor y uso de memoria 10x menor que Go (caso Discord "Read States" service, 2020; confirmado 2025)
- Cloudflare Edge, AWS Firecracker, Android kernel — todos en Rust
- Ecosistema maduro: Tokio, Axum, Actix, Serde, SQLx

**2026 novedades (versión actual: 1.97.0 — Jul 9, 2026)**
- v0 symbol mangling ahora default en stable → stack traces legibles con genéricos
- `build.warnings` estable en Cargo → CI warning-free sin invalidar build cache
- Linker stderr ahora visible por default → detección temprana de bugs de configuración
- Rust 1.95 (Abr 2026): `cfg_select!` macro, if-let guards en match arms

```rust
// Zero-allocation HTTP handler
#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/users/:id", get(get_user))
        .layer(ConcurrencyLimitLayer::new(10_000));
    axum::serve(TcpListener::bind("0.0.0.0:3000").await.unwrap(), app)
        .await.unwrap();
}
```

**Gaps**: curva de aprendizaje steep, borrow checker frustrante al inicio, compile times

---

### 🥈 Zig 0.16 — Control absoluto, cero overhead

**Fortalezas**
- Sin runtime, sin GC, sin allocator implícito → predecible al nanosegundo
- `comptime` ejecuta código en compile-time → 23% reducción latencia en parsing real
- Allocator interface: arena, stack fallback, pool — control granular por path
- Integer de ancho arbitrario: optimización de CPU cache sin precedente
- Zig 0.16.0 (14 Abr 2026): I/O as an Interface — async composable sin runtime overhead; debut de compilación incremental (build time: 75s → 20s)

**Empresas**
- Tigerbeetle (DB financiera): 100% Zig
- Uber: sistema de configuración crítico
- Bun (runtime JS): originalmente en Zig (rewrite a Rust anunciado Jul 8, 2026)
- Levanta ligeramente en throughput vs Rust en networking puro

```zig
// Zero-allocation HTTP handler
pub fn main() !void {
    var server = try http.Server.init(.{ .port = 3000, .workers = 4 });
    defer server.deinit();
    try server.run(handleRequest);
}
fn handleRequest(ctx: *Context) !void {
    try ctx.json(.{ .status = "ok" });
}
```

> ⚠️ **Estado real a Jul 16, 2026**: Zig **NO ha lanzado v1.0**. Versión actual: **0.16.0** (Abr 2026), próxima: 0.17.0 (estimada ago 2026). El creador Andrew Kelley declaró en mayo 2026: *"buscando perfección sin compromisos antes de bendecir el 1.0"* (The Register, 28 May 2026). Producción-ready para hot paths especializados, pero **sin garantía de estabilidad de API** hasta 1.0.

**Gaps**: ecosistema pequeño, API cambia entre releases, comunidad menor, sin 1.0 aún

---

### 🥉 Go 1.26 — Productividad + operabilidad de producción

> Versión actual: **1.26.5** (Jul 7, 2026). Go 1.25 (Ago 2025) y 1.26 (Feb 10, 2026) son las dos versiones activamente soportadas.

**Fortalezas**
- Binary único, deployment trivial, onboarding en días
- GC tuneado → sin pauses inesperadas en servicios bien configurados
- Goroutines: concurrencia masiva sin boilerplate
- Tooling best-in-class: `go test`, `pprof`, `race detector` built-in
- Domina microservicios, API gateways, CLIs, DevOps tools (Docker, K8s, Terraform)

**1.26 novedades clave (Feb 2026)**
- `crypto/hpke`: Hybrid Public Key Encryption (post-quantum hybrid KEMs, RFC 9180)
- `simd/archsimd` (experimental): acceso a SIMD nativo en amd64 (128/256/512-bit vectors)
- Generic self-referential type constraints ahora permitidos
- `pprof` web UI: flame graph como vista default

**Performance real**: en HTTP services con I/O bound, Go matches Rust en p99; la diferencia real aparece en CPU-bound hot paths.

**Gaps**: GC pauses en carga extrema, no apto para sistemas embedded, verbosity en error handling

---

### Menciones honorables

| Lenguaje | Niche |
|---|---|
| **TypeScript 5.x** | Frontend/backend full-stack con safety de tipos |
| **Python 3.13+** | AI/ML, scripting, data science — sigue dominando el espacio IA |
| **Mojo** | Emergente: sintaxis Python, performance de C/Rust — watch 2026–2027 |
| **C++23** | Legacy crítico, game engines, HPC |

---

## 4. AUTO-APRENDIZAJE DE AGENTES IA

### Arquitectura `.learnings/` (patrón OpenClaw / Claude Code)

```
.learnings/
├── errors/          → fallas con root cause + prevención
├── corrections/     → preferencias del usuario corregidas
├── insights/        → patrones descubiertos (ej: contexto >40 msgs → degradación 40%)
└── promoted/        → learnings críticos que se inyectan en cada sesión
```

### Hooks de aprendizaje automático

```python
# 3 hooks que corren en cada sesión
error_learning    → captura error_type, traceback, root_cause, prevention
session_learning  → patrón de comportamiento de la sesión
performance_learning → métricas de velocidad/calidad por tarea
```

### 3 Dimensiones de Auto-Evolución (Survey XMUDeepLIT 2026)

| Dimensión | Mecanismo | Ejemplo |
|---|---|---|
| **Model-Centric** | Self-correction, RL multi-turn | Sirius, Ragen |
| **Environment-Centric** | Knowledge estático + experiencia dinámica | RAG + memory consolidation |
| **Co-Evolution** | Modelo + entorno evolucionan juntos | LLM coder + unit tester via RL |

### AgentDevel Pipeline (arXiv 2026)

```
Reframe self-improvement as release engineering:
  implementation-blind quality signals
  → symptom-level diagnosis
  → flip-centered regression gating
  → promote only when metric improves on held-out set
```

---

## 5. MANEJO DE ERRORES (Producción-Grade)

### Jerarquía de error handling

```
1. PREVENCIÓN     → tipos estrictos (TypeScript strict, Rust Result<T,E>)
2. DETECCIÓN      → monitoring (TTFT, ITL, error rate, p99)
3. RECUPERACIÓN   → fallback graceful, retry con backoff exponencial
4. APRENDIZAJE    → log al .learnings/errors/ con root_cause + prevention
5. ESCALACIÓN     → alert si error es recurrente (promote a critical)
```

### Patrones por lenguaje

```rust
// Rust: error explícito en tipos
fn parse_config(path: &str) -> Result<Config, ConfigError> {
    let content = fs::read_to_string(path)?;  // ? propaga el error
    toml::from_str(&content).map_err(ConfigError::ParseFailed)
}
```

```typescript
// TypeScript: never para exhaustividad
function assertNever(x: never): never {
    throw new Error(`Unhandled case: ${JSON.stringify(x)}`);
}
```

```go
// Go: error como valor, siempre manejado
if err := db.Ping(); err != nil {
    return fmt.Errorf("db connection failed: %w", err)
}
```

### LLM Inference — Error handling específico

- **VRAM OOM**: reducir batch_size → activar layer offloading → bajar quantización
- **Context overflow**: `/compress` → nueva sesión con handoff denso
- **Hallucination loop**: detección por KL divergence del output → fallback a FP16

---

## 6. SUITE DE TESTING COMPLETA

### Pirámide de testing 2026

```
          [E2E - Playwright/Cypress]        ← 10% — flujos críticos
        [Integration - Supertest/Jest]      ← 20% — contratos entre módulos
    [Unit - Vitest/Jest/Go test/Cargo test] ← 70% — lógica pura
```

### Reglas de calidad

| Regla | Threshold |
|---|---|
| Cobertura en lógica crítica de negocio | ≥ 80% |
| Tests bloqueantes en cada PR | Siempre |
| TDD para lógica compleja | Obligatorio |
| Tests de comportamiento, no implementación | Los tests sobreviven refactoring |
| Visual regression (Chromatic/Percy) | Captura cambios UI no esperados |
| Performance test (Core Web Vitals) | LCP ≤2.5s, INP ≤200ms, CLS <0.1 |

### CI/CD gate mínimo

```yaml
on: pull_request
jobs:
  quality:
    steps:
      - lint          # ESLint / clippy / golangci-lint
      - typecheck     # tsc --noEmit
      - test          # vitest / cargo test / go test ./...
      - coverage      # fail si <80% en paths críticos
      - e2e           # playwright en staging
      - lighthouse    # Core Web Vitals regression check
```

---

## 7. METODOLOGÍA DE INVESTIGACIÓN: PLAN A vs B → V3

### Framework de investigación iterativa

```
CICLO BASE:
  Hipótesis → Implementación → Métricas → Análisis → Decisión → V_siguiente

ESTRUCTURA:
  Plan_A: enfoque conservador / baseline conocido
  Plan_B: enfoque experimental / nueva técnica
  ─────────────────────────────────────────────
  Plan_V3: síntesis: conserva lo mejor de A,
           integra mejoras de B,
           elimina los gaps de ambos
```

### Métricas de decisión (dual: auto + humana)

```
Auto-métrica:   throughput, latencia p99, coverage, build time, error rate
Humana:         review de calidad, adoption rate, DX, mantenibilidad
```

### Anti-patrones de investigación

- ❌ Confirmar solo el plan favorito — buscar activamente evidencia que lo refute
- ❌ Métrica única — siempre dual (perf + calidad)
- ❌ Comparar en staging sin carga real — benchmark en condiciones de producción
- ❌ Skip del baseline — Plan_A SIEMPRE necesita una implementación de referencia

### Ejemplo aplicado

```
Plan_A: RAG puro (vector search → inject chunks)
  → Problema: retrieval latency alta, chunks irrelevantes

Plan_B: Prefix caching (shared prompt prefix → cache KV)
  → Problema: solo funciona con prefijos fijos, poca flexibilidad

Plan_V3: RAG con prefix caching en el system prompt
  → system_prompt en cache → chunks variables en user_msg
  → resultado: -60% TTFT, +relevancia, +flexibilidad
```

---

## 8. MAPEO DE PROYECTOS Y CROSS-PROJECT

### Monorepo vs Polyrepo (decisión 2026)

| Criterio | Monorepo | Polyrepo |
|---|---|---|
| Cambios atómicos cross-proyecto | ✅ Un commit | ❌ Múltiples PRs |
| Shared libraries | ✅ Nativo | ❌ Versioning manual |
| CI/CD complejidad | ⚠️ Requiere tooling (Nx/Turbo/Bazel) | ✅ Simple por repo |
| AI coding assistant context | ✅ Claude Code absorbe todo el monorepo | ⚠️ Contexto fragmentado |
| Onboarding | ⚠️ Un repo enorme | ✅ Repos aislados |

**Adoptar monorepo cuando**: múltiples servicios se liberan juntos, shared libs frecuentes, team >5 engineers.

### Stack monorepo recomendado

```
Nx / Turborepo    → dependency graph, incremental builds, affected commands
Bazel             → polyglot a escala Google/Meta
Sourcegraph       → code intelligence, cross-repo search, dependency mapping
Augment Code      → AI para mapeo de dependencias en enterprise
```

### Gaps críticos que matar primero

| Gap | Síntoma | Fix |
|---|---|---|
| **Dependency drift** | A importa v1, B importa v3 del mismo lib | Centralized versioning en monorepo |
| **Type-3 code clones** | Lógica duplicada con pequeñas variaciones | Extraer shared lib + clone detection |
| **Circular deps** | A→B→A | Arquitectura en capas + lint rule |
| **Missing ownership** | Nadie sabe quién mantiene X | CODEOWNERS + ADR por módulo |
| **Context loss cross-session** | Agente repite errores previos | `.learnings/` + handoff doc |

---

## 9. SEO + UI/UX + DISEÑO RESPONSIVO (2026)

### Core Web Vitals — Umbrales mandatorios

| Métrica | Good | Needs Improvement | Poor | Impacto SEO |
|---|---|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤2.5s | 2.5–4.0s | >4s | Ranking directo |
| **INP** (Interaction to Next Paint) | ≤200ms | 200–500ms | >500ms | Ranking directo (reemplazó FID 2024) |
| **CLS** (Cumulative Layout Shift) | <0.1 | 0.1–0.25 | >0.25 | Ranking directo |

> Páginas en posición #1 tienen 10% más probabilidad de pasar CWV vs posición #9.
> Mejora de CWV → 12–20% organic traffic uplift (caso: QuintoAndar +36% conversión YoY tras +80% INP).

### Checklist técnico SEO/UX 2026

```
□ Mobile-first indexing: versión móvil = lo que Google evalúa
□ Semantic HTML: H1→H2→H3 jerarquía correcta, alt text, aria-labels
□ WCAG 2.2 AA: contraste 4.5:1, touch targets 48×48px mínimo
□ Image formats: WebP/AVIF obligatorio, lazy loading below-fold
□ Critical CSS inline en <head>, resto async
□ Code splitting: dynamic imports por ruta, tree shaking
□ CDN + edge functions: TTFB <200ms → target gold standard
□ Schema markup + structured data para AI Overviews (AEO/GEO)
□ HTTPS + OWASP Top 10:2025
□ Progressive hydration para apps JS-heavy
□ Sin pop-ups intrusive (Page Experience signal negativo)
```

### Responsive: componentes, no páginas

```
2026 shift:
  ANTES: diseñar layouts de página y adaptar a móvil
  AHORA: diseñar componentes responsivos por defecto
         → el componente sabe cómo reaccionar en cualquier contexto
         → container queries > media queries para componentes internos

Breakpoints modernos:
  Mobile-first → 320px base
  Container queries para componentes internos
  Fluid typography: clamp(1rem, 2.5vw, 1.5rem)
```

### Stack UI/UX recomendado

| Capa | Tool |
|---|---|
| Design system | Tokens CSS + Figma Variables |
| Components | Shadcn/UI o componentes propios bien documentados |
| Testing visual | Chromatic / Percy (regresión automática) |
| Performance audit | Lighthouse CI en cada PR |
| Real device test | BrowserStack / Sauce Labs + mid-range Android |
| Monitoring campo | Google Search Console CrUX + PageSpeed Insights |

---

## 10. CALIDAD DE CÓDIGO Y SINTAXIS MODERNA

### Principios (stack-agnóstico)

```
1. STRICT TYPES     → TypeScript strict:true / Rust / Zig — errores en compile-time
2. SMALL FUNCTIONS  → single responsibility, máx 40 líneas visibles
3. IMMUTABILITY     → prefer const/let, no mutación implícita
4. PURE FUNCTIONS   → sin side effects no declarados
5. EXPLICIT ERRORS  → no throw escondido; Result<T,E> o Either monad
6. ZERO MAGIC       → no metaprogramming oculta el flujo real
7. TEST PRIMERO     → si no puedes testear, rediseña
```

### Sintaxis moderna por stack

```typescript
// TypeScript 5.x — const type parameters, decorators stage 3
const parseId = <const T extends string>(id: T) => id;

// satisfies para validación sin widening
const config = { port: 3000, host: "localhost" } satisfies ServerConfig;

// using keyword para disposal automático
await using db = await connectDB();  // dispose() llamado automáticamente
```

```rust
// Rust 2024 edition
let result = items.iter()
    .filter(|i| i.active)
    .map(|i| i.transform())
    .collect::<Result<Vec<_>, _>>()?;  // short-circuit en primer error
```

### Linting / formatting mínimo

```
TypeScript:  ESLint + @typescript-eslint/strict + Prettier
Rust:        clippy --deny warnings + rustfmt
Go:          golangci-lint + gofmt
Todos:       pre-commit hooks + CI gate bloqueante
```

---

## 11. IDENTIFICACIÓN DE GAPS

### Gap analysis framework (4 capas)

```
CAPA 1 — CÓDIGO
  □ Code clones tipo 3 → duplicación con variación mínima
  □ Dead code → coverage report + tree shaking report
  □ Circular dependencies → lint rule + visualización de grafo
  □ Missing types → strict null checks, no 'any'

CAPA 2 — ARQUITECTURA
  □ God classes/modules → responsabilidad única violada
  □ Bottleneck I/O → profiling con flamegraph
  □ Missing caching layer → identifica reads frecuentes sin cache
  □ No error boundaries → fallas en cascada sin aislamiento

CAPA 3 — PROCESO
  □ Sin ADRs (Architecture Decision Records) → decisiones sin registro
  □ Sin CODEOWNERS → módulos huérfanos
  □ Tests solo en CI → feedback loop lento
  □ Deploys manuales → riesgo humano en producción

CAPA 4 — IA/CONTEXTO
  □ Context rot acumulado → sesiones largas sin compress
  □ Sin .learnings/ → errores repetidos en cada sesión
  □ Prompts sin versionar → regresiones de comportamiento invisibles
  □ Sin métricas duales → solo auto-métrica = hackeo de objetivo
```

---

## 12. RECOMENDACIONES ADICIONALES

### Observabilidad (no opcional en 2026)

```
OpenTelemetry → trazas distribuidas, métricas, logs unificados
  TTFT          → Time To First Token (LLM)
  ITL           → Inter-Token Latency
  p99 latency   → el percentil que importa en producción
  Error rate    → por tipo de error, no solo count
  DORA metrics  → Deployment Frequency, Lead Time, MTTR, Change Failure Rate
```

### Security-by-design

```
OWASP Top 10:2025 desde día 1
  A01 Broken Access Control → RBAC estricto, deny-by-default
  A03 Injection → prepared statements, no concatenación de queries
  A07 Auth failures → tokens de corta vida, rotación automática
  A09 Logging failures → logs estructurados, sin datos PII

Supply chain:
  Dependabot / Renovate → actualizaciones automáticas
  SBOM (Software Bill of Materials) → inventario de dependencias
  Sigstore → firma de artefactos
```

### AI-Assisted development (2026 stack)

```
Claude Code    → agente de coding en CLI, contexto full codebase
Cursor/Windsurf → IDE con AI inline, tab completion semántico
Aider          → git-aware coding assistant
Sourcegraph    → code intelligence + AI search cross-repo
Augment Code   → enterprise cross-repo dependency AI
```

### Arquitectura de investigación rápida (template)

```markdown
## [NOMBRE] Research — [fecha]

### Hipótesis
> [Una oración: "Si X, entonces Y, porque Z"]

### Plan A (baseline)
- Implementación: ...
- Métricas objetivo: ...
- Riesgos: ...

### Plan B (experimental)
- Implementación: ...
- Métricas objetivo: ...
- Riesgos: ...

### Resultados
| Métrica | Plan A | Plan B | Delta |
|---------|--------|--------|-------|
| perf    |        |        |       |
| quality |        |        |       |

### Decisión: Plan V3
> [Qué se toma de A, qué de B, qué se descarta]
> [Próximos pasos]
```

---

## 13. REDUCCIÓN DE TOKENS SIN PERDER CALIDAD

### 6 estrategias ordenadas por impacto

| Técnica | Reducción | Calidad | Aplicación |
|---|---|---|---|
| **Semantic caching** | 50–80% requests | 100% (hit exacto) | Redis LangCache; misma query → sin llamada al LLM |
| **Prefix caching** | 40–70% TTFT | 100% | System prompt fijo → KV cache reutilizado entre requests |
| **Strip tool responses** | ~68% por llamada | ~99% | Solo campos relevantes; 2,847 tok → 891 tok (Stripe caso real) |
| **RAG vs context stuffing** | Hasta 90% vs inject total | ~95% | Top-K chunks semánticos, no corpus completo en contexto |
| **Compresión jerárquica** | 4:1 a 18:1 | 91–97% | Multi-level summarization; Stingy Context: 239k → 11k tokens en código |
| **Structured output (JSON schema)** | 20–40% en outputs | 100% | El modelo responde directo al schema, sin prosa envolvente |

### Cuándo aplicar cada una

```
Query repetida / mismo usuario       → Semantic cache primero
System prompt largo (>2k tokens)     → Prefix cache
Tool calls / API responses           → Strip a campos mínimos (whitelist por tool)
Base de conocimiento grande          → RAG, nunca context stuffing
Archivos de código en contexto       → view_range + compresión jerárquica
Output estructurado predecible       → JSON schema forzado
Sesión larga (>40 mensajes)          → /compress → nueva sesión con handoff denso
```

### Anti-patrón más costoso

```
❌ Inyectar el response completo de una API/DB al contexto
   → Solución: whitelist de campos por tool name
   → Caso real: Stripe payment object 2,847 tok → 891 tok (68.7% ahorro)
   → Implementación: map<tool_name, string[]> allowed_fields
```

### Relación con §2 (recursos)

```
Semantic cache  → menos llamadas LLM     → CPU/GPU/VRAM reducidos
Prefix cache    → menos prefill compute  → TTFT reducido 40–70%
RAG             → ventana más pequeña    → KV cache más pequeño → VRAM reducida
Strip responses → menos tokens/req       → throughput sube sin cambiar hardware
```

---

## RESUMEN EJECUTIVO (caveman mode)

| Área | Acción inmediata |
|---|---|
| Archivos IA | view_range + str_replace siempre; nunca view completo |
| VRAM | FP8 primero, PagedAttention, FlashAttention — siempre activos |
| Lenguaje | Go para APIs; Rust para hot paths; Zig para daemons críticos |
| Auto-aprendizaje | `.learnings/` con hooks de error + session |
| Testing | ≥80% en lógica crítica, Playwright E2E, Lighthouse CI |
| Investigación | Plan A vs B → métricas duales → síntesis V3 |
| Cross-project | Monorepo + Nx/Turbo + Sourcegraph para >5 devs |
| SEO/UX | LCP≤2.5s + INP≤200ms + CLS<0.1; componentes responsivos |
| Código | strict types + TDD + lint bloqueante en CI |
| Gaps | 4 capas: código → arquitectura → proceso → IA |

---

*Fuentes verificadas: mem0.ai, redis.io, zylos.ai, logrocket.com, NVIDIA dev blog, arXiv (VoltAgent, XMUDeepLIT, AutoResearch), dev.to (Speed Engineer, Pooya Golchian), sourcegraph.com, uxpin.com, almcorp.com, rust-lang.org, ziglang.org, web.dev · Julio 16, 2026*

---

## AUDIT LOG — Errores corregidos (2 rondas de revisión · Jul 16, 2026)

### Ronda 1 — Errores de factual críticos
| # | Claim v1 | Estado | Corrección aplicada |
|---|---|---|---|
| 1 | "Rust 1.95" como versión actual | ❌ FALSO | Actual: **Rust 1.97.0** (Jul 9, 2026) |
| 2 | "Zig 1.0 en late 2025" | ❌ FALSO | Zig sigue en **0.16.0** — sin 1.0 aún (The Register, May 28, 2026) |
| 3 | "Discord 5x throughput" | ⚠️ IMPRECISO | Fue **5x tail latency + 10x memoria** (no throughput) |

### Ronda 2 — Gaps adicionales encontrados en revisión profunda
| # | Claim v2 | Estado | Corrección aplicada |
|---|---|---|---|
| 4 | "Go 1.22+" | ❌ FALSO | Actual: **Go 1.26.5** (Jul 7, 2026); 1.22 es de Feb 2024 y está EOL |
| 5 | "FlashAttention-4 · Default en vLLM/TensorRT-LLM" | ❌ INCORRECTO | FA-4 es **solo para Blackwell (B200/B300/SM100)**. FA-3 = H100/H200; FA-2 = A100/RTX30-40 |
| 6 | Mojo duplicado en menciones honorables | ⚠️ REDUNDANTE | Consolidado en una sola entrada |
| 7 | §13 Reducción de tokens ausente del .md | ⚠️ GAP | Agregado como sección completa |

### Claims verificados correctos
| # | Claim | Fuente |
|---|---|---|
| ✓ | Context compression 68%/91% | TACL research vía Zylos Research (Jan 2026) |
| ✓ | Core Web Vitals LCP≤2.5s, INP≤200ms, CLS<0.1 | Google 2026 |
| ✓ | QuintoAndar -80% INP → +36% conversiones YoY | web.dev case study oficial |
| ✓ | GQA: Llama 3 usa 8 KV heads / 64 query heads | LLM Inference Guide 2026 |
| ✓ | Zig 0.16.0 release Apr 14, 2026 | ziglang.org oficial |
| ✓ | Rust 1.95 release Apr 16, 2026 (histórico) | rust-lang.org oficial |
| ✓ | FlashAttention reduce HBM I/O 5-20x | Spheron + NVIDIA dev blog |
| ✓ | vLLM/SGLang/TensorRT-LLM como top frameworks | inferenceengineering.tech 2026 |
