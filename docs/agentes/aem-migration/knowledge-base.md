# AEM Migration Knowledge Base

> Synthesized from 12 research cycles (Adobe Experience League, Apache Sling, GitHub adobe/skills, VML/Ford case study). Confidence markers included per section. Source: web research 2025–2026.

## 1. Migration Landscape Overview

### 1.1 The Full Adobe Experience Cloud Stack in Migration Context

A site migration from AEM On-Premise/AMS to AEM as a Cloud Service is **NOT** just a content move — it is a full digital-experience-platform migration:

| Component | Source | Target | Complexity | Confidence |
|-----------|--------|--------|------------|------------|
| AEM Sites | 6.x / AMS | AEM Cloud Service | HIGH | high |
| Adobe Tags | Adobe Launch | AEP Tags (same product, new UX) | LOW-MED | high |
| Data Layer | digitalData (W3C DDL) | ACDL / XDM | HIGH | high |
| Analytics | AppMeasurement.js | Web SDK (alloy.js) | HIGH | high |
| Personalization | Adobe Target at.js | Web SDK Target | HIGH | medium |
| Campaign Orchestration | Adobe Campaign (MC) | AJO / Campaign v8 | MED-HIGH | medium |
| Audience Data | Audience Manager | Real-Time CDP | HIGH | medium |
| Content Assets | AEM Assets | AEM CS Asset Microservices | HIGH | medium |

**Ford / VML case study** (`confidence: high`): VML integrated AEM + Campaign + Target + Audience Manager + Analytics + Tags into a single experience, stitching 1st + 3rd party data. Conversion up 76%, +4,400 conversions, cost-per-lead down 16%. AEM migrations are **platform-level**, not just CMS-level.

### 1.2 Migration Phases (Adobe Official — 3-phase model)

**Phase 1 — Planning** (`confidence: high`):
- Familiarize with AEM CS architecture (container-based, API-driven, guided DevOps)
- Review notable changes: automatic updates, **Cloud Manager (required, sole deployment mechanism)**, Asset Microservices, Separation of code and content, Replication as a Service, Admin console/IMS
- Review deprecated features; run **Best Practices Analyzer (BPA)** on source
- Effort estimation + resource planning; establish KPIs & timelines

**Phase 2 — Execution** (`confidence: high`):
- Content Migration: Content Transfer Tool (CTT)
- Code Migration: Maven build via Cloud Manager pipeline
- Component Migration: ExtJs dialogs → Coral 3, JSP → HTL, Sling Models
- Tags/Data Layer Migration: Launch → AEP Tags, digitalData → ACDL/XDM, AppMeasurement → Web SDK

**Phase 3 — Post Go-live** (`confidence: high`):
- Monitoring, optimization, iteration, content top-ups, performance tuning

## 2. Assessment Tools

### 2.1 Best Practices Analyzer (BPA) (`confidence: high`)
- Static analysis → migration readiness report; runs on source AEM 6.1+
- Requires admin user; **BPA v2.1.54+ includes Lighthouse Score** (needs public site URL)
- Auto-upload to CAM via upload key (auto-renew near expiry); manual upload limited ~200MB
- **Preference**: Run on Stage/Clone, NOT directly on Prod
- Built on AEM Pattern Detector output

### 2.2 Cloud Acceleration Manager (CAM) (`confidence: high`)
- Central hub: migration sets, BPA upload, migration tracking
- Max 10 migration sets per project (split to 2nd project if more needed)

## 3. Content Transfer Tool (CTT) (`confidence: high`)

### 3.1 Requirements
- **Version**: 3.0 recommended (2.0+ required); uninstall older versions
- Source: AEM 6.3+ (upgrade to 6.5 if lower); Java 8+
- **Disk space on source**: `datastore_size + (nodestore_size × 1.5)` — CTT uses 64GB min for datastore
- Data Store types: File, S3, Shared S3, Azure Blob

### 3.2 Migration Set Lifecycle
1. **Extract** → local copy in `crx-quickstart/cloud-migration` (DO NOT alter this path)
2. **Store** → migration set in CAM
3. **Ingest** → apply to target AEM CS Author/Publish
4. **Top-up** → incremental extract → merge ingest

### 3.3 Ingestion Modes
- **Wipe mode** (initial migration, FASTER): delete target repo → apply migration set
- **Merge mode** (top-ups, SLOWER): apply on top of existing content

### 3.4 Critical Gotcha (`confidence: high`)
**CTT does NOT differentiate published/unpublished content.** Must manually filter.

### 3.5 Post-Transfer
- Correct **project structure** must be in CS environment for content to render
- CTT creates content but NOT code/components — migrate separately via Cloud Manager

## 4. Code & Component Migration (`confidence: high`)

