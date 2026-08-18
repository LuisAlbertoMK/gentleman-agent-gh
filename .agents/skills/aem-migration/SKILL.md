---
name: aem-migration
description: "Specialized domain knowledge for Adobe Experience Manager site migrations — assessment, content transfer, component/dialog/HTL/Sling-Models migration, Adobe Tags/Launch data-layer migration, Adobe Analytics/Target/Campaign integration, and AEM debugging."
triggers: "aem migration, adobe experience manager migration, migration aem, aem cloud service, adobe launch tags migration, data layer migration, digitaldata, digital data layer, appmeasurement to web sdk, aep web sdk, adobe analytics migration, adobe target migration, content transfer tool, best practices analyzer, extjs to coral3, sling model, datasource migration, aem debugging, aem tags integration, migration readiness"
changelog: docs/agentes/aem-migration/automejora-cycle-log.md
---

# AEM Migration Skill

> Domain expertise for the `gentleman-aem` agent. Kept compact per ADR-007. Deep references: `references/reference.md` and `docs/agentes/aem-migration/knowledge-base.md`.

## When to Use

Any AEM migration task: readiness assessment, content transfer (CTT), component/dialog/code migration to Cloud Service, Adobe Tags (Launch) → AEP Tags migration, digitalData → ACDL/XDM data-layer migration, AppMeasurement → Web SDK migration, Adobe Analytics/Target/Campaign integration, and AEM debugging.

## Domain Model (at-a-glance)

| Layer | Source (6.x/AMS) | Target (Cloud Service) | Key Migration Artifact |
|-------|------------------|------------------------|------------------------|
| **Content** | CRX/DE package, node store | Migration set via CTT v3.0 | `04-migration-set/` |
| **Code** | Felix `system/console` | Cloud Manager CI/CD pipeline | `ui.apps` / `ui.content` archetype |
| **Dialogs** | ExtJS `dialog/` (Coral 2) | Granite UI `_cq_dialog/` (Coral 3) | extjs-to-coral3 mapping |
| **Components** | JSP / Sling taglibs | HTL / Sightly | `@Model` Sling Models |
| **Datasources** | `optionsProvider` servlet | `datasource` + JSON servlet | Sling ResourceType servlet |
| **Data layer** | `digitalData.*` | ACDL / XDM / Web SDK | `adobe.dl`, `datastream` |
| **Tags** | Adobe Launch property | AEP Tags property | Library → Environment → Publish |
| **Analytics** | AppMeasurement.js | Web SDK extension | `data` object ↔ XDM mapping |
| **Debug** | CRXDE Lite, Felix | RDE, Query Perf, AEP Debugger | logs, `/system/console/*`, `arc.*` |

## Workflow

### 1. Pre-Flight Assessment
```
BPA (Best Practices Analyzer) → CAM (Cloud Acceleration Manager) → Pattern Detector
↓
Gap inventory: components, dialogs, datasources, clientlibs, workflows, searches
↓
ICE scoring (Impact × Confidence × Effort) + blast radius (Bajo/Medio/Alto)
```
**Stop**: Alto blast-radius gaps require human checkpoint before Phase 2.

### 2. Content Transfer (CTT)
```
Pre-flight: Revision Cleanup + dataStore consistency
Disk space ≥ datastore_size + nodestore_size × 1.5
↓
CAM project: extraction → migration set → ingest (wipe mode = faster)
↓
Max 10 migration sets/project → split to 2nd project if >10
↓
Post: verify content renders (project structure must be correct)
```

### 3. Code & Component Migration
**Dialog (ExtJS → Coral 3):**
- `dialog/` → `_cq_dialog/` (rename, do NOT delete until backup)
- `multifield` → `composite="{Boolean}true"` + `<field>` container
- `optionsProvider` → `datasource` child node, `sling:resourceType` → dev implements servlet
- `namePrefix` → `name="./prop"` on field container
- Validation (`vtype`, `regex`, `allowBlank`) → Coral 3 clientlib `foundation-validation`

**Sling Models**: `@Model(adaptables={Resource.class, SlingHttpServletRequest.class})`, injectors (`@ValueMapValue`, `@ChildResource`, `@ScriptVariable`), register to `sling:resourceTypes`, export-ready for Cloud Service.

### 4. Tags / Data Layer / Analytics
```
Launch property → AEP Tags property (Company/Env mapping in IMS config)
↓
digitalData.* → ACDL (adobe.dataLayer) OR XDM schema
↓
Data elements: map js vars → report suite / XDM fields
↓
Rules: Event+Conditions+Actions → Web SDK extension
  Client-side: %dataElement%  |  Event-forwarding: {{dataElement}}
  Edge: arc.event.xdm.*
↓
AppMeasurement → Web SDK: 3 paths
  1. Web SDK tag ext (recommended)
  2. Analytics ext → Web SDK ext (grace period, uses `data` obj)
  3. AppMeasurement → Web SDK lib (manual, no tags)
  ⚠️ No mixed Web-SDK+AppMeasurement on same page
```

### 5. Debugging
| Tool | URL / Location | Use |
|------|---------------|-----|
| Logs | `error.log`, `access.log` | Frontline debugging (needs adequate logging config) |
| Bundles | `/system/console/bundles` | Validate bundle present + active, unsatisfied imports |
| Components | `/system/console/components` | Component lifecycle, PID for OSGi config |
| Sling Models | `/system/console/status-Sling-Model` | Registered resource types, adaptables |
| Query Perf | `/libs/granite/operations/content/maintenance` | Explain slow queries, traversal detection |
| Remote debug | IDE JDWP to `:4502` (JDWP) | Step-through live Java code |
| RDE | `aio cli` | Rapid dev-iteration cycle |
| AEP Debugger | Chrome extension | Tags build/env, Analytics report suites, Target activities |

**Slow-query fix**: nodetype restriction → `@Type` index; path scoping (`path=/content/site/us`); `jcr:contains` over `LIKE`; tune `oak.queryLimitInMemory`/`oak.queryLimitReads`.

## Constraints

- CTT does NOT analyze content; published/unpublished distinction is NOT preserved → filter manually.
- AEP Debugger requires Experience Cloud auth in an open tab for non-public data.
- Web SDK migration must be all-or-nothing per page (no mixed AppMeasurement + Web SDK).
- Extjs-to-coral3 `optionsProvider` servlet → developer must implement (cannot auto-convert).
- BPA requires admin user; preferred on Stage/Clone, never directly on Prod.

## References
- `references/reference.md` — Deep reference (mappings, JSON schemas, servlet skeletons)
- `docs/agentes/aem-migration/knowledge-base.md` — Synthesized research
- `docs/protocolos/protocolo_mejora_autonoma_v3.md` — Automejora protocol
- `docs/agentes/aem-migration/automejora-cycle-log.md` — Cycle execution log

## Cross-Refs
self-improvement | analysis-mode | deep-debugging | code-generation | security-scanner | quality-gate
