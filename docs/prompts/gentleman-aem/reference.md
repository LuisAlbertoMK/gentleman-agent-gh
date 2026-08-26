# AEM Migration Specialist — Detailed Reference

## Lifecycle: The 7 Migration Phases

> Reference: `docs/protocolos/protocolo_mejora_autonoma_v3.md` — every phase runs as an automejora cycle (Analyzer → Implementer → Breaker/QA → Benchmark → Documenter).

### Phase 1 — Assessment & Readiness (Pre-Flight)
- Run **Best Practices Analyzer (BPA)** + **Pattern Detector** on the source AEM (6.x / AMS) instance.
- Inventory: custom components, dialogs (ExtJS → Coral 3 delta), datasources, Sling Models, clientlibs, workflows, search forms, repoinit ACL scripts.
- Identify deprecated/blocking features against AEM as a Cloud Service compatibility matrix.
- Output: `01-assessment-report.md` with ICE-scored gap list + blast radius (Bajo/Medio/Alto).

### Phase 2 — Architecture & Planning
- Map source topology (Author/Publish/Dispatcher) → target Cloud Service topology (Author Tier / Publish Tier / CDN / RDE).
- Define migration strategy per asset type:
  - **Content**: Content Transfer Tool (CTT) v3.0, migration sets, wipe vs. merge ingestion.
  - **Code**: AEM Project Archetype → Cloud Manager CI/CD pipeline; `ui.apps` / `ui.content` restructuring.
  - **Components**: Coral 3 dialogs, composite multifields, datasource servlets, HTL, Sling Models exporter-ready.
  - **Data layer / Tags**: digitalData → AEP Client Data Layer (ACDL) or XDM; Launch property → AEP Tags; AppMeasurement → Web SDK extension.
- Scope-lock files: `02-migration-plan.md` (files in scope + rollback map).

### Phase 3 — Infrastructure & Environment Setup
- Provision Cloud Acceleration Manager project + migration sets.
- Configure Cloud Manager pipelines (CI/CD: build, test, deploy).
- Set up Remote Developer Environment (RDE) for local rapid iteration.
- Configure Adobe IMS + Tags (Launch) integration in AEM Cloud Service.

### Phase 4 — Content Transfer
- Pre-flight: Revision Cleanup + data store consistency checks on source.
- Disk space calc: `data store size + node store size × 1.5`.
- Extraction → ingestion (wipe mode recommended for speed; merge mode for top-ups).
- Max 10 migration sets per CAM project; split into 2nd project if more needed.
- Post-transfer: verify content renders (correct project structure, component mapping).

### Phase 5 — Code & Component Migration
- **Dialog migration**: ExtJS `dialog/` → Coral3 `_cq_dialog/`. See `adobe/skills` extjs-to-coral3 reference.
  - `multifield` → `composite="{Boolean}true"` + `field` container.
  - `optionsProvider` → `datasource` child node + Sling servlet (developer must implement).
  - `namePrefix` → `name="./prop"` on container.
  - Validation: `vtype`/`regex` → Coral 3 clientlib `foundation-validation`.
- **Sling Models**: `@Model(adaptables=..., adapters=...)`, injectors (`@ValueMapValue`, `@ChildResource`, `@ScriptVariable`), HTL `data-sly-use`.
- **Datasource migration**: Classic `optionsProvider` servlet → Granite UI `datasource` resource + JSON servlet.
- **Clientlibs**: category restructuring, `granite` vs `jquery` embed, async loading.

### Phase 6 — Adobe Tags / Data Layer Migration
- **Tags (Launch)**: Properties → AEP Tags property; Libraries → Environments (Dev/Staging/Prod); Publishing flow (Develop → Submitted → Approved → Published).
- **Data elements**: `digitalData.page.pageInfo.pageName` → ACDL `adobe.dataLayer` or Web SDK XDM mapping.
- **Rules**: Event + Conditions + Actions → Web SDK extension; `%dataElement%` tokenization; `arc.event.xdm.*` for Edge data.
- **Extensions**: Adobe Analytics (AppMeasurement) → Web SDK extension (migration paths: Web SDK tag ext / Analytics-to-Web-SDK / AppMeasurement-to-Web-SDK-lib). **Mixed implementations not supported on same page.**
- **Debugging**: Adobe Experience Platform Debugger (Chrome) + `_satellite.setDebug(true)` + browser devtools Network tab (Edge network `/ee/v2/collect`).

### Phase 7 — Debugging & Verification
- **AEM debugging**: Logs (frontline — needs adequate logging), OSGi Web Console (`/system/console/bundles`, `/components`, `/status-Sling-Model`), Remote debugging (IDE step-through), CRXDE Lite, Query Performance console (slow queries → `oak.queryLimitReads`/`queryLimitInMemory`, nodetype restriction, path scoping, `jcr:contains` over `LIKE`).
- **Migration verification**: BPA re-run, content diff, E2E smoke tests.
- **Performance**: Query tuning, index definitions, cache layers.

## Automejora Protocol Integration (Expanded)

Every Phase is a **karpathy-loop** cycle. Within each migration task:

1. **Analyzer** (`!analisis` + ICE + blast radius): discover gaps with evidence + cite `file:line`.
2. **Scope lock**: declare files/modules in scope before implementing.
3. **≥3 approaches**: generate 3+ distinct approaches; document discarded ones (mini-ADR).
4. **Implementer**: codify the chosen approach. Fowler rule: `refactor:` / `fix:` / `feat:` never mixed.
5. **Breaker/QA** (isolated): fuzzing, mutation testing, load/chaos where applicable.
6. **E2E**: existing + new tests. Pre-existing bugs corrected, zero exceptions.
7. **Benchmarker**: measure vs baseline + previous cycle (min 5 runs, median/IQR).
8. **Documenter**: cycle log + mini-ADR + commit↔cycle mapping.
9. **Definition of Done**: E2E green + benchmark non-regressive + 0 new critical/high vulns + ADR written + in-scope commits tagged.

**Stop condition**: no ICE-relevant gaps + Breaker survives 3+ angles + 100% E2E + benchmark ≥ baseline + marginal gain below threshold + budget reached.

## Trusted References (externalized — ADR-007)

- Adobe Experience League — AEM as a Cloud Service Migration Guide
- Adobe Experience League — Content Transfer Tool guidelines
- Adobe Experience League — Best Practices Analyzer
- Adobe Experience League — Debugging AEM SDK (OSGi consoles, remote debugging)
- Adobe Experience League — Tags publishing flow, rules, data elements
- Adobe Experience League — Web SDK migration (AppMeasurement → Web SDK, Analytics extension → Web SDK extension)
- Adobe Experience League — Experience Platform Debugger
- Apache Sling — Sling Models reference (injectors, `@Model`)
- GitHub `adobe/skills` — extjs-to-coral3 dialog/migration references
- VML case study: Ford of Europe Adobe Experience Cloud integration (AEM + Campaign + Target + Audience Manager + Analytics + Tags)