### 4.1 Dialog Migration: ExtJS → Coral 3 (GitHub adobe/skills)
- Source: `dialog/` → Target: `_cq_dialog/` (backup: rename `dialog/` → `dialog.bak/`)
- Design dialog: `design_dialog/` → `_cq_design_dialog/` (skip if editable-templates-in-use)
- **Multifield**: `composite="{Boolean}true"` + `<field>` container; single field → simple
- **namePrefix** → `name="./prop"` on field container; child names preserved
- **optionsProvider** → `datasource` child node + Sling servlet (developer MUST implement; do NOT use `servletPath`)
- **Validation**: `vtype`/`regex`/`regexText` → Coral 3 clientlib `foundation-validation`; flag each dropped
- **Path sanitization**: strip leading `/libs/`; collapse `//` to `/`
- **filter.xml**: add `<exclude pattern=".*/dialog.bak(/.*)?"/>`

### 4.2 Sling Models (`confidence: high`)
- `@Model(adaptables={Resource.class, SlingHttpServletRequest.class}, adapters={...}, resourceType={...})`
- Injectors: `@ValueMapValue`, `@ChildResource`, `@ScriptVariable`, `@ResourcePath`, `@RequestAttribute`
- HTL: `data-sly-use.model="com.my.model.MyModel"` → adapt from Resource
- Cloud Service: ensure `@Exporter` for JSON/Servlet export

### 4.3 Datasources
- Source: `optionsProvider` servlet path → Target: `datasource` child node + Sling component returning `application/json`
- The servlet must be implemented; `datasource` is a shell telling AEM to call it

### 4.4 Clientlibs (`confidence: medium`)
- Category restructuring (Cloud Service uses different jQuery/embed)
- `granite` vs `jquery` category split; async loading considerations
- Embed audit for deprecated categories (`cq.jquery`, `cq.shared`)

## 5. Adobe Tags (Launch) Migration (`confidence: high`)

### 5.1 Publishing Flow
- Library states: Development → Submitted → Approved → Published
- Permissions: `Develop` (create/build/submit), `Approve` (staging build), `Publish` (production)
- Downstream: upstream resources included in builds

### 5.2 Rules Architecture
- Events (If, OR logic), Conditions (AND), Exceptions (NOT), Actions (Then)
- Tokenization: client-side `%dataElement%`, event-forwarding `{{dataElement}}`, Edge `arc.event.xdm.*`

### 5.3 Data Elements
- Map data layer: `digitalData.page.pageInfo.pageName` → JavaScript Variable data element
- Or ACDL: `adobe.clientDataLayer` → Adobe Client Data Layer type

### 5.4 Debugger (`confidence: high`)
- Chrome extension; needs Experience Cloud auth for non-public data
- Can test embed codes locally (override prod/staging with local build)
- Shows Tags property/build/env, Analytics report suites, Target activities

### 5.5 Client-side debugging
- `_satellite.setDebug(true)` — verbose rule firing order logging
- Browser DevTools → Network tab → library URL + Edge network (`/ee/v2/collect`)

## 6. Data Layer Migration (`confidence: high`)

### 6.1 Source: digitalData (W3C DDL)
```js
window.digitalData = {
  page: { pageInfo: { pageName, destinationURL, pageType, language } },
  product: [{ id, name, productInfo: { productCategory } }]
};
```

### 6.2 Target Options
- **ACDL** (Adobe Client Data Layer): `adobe.clientDataLayer.push({event, eventInfo})` — recommended for AEM CS
- **XDM** (Experience Data Model): for full AEP integration (CJA, Real-Time CDP)
- **Web SDK `data` object**: grace period, maps via Data Stream mapping

### 6.3 Migration Path Decision
```
digitalData → ACDL     : if staying Adobe Analytics + minimal AEP
digitalData → XDM      : if moving to CJA / Real-Time CDP / AJO
```

## 7. Adobe Analytics → Web SDK (`confidence: high`)
Three paths (NOT combinable on same page):
1. **Web SDK tag extension** (recommended) — full migration
2. **Analytics extension → Web SDK extension** — grace period, uses `data` object
3. **AppMeasurement → Web SDK lib** — manual, no tags

## 8. Debugging (`confidence: high`)

| Tool | URL | Use |
|------|-----|-----|
| Logs | error.log, access.log | Frontline (needs adequate logging) |
| Bundles | /system/console/bundles | Bundle present + active, unsatisfied imports |
| Components | /system/console/components | Component lifecycle, PID for OSGi config |
| Sling Models | /system/console/status-Sling-Model | Registered resource types, adaptables |
| Query Perf | /libs/granite/operations/content/maintenance | Explain slow queries, traversal |
| Remote debug | IDE JDWP to :4502 | Step-through Java |
| RDE | aio CLI | Rapid dev iteration |
| AEP Debugger | Chrome ext | Tags/Analytics/Target validation |

### 8.2 Slow Query Fix Recipe
1. Identify in error.log → "The query read more than x nodes"
2. Query Performance console → EXPLAIN → look for "no index" / "traversal"
3. Fix: nodetype restriction (`@Type` index) → path scoping (`/content/site/us`) → `jcr:contains` over `LIKE` → ensure `evaluatePathRestrictions=true`
4. Tune: `-Doak.queryLimitInMemory=500000`, `-Doak.queryLimitReads=100000`

## 9. Ford / VML Migration Pattern (case study) (`confidence: high`)
VML built a bespoke site-build accelerator + authoring tool on AEM, then integrated:
- **AEM** (CMS foundation) + **Campaign** + **Target** + **Audience Manager** + **Analytics** + **Tags**
- Stitched 1st + 3rd party data for personalization
- Results: +76% conversions, +4,400 conversions, -16% cost-per-lead

**Key learning**: Migration is platform integration — not just AEM. Data layer, tags, analytics, target, campaign must migrate as a coordinated unit.

## 10. Cloud Manager CI/CD (`confidence: high`)
- Sole deployment mechanism for AEM CS
- Pipelines: build → test → deploy
- Code pushed to remote AEM CS via git
- Maven archetype → `ui.apps` / `ui.content` package structure

## 11. AEM Version Compatibility Matrix (`confidence: high`)

| Source AEM Version | CTT Supported | Java Target | Notes |
|--------------------|---------------|-------------|-------|
| 6.3 | ✅ (min) | Java 8 | Must upgrade to 6.5 before CTT 3.0 |
| 6.4 | ✅ | Java 8+ | Upgrade path: 6.4 → 6.5 → CS |
| 6.5 | ✅ (recommended) | Java 8+ | Direct CTT 3.0 extraction |
| 6.5 (with SP) | ✅ | Java 8+ | Apply latest SP before extraction |
| Managed Services (AMS) | ✅ | Java 8+ | Same as 6.5; AMS-specific infra decommission |

### 11.1 Deprecation Impact (`confidence: high`)

| Feature | 6.x | AEM CS | Migration Action |
|---------|-----|--------|-----------------|
| Classic UI | ✅ | ❌ | Disable; migrate to Touch UI |
| JMX MBeans | ✅ | ⚠️ Limited | Use new health-check framework |
| Custom log paths | ✅ | ❌ | Use Cloud Manager logs |
| CRXDE Lite | ✅ | ✅ (dev only) | Same URL; dev env only in CS |
| Felix Web Console | ✅ | ✅ (dev only) | `/system/console` → dev env restriction |
| Custom indexes | ✅ | ✅ (Oak index) | Must use compat pattern; no Lucene custom |
| JSP | ✅ | ⚠️ Deprecated | Migrate to HTL + Sling Models |
| ExtJS dialogs | ✅ | ❌ | Migrate to Coral 3 (see references) |
| Design dialog | ✅ | ⚠️ | Use Content Policies (Style System) |
| Skinning | ✅ | ❌ | Use Theme Editor (ThemeLibrary) |
| MSM (multi-site) | ✅ | ✅ | Live Copy → same; but verify rollout config |

### 11.2 Multilingual & Multisite Migration (`confidence: high`)

AEM's translation workflow + multi-site manager (MSM) must be handled carefully:
- **Translations**: Use AEM Translation Connector → export XLIFF → translate → re-import. CTT preserves `jcr:language` on pages.
- **MSM Live Copies**: CTT preserves Live Copy structure, but rollout configs may need re-validation in CS (different dispatcher/CDN).
- **Language roots**: `/content/site/en`, `/content/site/es`, `/content/site/fr` — verify language copy mapping post-transfer.
- **Cross-site references**: Internal links (`/content/site/es/...`) may need path rewriting if site structure changes.
- **Translation projects**: Existing translation projects are NOT migrated by CTT — recreate in CS.

### 11.3 RDE (Remote Developer Environment) Workflow (`confidence: medium`)

```bash
# 1. Initialize RDE from a Cloud Service environment
aio cloud-service:rde:init --environment-id <env-id>

# 2. Install artifacts iteratively (no full pipeline needed)
aio cloud-service:rde:install --file target/bundle.jar
aio cloud-service:rde:install --file target/package.zip
aio cloud-service:rde:install --file target/config.json  # OSGi config

# 3. Stream logs
aio cloud-service:rde:logs --tail -f
aio cloud-service:rde:logs --follow --grep "ERROR"

# 4. Debug cycle: install → test → install → test (fast iteration)
```

**RDE limitations**: Max 200MB per install, 5 min timeout per install, 3 concurrent RDEs per org.

